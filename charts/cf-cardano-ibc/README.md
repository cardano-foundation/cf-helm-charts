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

## Out of chart scope

- **Postgres** — provisioned by the Zalando Postgres Operator; this chart only
  consumes the operator's Service DNS + credential Secrets (`global.gatewayDb`,
  `global.yaciDb`).
- **Injective chain** — external RPC endpoints (`global.injective.*`); the chart
  does not run an `injectived` container.
- **Smart-contract deployment** — `caribic deploy_preprod_bridge` /
  `handler.json` are provided out-of-band and mounted into the Gateway.