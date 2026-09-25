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
`facilitator-owner-user.cardano-x402-facilitator-pg.credentials.postgresql.acid.zalan.do`.
The Deployment derives both that name and the Postgres Service DNS from the chart values.

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

The Secret must be in the Helm release namespace.
