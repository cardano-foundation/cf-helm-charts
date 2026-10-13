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
