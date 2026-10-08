# cf-cardano-ibc

Cardano↔Injective IBC bridge — Helm chart.

Peers a self-hosted Cardano follower node + indexers (Kupo, Ogmios, Yaci Store)
with the IBC Gateway and Hermes relayer, paired with an external Injective RPC
endpoint.

## Topology (preprod)

- **cf-cardano-node** (standalone chart) — follower peering with public preprod
  over n2n (TCP 3001); a socat sidecar exposes the n2c socket over TCP so
  in-cluster indexers reach it without sharing a socket volume.
- **cf-ogmios** (standalone chart) — socat client sidecar re-creates a local
  Unix socket from the cardano-node socat Service; `--node-socket` points at it.
- **cf-kupo** (standalone chart) — defaults to `--ogmios-host` (WebSocket to
  Ogmios); can flip to its own socat sidecar via `source: node-socket`.
- **cf-yaci-store** (standalone chart, aliased as the `yaci-store` dependency) —
  chain-follows cardano-node over n2n (TCP 3001); `networkMagic` is passed as
  `STORE_CARDANO_PROTOCOL_MAGIC` so the image picks its bundled
  preprod/preview/mainnet genesis files; yaci DB is Postgres.
- **gateway** (subchart) — two Deployments: `gateway-app` (REST 8000 / gRPC
  5001) and `gateway-bridge-history-sync`; `.env` rendered from values.
- **hermes** (subchart) — config.toml + keys via ConfigMap/Secret; points Cardano
  at the in-cluster Gateway gRPC and Injective at an external RPC endpoint.
- **dapps** (subchart, optional) — swap-client + explorer frontends.

## Blockfrost

Public-network Gateway history uses Blockfrost for epoch nonces, stake snapshots,
and historical pool registrations. Set the API endpoint through
`gateway.env.CARDANO_BLOCKFROST_ENDPOINT`; when omitted, Gateway selects the
hosted endpoint from `CARDANO_NETWORK_MAGIC`. Supply the hosted API project ID
from a Secret:

```yaml
gateway:
  env:
    CARDANO_BLOCKFROST_ENDPOINT: https://cardano-preview.blockfrost.io/api/v0
  blockfrostProjectIdSecret:
    name: gateway-secrets
    key: blockfrostProjectId
```

The Secret value is exposed to Gateway as `CARDANO_BLOCKFROST_PROJECT_ID` and
is sent to Blockfrost in the `project_id` header. Do not use a Koios API key as
a Blockfrost project ID; omit `blockfrostProjectIdSecret.name` until the named
Secret contains the correct key.

## Preview bridge cutover

The dev Argo CD application supplies `ibc:` from
`ecosystem-engineering-deployment/argocd/charts/main-app/values-dev.yaml`, not
`values-preview.yaml`. For the October 8 Preview bridge, the inline Gateway
ConfigMap is an exact copy of the authenticated IBC repository manifest
(`cardano-preview:df48c007…`). Gateway reads the chart-rendered ConfigMap;
the image's bundled manifest is **not** selected while inline content is
present. `IBC_DEPLOYMENT_MODE=legacy` must agree with the manifest. Newer Hermes
builds can optionally mount this manifest; the dev-pinned PR857 Hermes does not
support `bridge_manifest_path` or independent signing endpoint fields.

Publish this chart's `feat/cf-ibc` changes **before** the dev Argo values change:
older chart revisions ignore `hermes.replicas: 0` and would leave the relayer
running with the old key. While replicas are zero, Argo syncs the Hermes scale
down in wave -1 ahead of the new Gateway ConfigMap. Do not sync the new manifest
with a running old signer. No Helm values change or local key export rotates the
Kubernetes `hermes-keys` Secret.

The existing Yaci intersection (block 4660299) is deliberately retained. It
precedes the new manifest checkpoint (4735054); a newer Yaci start would risk
losing history. Before resuming Hermes, check the **Gateway pod's actual**
`HISTORY_DB` for checkpoint successor 4735055 linked to the manifest block hash,
contiguous raw blocks/transaction CBOR through the new HostState mint, and
matching `bridge_tx_evidence` for the creation and live HostState transactions.
The history-sync cursor `complete-block-v2` persists independently of the
manifest: if it has passed the new deployment with the old projection filter,
a controlled projection replay may be required. Do not reset the DB or cursor
without a backup and inspection. Require `/health/ready` to return 200 before
resuming Hermes or routing transactions.

