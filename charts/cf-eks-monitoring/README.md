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
