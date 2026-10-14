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

## Grafana MCP server (`grafana-mcp`)

The chart deploys the [Grafana MCP server](https://grafana.com/docs/grafana/latest/developer-resources/mcp/)
as an additional Helm dependency (`oci://ghcr.io/grafana-community/helm-charts/grafana-mcp`). It
authenticates to the Grafana instance of this chart with basic auth: `GRAFANA_USERNAME` and
`GRAFANA_PASSWORD` are **not** configured inline, they are resolved from the Grafana admin secret
that kube-prometheus-stack ships together with the Grafana deployment
(`<release-name>-grafana`, keys `admin-user` / `admin-password`) via `secretKeyRef`:

```yaml
grafana-mcp:
  enabled: true          # condition (`grafana-mcp.enabled`) in Chart.yaml
  fullnameOverride: "grafana-mcp"
  grafana:
    url: "http://cf-eks-monitoring-grafana:3000"
  envValueFrom:
    GRAFANA_USERNAME:
      secretKeyRef: { name: cf-eks-monitoring-grafana, key: admin-user }
    GRAFANA_PASSWORD:
      secretKeyRef: { name: cf-eks-monitoring-grafana, key: admin-password }
```

Implication - Grafana's object names are **release-name based**, not pinned here: kube-prometheus-stack
derives them as `<release-name>-grafana` (its `fullnameOverride: kube-prometheus-stack` only applies
to the prometheus/alertmanager objects, not to the Grafana sub-chart). The two literals in the
block above - the `secretKeyRef` name and the `GRAFANA_URL` host - therefore only hold as long as
the Helm release / ArgoCD component name is `cf-eks-monitoring`:

| release / component name | Grafana admin secret & deployment name | MCP refs resolve? |
|---|---|---|
| `cf-eks-monitoring` | `cf-eks-monitoring-grafana` | yes |
| anything else (renamed component) | `<that-name>-grafana` | **no** - MCP starts up with dangling refs and Grafana is deployed under a different name |

Kubernetes does not fail on a `secretKeyRef` that points at a missing object, so this breaks at
runtime (container stuck waiting for the secret), not at deploy time. If the component is ever
renamed, update both literals - or pin the Grafana name once with
`kube-prometheus-stack.grafana.fullnameOverride` (note that this also renames the Grafana
deployment, secret, RBAC role and sidecar ConfigMaps, so the release-based objects from before the
rename have to be cleaned up).

Notes:
- The secret must live in the MCP deployment's namespace - Kubernetes resolves `secretKeyRef`
  only within the container's namespace. Both charts default to the release namespace, which is
  fine as long as you deploy them in one component; if you split Grafana and `grafana-mcp` into
  separate components, give both the same `namespaceOverride`/namespace.
- `GRAFANA_URL` uses port `3000`, the port Grafana actually listens on (`service.port: 80` is only
  the ingress-facing port with `targetPort: 3000`).
- No credentials are duplicated: the values are read from the same secret object Grafana's own
  deployment consumes via `GF_SECURITY_ADMIN_USER`/`GF_SECURITY_ADMIN_PASSWORD`. Basic auth is the
  least suitable option for automation - a service account token
  (`grafana-mcp.grafana.apiKeySecret: { name: ..., key: ... }`) is preferred; skip the MCP server
  with `--set grafana-mcp.enabled=false`.

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
