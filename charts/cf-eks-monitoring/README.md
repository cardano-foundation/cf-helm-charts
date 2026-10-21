# cf-eks-monitoring Helm Chart

This Helm chart deploys a baseline for monitoring/observability based on: prometheus, grafana, and loki.

# Using values-k3s.yaml

This kind of deploy contains sensitive default values for keys and secrets. You must override these defaults before deploying to production, for example:

```sh
helm repo add cardano-foundation https://cardano-foundation.github.io/cf-helm-charts
helm install \
  --create-namespace \
  -n observe \
  --values values-k3s.yaml \
  --set loki.minio.rootPassword=CHANGEME \
  --set loki.storage.object_store.s3.secret_access_key=CHANGEME \
  cf-eks-monitoring cardano-foundation/cf-eks-monitoring 
```

## Object storage: MinIO replaced by Silo (`pgsty/silo`)

Loki's S3 object store runs on the `minio` sub-chart of `loki` (5.4.0 from `https://charts.min.io/`),
whose default images - `quay.io/minio/minio` and `quay.io/minio/mc` - are no longer pullable: the
`quay.io/minio` namespace returns 401 for anonymous pulls (other Quay packages still work), the
images are gone from Docker Hub, and upstream `github.com/minio/minio` is archived. That breaks any
`helm upgrade`/redeploy of this chart, because the `loki-minio-post-job` step containers would fail
at container start; already-running MinIO containers keep working until then.

All values files now pin the [Silo](https://silo.pgsty.com/) fork instead, in the sub-chart's own
values keys (no chart patch needed):

```yaml
loki:
  minio:
    image:
      repository: docker.io/pgsty/silo   # server + statefulset
      tag: RELEASE.2026-09-16T00-00-00Z
    mcImage:
      repository: docker.io/pgsty/mc     # loki-minio-post-job steps (/config/initialize, /config/add-user)
      tag: RELEASE.2026-09-16T00-00-00Z
```

Verified against those images locally: `docker-entrypoint.sh minio server ...` starts (Silo accepts
the legacy `minio` argv token), `MINIO_ROOT_USER`/`MINIO_ROOT_PASSWORD` are honoured, `/usr/bin/mc`
exists in both images, and `mc alias set myminio ...`, `mb`/`mb --with-lock` (bucket create), `stat`,
`rm -r --force`, `version enable`, `admin user add`, `admin user svcacct add` all work. Not
verified / differs: `admin policy create` wants Silo's own policy JSON (numeric `version` is
rejected), while the sub-chart's `_helper_policy.tpl` emits the S3 `Version`/`Statement` shape - only
relevant if you ever set `loki.minio.policies` (currently `[]`). `anonymous set default` is also
rejected by Silo's `mc` (it wants `private|public|download|upload`) - only relevant if a bucket
configures `permissions`.

Existing storage is read without conversion (`.minio.sys` layout is unchanged), so no data migration
is implied; the PVC/Secret identities (`loki-minio`, `loki-minio-post-job`) also stay the same. If
`cf-zpg-operator` is deployed, it pins the same `minio` sub-chart and needs the same image override.
