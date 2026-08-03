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
enough for the Injective-hosted Cardano probabilistic client. Enable the Hermes
sidecar after creating a healthy route and set the route's client IDs:

```yaml
hermes:
  clientRefresh:
    enabled: true
    injectiveCardanoClientId: 08-cardano-probabilistic-123
    cardanoTendermintClientId: 07-tendermint-456
    initialDelaySeconds: 60
    intervalSeconds: 1200
    retryDelaySeconds: 300
    commandTimeoutSeconds: 2400
    idleHeartbeat:
      enabled: true
      idleThresholdSeconds: 1200
      observationIntervalSeconds: 60
      cardanoChannels:
        - portId: transfer
          channelId: channel-1
```

The sidecar uses the same Hermes image, config, and keyring Secrets as the main
relayer. Its normal path matches `caribic/README.md`: every `intervalSeconds` it
updates only `injectiveCardanoClientId`. That operation reads Cardano but writes
only to Injective, so it cannot create a pending Cardano HostState root.

The optional idle-heartbeat state machine works as follows:

1. Every `observationIntervalSeconds`, it queries the probabilistic client on
   Injective. Any change to its `latest_height`, including an update submitted
   by the main relayer, resets the idle timer.
2. Once the height has remained unchanged for `idleThresholdSeconds`, it queries
   Gateway channel health for every configured `cardanoChannels` entry. A
   failed/unparseable query, a non-open channel, or any pending Cardano packet
   commitment defers the heartbeat by `retryDelaySeconds`.
3. If all channels are quiet, it updates `cardanoTendermintClientId` once to
   create a HostState anchor. It then retries only the Injective update until
   Gateway accepts that anchor (normally after about 24 Cardano descendants).
   The Cardano leg is not repeated even if its command fails, because a timeout
   can leave its broadcast outcome uncertain and replacing a maturing anchor
   would restart the stability wait.
4. After the Injective leg succeeds or is already current, the idle timer resets
   and normal Injective-only refreshes resume.

The idle timer is intentionally in memory. A Pod restart starts a fresh full
idle interval, delaying rather than prematurely creating an anchor.
`injectiveCardanoClientId` is required whenever the sidecar is enabled.
`cardanoTendermintClientId` and at least one `cardanoChannels` entry are required
when `idleHeartbeat.enabled` is true. Leave idle heartbeat disabled for a pure
Injective-only loop.

Both containers use the same relayer accounts, so occasional account-sequence
races with packet relaying may occur. Keep the Hermes Deployment at one replica.
The channel-health check reduces unsafe heartbeat timing but cannot prevent a
new user packet from racing immediately after the check.

While a new live HostState waits for stability, Gateway proof queries can fail
with `HEIGHT_NOT_ACCEPTED`. A live packet event rejected during that window is
not replayed to its worker by Hermes. The chart therefore defaults
`packetRelaying.clearInterval` to 10 Cardano blocks (rather than 100) so the
packet worker reconstructs pending packets soon after proofs become available;
`clearOnStart` remains enabled.

The chart also sets the Cardano `event_replay_window` to 50 blocks. Gateway's
Events RPC currently scans at most 101 heights per call, while Hermes applies
its overlap before every call. With Hermes's default 100-block overlap a
backlogged cursor advances only one height per poll; 50 preserves late-indexing
replay while allowing it to catch up by roughly 51 heights per call.

Enabling the sidecar cannot recover a client whose existing update gap already
exceeds Injective's transaction limit. Such a client must first be advanced
through suitably close historical HostState anchors or replaced together with
its connection and channel.

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
