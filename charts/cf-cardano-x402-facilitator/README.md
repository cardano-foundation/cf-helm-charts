# cf-cardano-x402-facilitator

Deploys the [Cardano x402 facilitator](https://github.com/cardano-foundation/cardano-x402-facilitator) in the light configuration from its Docker Compose deployment.

The chart creates:

- one facilitator `Deployment` and an optional cluster-internal `Service`;
- an optional `Ingress` exposing only the public x402 endpoints;
- one Zalando Postgres Operator `postgresql` resource with a prepared `facilitator` database.

It does not deploy cardano-node, Yaci Store, or Yano. The facilitator uses a hosted Blockfrost API by default and has no built-in HTTP authentication, so any external exposure should add TLS, authentication, and traffic controls.

## Prerequisites

- Kubernetes with the Zalando Postgres Operator and `acid.zalan.do/v1` CRD installed;
- an amd64 worker (the application image currently includes an amd64-only native library);
- a Blockfrost project ID when using hosted Blockfrost.

## Install

Create the Blockfrost credential in the release namespace:

```shell
kubectl create secret generic facilitator-blockfrost \
  --from-literal=BLOCKFROST_PROJECT_ID='<project-id>'
```

Install the chart:

```shell
helm upgrade --install facilitator ./charts/cf-cardano-x402-facilitator \
  --set blockfrost.existingSecret.name=facilitator-blockfrost
```

The Postgres Operator creates the database owner Secret as
`facilitator-owner-user.facilitator-pg.credentials.postgresql.acid.zalan.do`.
By default, the cluster name is `<Helm release name>-pg`; set
`postgres.clusterName` to override it. The Deployment derives both the Secret
name and the Postgres Service DNS from the resolved cluster name.

The PostgreSQL custom resource is created in `zpg-system` by default, while
prepared-database credentials are created in the Helm release namespace. Set
`postgres.namespace` when the operator watches a different namespace.

## Ingress

Enable ingress and configure its host and TLS settings:

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: facilitator.example.com
  tls:
    - secretName: facilitator-tls
      hosts:
        - facilitator.example.com
```

The ingress uses `Exact` matches for `/verify`, `/settle`, and `/supported`.
There is intentionally no catch-all path, so `/actuator`, `/health`, and other
application paths are not exposed through this ingress.

## Gateway API route

Instead of an `Ingress`, attach the same three `Exact` endpoints to the infra
Envoy Gateway (`httpRoute.enabled` and `ingress.enabled` are mutually exclusive).
`httpRoute.hosts` are the `hostnames` the route matches; `ingress.hosts` and
`ingress.tls` are not used here — TLS belongs to the Gateway listener.

```yaml
httpRoute:
  enabled: true
  hosts:
    - x402.mainnet.prod.ecosyseng.cf-deployments.org
  parentRef:
    kind: Gateway
    name: envoy
    namespace: infra-system   # omit for a same-namespace Gateway
```

## External PostgreSQL

Disable cluster creation and provide an existing endpoint and credential Secret:

```yaml
postgres:
  enabled: false
database:
  host: postgres.example.svc.cluster.local
  name: facilitator
  secretName: facilitator-db
  secretUsernameKey: username
  secretPasswordKey: password
```

The Secret must be in the Helm release namespace. Unless `database.url` is
provided, the chart adds `currentSchema=<database.schema>` to the JDBC URL so
both the Spring datasource and Flyway connections use the facilitator schema.
A custom `database.url` must include that parameter itself.

## Clone and point-in-time recovery

`postgres.clone` renders the `clone` section of the `postgresql` resource, so the
operator builds the data directory from another cluster's data instead of running
`initdb`. The source cluster has to archive WAL to the object storage configured
in the operator (`wal_s3_bucket`) for a `timestamp` restore, and `postgres.version`
has to match the source cluster's major version.

Clone into a new cluster without a point in time (live `pg_basebackup`, the source
keeps serving traffic):

```yaml
postgres:
  clusterName: cf-cardano-x402-facilitator-pg
  clone:
    clusterName: cf-cardano-x402-mainnet-facilitator-pg
```

Point-in-time recovery replays WAL up to `timestamp` and therefore needs the
`metadata.uid` of the source cluster, whose archive prefix is used:

```shell
kubectl -n zpg-system get postgresql cf-cardano-x402-mainnet-facilitator-pg \
  -o jsonpath='{.metadata.uid}'
```

```yaml
postgres:
  clusterName: cf-cardano-x402-facilitator-pg
  clone:
    clusterName: cf-cardano-x402-mainnet-facilitator-pg
    uid: 1d1b4a2e-6c3f-11ef-9a1e-0a1234a56789
    timestamp: "2026-02-14T10:30:00+00:00"
```

Nothing else has to point at the bucket. The operator injects `WAL_S3_BUCKET`,
`WAL_BUCKET_SCOPE_PREFIX` (empty) and `WAL_BUCKET_SCOPE_SUFFIX` (`/<uid>`) into
every Postgres pod, and spilo composes the archive location from them plus the
cluster scope, `s3://<wal_s3_bucket>/spilo/<cluster>/<uid>/wal/<version>`.
For a restore the same derivation happens from `CLONE_WAL_S3_BUCKET` and
`CLONE_WAL_BUCKET_SCOPE_SUFFIX`, which is why `uid` is what identifies the
archive and `s3WalPath` is not needed for a cluster of the same environment.

Object storage that the operator cannot derive from its global configuration is
addressed explicitly with `s3WalPath`, `s3Endpoint`, `s3AccessKeyId`,
`s3SecretAccessKey`, and `s3ForcePathStyle`. Those credentials are stored in the
`postgresql` manifest, so prefer the operator's global WAL bucket settings and
pass the overrides only when the clone fails without them. Setting `s3WalPath`
replaces the derived bucket with a literal wal-e style prefix.

Restoring in place keeps the cluster name and therefore the Deployment wiring:
note down the UID, delete the `postgresql` resource, then apply the same release
with `clone.clusterName` set to the cluster's own name plus its `uid` and
`timestamp`.

The operator only acts on `clone` while creating a cluster. Remove the block once
the restored cluster is healthy, and keep in mind that a GitOps controller prunes
the old cluster in the same sync that creates the clone, so a live clone can race
with its own source — a `uid` plus `timestamp` restore reads from object storage
and is unaffected.
