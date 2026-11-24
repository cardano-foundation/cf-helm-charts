# cf-programmable-tokens-platform

Helm chart for the [CIP-113 programmable tokens platform](https://github.com/cardano-foundation/cip113-programmable-tokens-platform):

| Component | Kind | Notes |
|---|---|---|
| `<fullname>-ui` | Deployment + Service | Next.js frontend, image `<ui.image.tag>-<network>` |
| `<fullname>-indexer` | Deployment (1 pod, `Recreate`) + Service | Spring Boot backend + yaci-store indexer |
| `<teamId>-<fullname>` | `postgresql` (Zalando) | optional, `postgres.create` |
| routes | Ingress **or** HTTPRoute | `exposure.type`, one per non-empty `hosts.*` |

One release per network, one network per namespace.

## Minimal values

```yaml
fullnameOverride: programmable-tokens
network: preprod                       # preview | preprod | mainnet
hosts:
  ui: preprod.example.org
  indexer: preprod-indexer.example.org # must match the API base URL baked into the UI image
ui:
  image: { tag: ab75bd5 }              # renders cip113-frontend:ab75bd5-preprod
indexer:
  image: { tag: dd94999 }
blockfrost:
  existingSecret: { name: programmable-tokens-blockfrost }  # key BLOCKFROST_PROJECT_ID
```

With `keri.enabled: true` also set `keri.url`, `keri.bootUrl` and `keri.secret.name`.
That Secret must hold `bran` and `signing-mnemonic`.

## Things that fail far from their cause

- **The frontend is configured at build time.** `NEXT_PUBLIC_*` (network, Blockfrost, API
  base URL, module flags) are inlined by the image build, and pod env cannot change them.
  Pointing the UI at a different indexer hostname needs a new image. The only runtime flag
  is `OPS_ENABLED` (`ui.opsEnabled`). With it off, `/ops` answers 404 by design.
- **The RWA creation audience is part of a signature.** The browser signs
  `NEXT_PUBLIC_API_BASE_URL + /api/v1` and the backend verifies against
  `RWA_TOKEN_CREATION_AUDIENCE`, which is derived from `hosts.indexer`. A mismatch (other
  host, scheme or a trailing slash) rejects every signed creation request, and the
  signature still looks valid.
- **The indexer is a singleton.** With `kycExtended` on it signs and submits root updates,
  and there is no idempotence key. Under `Recreate`, a pod that cannot start is an outage,
  not a stalled rollout. Roll forward to recover.
- **Green probes do not mean progress.** The probes are TCP only (the image has no
  actuator), and an unreachable node is retried, not failed. Watch the sync slot in the
  logs.
- **The database role must own the database** on Postgres 15+. Otherwise Flyway fails at
  the first migration *after* a successful connect.
- **Disabling or switching routing only stops rendering the objects.** Under Argo CD with
  `prune: false` the old Ingress/HTTPRoute stays in the cluster.

## Migrating from `programmable-tokens-poc`

Renamed keys are refused at render time: `replicas`, `ingress.*`, `blockfrost.key`.
The POC hardcoded these resource names. They are reproduced with
`fullnameOverride: programmable-tokens`, which also keeps the Postgres cluster name
`e1-programmable-tokens`.
