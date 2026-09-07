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
- **yaci-store** (subchart) — chain-follows cardano-node over n2n (TCP 3001);
  `networkMagic` is passed as `STORE_CARDANO_PROTOCOL_MAGIC` so the image picks
  its bundled preprod/preview/mainnet genesis files; yaci DB is Postgres.
- **gateway** (subchart) — two Deployments: `gateway-app` (REST 8000 / gRPC
  5001) and `gateway-bridge-history-sync`; `.env` rendered from values.
- **hermes** (subchart) — config.toml + keys via ConfigMap/Secret; points Cardano
  at the in-cluster Gateway gRPC and Injective at an external RPC endpoint.
- **dapps** (subchart, optional) — swap-client + explorer frontends.

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