The dev Hermes Deployment remains at **zero replicas** until its Cardano key
is rotated externally and Gateway is proof-ready. The pinned PR857 Hermes
image accepts the in-cluster HTTP Gateway Service, but does not independently
authorize Gateway-built transactions with a pinned manifest. Newer Hermes
builds (after `f8780b26`) require an operator-pinned manifest and reject
non-loopback plaintext Gateway, signing Kupo, and signing Ogmios connections;
the Gateway's REST ingress is **not** a TLS gRPC endpoint. This chart does not
validate endpoint URL schemes. If upgrading the signer, provision suitable
authenticated transport and configure its pinned manifest and independent
signing sources first. Keep `clientRefresh` off until a new Injective-side
client is healthy.

## Hermes keys

The Hermes image runs as user `hermes`; the chart mounts config and keys under
`/home/hermes/.hermes`. Provide a Secret named `hermes-keys` by default with
Hermes keyring JSON file contents, not raw mnemonic-only files:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: hermes-keys
type: Opaque
stringData:
  cardano-relayer.json: |
    {"mnemonic":"<cardano mnemonic or ed25519_sk...>","account":0,"network_id":0}
  injective-888-relayer.json: |
    <contents of ~/.hermes/keys/injective-888/keyring-test/injective-888-relayer.json>
```

The chart mounts each Secret entry directly at that chain's `keyring-test`
directory and maps it to Hermes' expected filename:

```text
/home/hermes/.hermes/keys/<cardano-chain-id>/keyring-test/<cardano-key-name>.json
/home/hermes/.hermes/keys/<injective-chain-id>/keyring-test/<injective-key-name>.json
```

For `values-preview.yaml`, that resolves to:

```text
/home/hermes/.hermes/keys/cardano-preview/keyring-test/cardano-relayer.json
/home/hermes/.hermes/keys/injective-888/keyring-test/injective-888-relayer.json
```

Kubernetes Secret volumes still expose implementation-detail `..data` symlinks
inside each mounted `keyring-test` directory, but the chain directories
(`cardano-preview`, `injective-888`) are normal parent directories rather than
top-level projected-volume symlinks.

## Periodic client refresh

The standard Hermes refresh worker is trusting-period based and is not frequent
enough for the Injective-hosted Cardano probabilistic client. After creating a
healthy route, enable the optional sidecar with that client's ID:

```yaml
hermes:
  clientRefresh:
    enabled: true
    injectiveCardanoClientId: 08-cardano-probabilistic-123
    intervalSeconds: 1200
```

The sidecar mirrors the loop documented in `caribic/README.md`:

```bash
while true; do
  hermes update client \
    --host-chain injective-888 \
    --client 08-cardano-probabilistic-123
  sleep 1200
done
```

It reads Cardano to construct the update but writes only to Injective. The main
Hermes daemon independently provides HostState anchor points through
`host_state_heartbeat_interval = '60s'`; the sidecar never updates a
Cardano-hosted Tendermint client and never submits a Cardano transaction. A
failed or already-current update simply waits until the next interval.

The sidecar and main relayer share the Injective account, so transactions can
occasionally race its account sequence. Keep the Hermes Deployment at one
replica. Enabling the sidecar cannot recover a client whose existing update gap
already exceeds Injective's transaction limit; such a client must be advanced
through suitable historical HostState anchors or replaced with its connection
and channel.

The rendered Hermes packet and Cardano event-source settings follow caribic:
`clear_interval = 100`, `clear_on_start = true`, and no explicit
`event_replay_window` (Hermes therefore uses its 100-block default).

## Out of chart scope

- **Postgres** — provisioned by the Zalando Postgres Operator; this chart only
  consumes the operator's Service DNS + credential Secrets (`global.gatewayDb`,
  `global.yaciDb`).
- **Injective chain** — external RPC endpoints (`global.injective.*`); the chart
  does not run an `injectived` container.
- **Smart-contract deployment** — `caribic deploy_preprod_bridge` produces
  the bridge deployment config. The Gateway can start from either a compact
  `bridge-manifest.json` (`BRIDGE_MANIFEST_PATH`) or legacy `handler.json`
  (`HANDLER_JSON_PATH`). Configure this per deployment with
  `gateway.deploymentConfig`; for custom deployments mount the file from an
  operator-created ConfigMap (or inline chart-created ConfigMap).

Example custom `handler.json` ConfigMap wiring:

```yaml
gateway:
  deploymentConfig:
    source: handlerJson
    configMap:
      name: cardano-ibc-handler
      key: handler.json
```
