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
- **Gateway** — one Deployment (REST 8000 / gRPC 5001). Reads history from
  Yaci Store's REST API; only Yaci Store connects to the history database.
- **Hermes** — config.toml + keys via ConfigMap/Secret; uses in-cluster Gateway
  gRPC over TLS and Injective's external RPC.
- **dApps** (optional) — swap-client and explorer frontends.

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

## Images and Preview cutover

Gateway, Hermes and Swap are pinned by digest in `values.yaml`. These are the
published linux/amd64 builds of [PR #1092's merge tree](https://github.com/cardano-foundation/cardano-ibc-incubator/actions/runs/45163033364)
(`056c344`), identical to `main` at `1e7d67b2`. Update the tag and digest
together when advancing the pin.

The dev Argo CD app uses `ibc:` from
`ecosystem-engineering-deployment/argocd/charts/main-app/values-dev.yaml`.
It and the standalone `values-preview.yaml` select the same governed Preview
bridge and the existing `transfer/channel-0` ↔ `transfer/channel-77176` route.
The manifest is too large for a ConfigMap. Gateway reads the manifest baked
into its pinned image; Hermes copies the same file from that digest in an
init container. Hermes never fetches its signing manifest from Gateway RPC.

1. Stop the previous Hermes instance before syncing the chart and dev values
   together. Dev's cert-manager issues the gRPC TLS Secret. The incoming
   Hermes Deployment is staged at zero replicas.
2. Preserve the existing dev Yaci intersection (block 4754933) and database.
   Verify that the Yaci REST API retains block/transaction CBOR from the
   manifest checkpoint (4870744) and that asset and address history are available.
3. Check Gateway returns HTTP 200 from `/health/ready`. Confirm that the
   configured route is open, its clients are active, and `hermes-keys` holds
   the intended funded keys. Set `hermes.replicas: 1` once no other instance
   is using those keys. A manifest cutover does not repair old clients or
   rotate keys.

Kubernetes readiness uses `/health` to check Gateway Postgres and Yaci REST
connectivity. A fresh HostState waiting for proof stability does not remove
the Gateway from the Service.

Hermes still waits for `/health/ready` at startup. That check uses
`gateway.env.GATEWAY_READINESS_PROOF_TIMEOUT_MS` as its proof budget; the Hermes
init container allows that budget rounded up to seconds plus 15 seconds for
other HTTP work (135 seconds in Preview). Proof acceptance is unchanged.
The Gateway startup probe separately allows the cold-history budget
(`BRIDGE_HISTORY_SYNC_TIMEOUT_SECONDS`) plus margin.

## Gateway gRPC TLS

Set `gateway.grpcTls.existingSecret` to the TLS Secret name in the release
namespace. Dev also sets `gateway.grpcTls.certManager.enabled: true`. With
cert-manager installed, the chart bootstraps a namespaced private CA and
issues a server certificate with the Gateway Service DNS name as its SAN
(`cf-cardano-ibc-gateway` in dev). No public ACME issuer is needed.

For externally managed TLS, leave chart issuance disabled and supply
`tls.crt`, `tls.key` and `ca.crt` in the referenced Secret. Gateway mounts
only the server certificate and key; Hermes mounts only the CA certificate.
Restart Gateway after server certificate renewal, and restart Hermes if the
CA changes. Plan CA rotation separately; cert-manager does not automatically
reissue the server certificate when the CA Secret changes.

The REST ingress does not serve gRPC. Keep the gRPC Service private and
restrict it to trusted workloads. Without a TLS Secret, Gateway binds gRPC
to loopback and the Service exposes only REST. A custom
`hermes.config.cardano.gatewayUrl` must use HTTPS and, when set, uses native
trust roots.

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

The chart projects each Secret entry read-only into an init container. Once
Gateway is ready, the init container copies the keys as regular files into a
memory-backed writable volume (directories `0700`, files `0600`, owned by the
Hermes image user `2000:2000`). Hermes reads them at:

```text
/home/hermes/.hermes/keys/<cardano-chain-id>/keyring-test/<cardano-key-name>.json
/home/hermes/.hermes/keys/<injective-chain-id>/keyring-test/<injective-key-name>.json
```

For `values-preview.yaml`, that resolves to:

```text
/home/hermes/.hermes/keys/cardano-preview/keyring-test/cardano-relayer.json
/home/hermes/.hermes/keys/injective-888/keyring-test/injective-888-relayer.json
```

Do not mount the Secret directly as the runtime keyring: Hermes secures its
keyring directories and files on read and refuses symlinked key files, while
Kubernetes Secret volumes are read-only and use projected symlinks. A Secret
rotation requires restarting the Hermes Pod to recopy the new key files.

## Periodic client refresh

Hermes' built-in refresh follows the client's trusting period. To schedule
additional updates for a healthy route, enable the optional sidecar with
the active Injective-side client's ID:

```yaml
hermes:
  clientRefresh:
    enabled: true
    injectiveCardanoClientId: 08-cardano-probabilistic-123
    intervalSeconds: 1200
```

Preview uses only Hermes' built-in client refresh; do not enable the sidecar
for the old bridge's client. The optional loop is documented in
`caribic/README.md`:

```bash
while true; do
  hermes update client \
    --host-chain injective-888 \
    --client 08-cardano-probabilistic-123
  sleep 1200
done
```

It reads Cardano to construct the update but writes only to Injective. The sidecar never updates a Cardano-hosted Tendermint client and never
submits a Cardano transaction. Automatic HostState heartbeats are disabled
by default. A failed or already-current update waits until the next interval.

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
- **Smart-contract deployment** — the chart does not deploy contracts. The
  pinned Gateway image does not include a current Preprod manifest. Before
  installing `values-preprod.yaml`, supply a compatible governed manifest,
  the matching Yaci intersection, and a Blockfrost project ID. Enable Hermes
  only after configuring TLS and independent HTTPS signing endpoints.

Set `gateway.deploymentConfig.path` for a manifest in an operator-pinned
image. For a file that fits in a ConfigMap, leave `path` empty and set
`gateway.deploymentConfig.configMap.name` (existing ConfigMap) or
`gateway.deploymentConfig.configMap.content` (chart-created ConfigMap).
Gateway and Hermes use the same manifest file in either case. Legacy
`handler.json` deployments are not supported.
