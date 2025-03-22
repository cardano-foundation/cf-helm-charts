# Cardano Foundation ID Wallet Helm Chart

This Helm chart deploys various components of the Cardano Foundation ID Wallet (cf-idw), including credential issuance, CIP45 sample DApp, Keria, and others.

## Prerequisites

Before you begin, ensure you have the following:

- A Kubernetes cluster
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) installed
- [helm](https://helm.sh) installed
- Add the Cardano Foundation Helm chart repository:
  ```sh
  helm repo add cardano-foundation https://cardano-foundation.github.io/cf-helm-charts/
  ```

## Installation

Ensure your `KUBECONFIG` and `kubectl context` are set for your destination cluster. Then, follow one of the methods below to install the chart.

### Using the helm-install Script

1. **Download AND review the script**:
   ```sh
   curl -so /tmp/helm-install.sh https://raw.githubusercontent.com/cardano-foundation/cf-helm-charts/main/charts/cf-idw/helm-install.sh
   ```

2. **Execute the script** with the required environment variables:
   ```sh
   export NAMESPACE=cf-idw-services
   export WITNESS_COUNT=6  # Number of witnesses to deploy
   export PUBLIC_DOMAINS=3x4mpl3.com,example.com  # Comma-separated list of public domains where the deployment will be served from 
   bash /tmp/helm-install.sh
   ```

3. **Get the full list of URLs** if you already have an ingress controller managing SSL certificates:
   ```sh
   for host in $(kubectl get ingress -n ${NAMESPACE} -o jsonpath='{.items[*].spec.rules[*].host}'); do
     echo https://$host
   done | sort
   ```

### Manual Helm Installation

1. **Add the Helm repository**:
   ```sh
   helm repo add cardano-foundation https://cardano-foundation.github.io/cf-helm-charts
   ```

2. **Customize the deployment**. Most of the default chart values will be okay for basic deployments, but after checking the [documentation](#Value) you might want to customize some like:
   - `keria.passCode`. The chart will automatically generate one, but you might want to provide one yourself. You can generate one yourself using [signify-ts](https://github.com/WebOfTrust/signify-ts) or using our handy docker image:
     ```sh
     docker run -it --rm cardanofoundation/cf-keria-passcode-gen
     ```
   - `witness.witnessCount`. You might want to increase the default or just disable them by setting `witness.enabled` to `false`.

3. **Install the chart** with the release name `my-release`:
   ```sh
   export PUBLIC_DOMAINS="3x4mpl3.com,example.com"
   helm install my-release --set ingressTLDs="{$PUBLIC_DOMAINS}" cardano-foundation/cf-idw
   ```

4. **Configure Keria** to use a set of witnesses. You can follow the helm chart install notes shown after the successful `helm install`, provide `keria.keriaIurls` before hand in the `helm install` step or use update the deployment afterwards like this:
   ```sh
   export WITNESSES_URLS="https://witness0.other.com/oobi/BI3WKCsAmFq2NteYBf3Wt5iW7T1ynnBqponEMjHM0dtI/controller?role=witness https://witness1.other.com/oobi/BJftdAJsxd40opYt-dE0iOVZDXssITq_Xv2E83Hch1HX/controller?role=witness"
   helm upgrade my-release cardano-foundation/cf-idw --reuse-values --set keria.keriaIurls="$WITNESSES_URLS"
   ```

# Values

This is an overview of the configurable values for the Helm chart. These values can be set in a `values.yaml` file to customize the deployment of the chart.

## Global Configuration

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `ingressTLDs`  | List of top-level domains for ingress | Array of strings | `["example.com"]` |

## Services

### Credential Issuance (`credIssuance`)

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `credIssuance.enabled`      | Enable or disable the service      | Boolean| `true`          |
| `credIssuance.image.repository` | Docker repository for the image | String | `cardanofoundation/cf-cred-issuance` |
| `credIssuance.image.tag`    | Tag of the image                   | String | `main`          |
| `credIssuance.port`         | Port on which the service listens  | Integer| `3001`          |
| `credIssuance.ingress.enabled` | Enable or disable ingress       | Boolean| `true`          |
| `credIssuance.ingress.hosts` | subdomain that will be preprended to the `ingressTLDs` | Array of strings | `["cred-issuance"]` |

### Credential Issuance UI (`credIssuanceUI`)

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `credIssuanceUI.enabled`      | Enable or disable the service      | Boolean| `true`          |
| `credIssuanceUI.image.repository` | Docker repository for the image | String | `cardanofoundation/cf-cred-issuance-ui` |
| `credIssuanceUI.image.tag`    | Tag of the image                   | String | `main`          |
| `credIssuanceUI.port`         | Port on which the service listens  | Integer| `80`            |
| `credIssuanceUI.ingress.enabled` | Enable or disable ingress       | Boolean| `true`          |
| `credIssuanceUI.ingress.hosts` | subdomain that will be preprended to the `ingressTLDs` | Array of strings | `["cred-issuance-ui"]` |

### CIP45 Sample DApp (`cip45`)

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `cip45.enabled`      | Enable or disable the service      | Boolean| `true`          |
| `cip45.image.repository` | Docker repository for the image | String | `cardanofoundation/cf-cip45-sample-dapp` |
| `cip45.image.tag`    | Tag of the image                   | String | `main`          |
| `cip45.port`         | Port on which the service listens  | Integer| `80`            |
| `cip45.ingress.enabled` | Enable or disable ingress       | Boolean| `true`          |
| `cip45.ingress.hosts` | subdomain that will be preprended to the `ingressTLDs` | Array of strings | `["cip45"]`     |

### Keria (`keria`)

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `keria.enabled`      | Enable or disable the service      | Boolean| `true`          |
| `keria.image.repository` | Docker repository for the image | String | `cardanofoundation/cf-idw-keria` |
| `keria.image.tag`    | Tag of the image                   | String | `main`          |
| `keria.logLevel`     | Log level for the service          | String | `INFO`          |
| `keria.ports`        | Ports on which the service listens | Array of integers | `[3901, 3902, 3903]` |
| `keria.ingress.enabled` | Enable or disable ingress       | Boolean| `true`          |
| `keria.ingress.hosts` | subdomains-to-service-port that will be use as prefix for the ingress, preprended to each `ingressTLDs` | Array of objects | `[{"name": "keria", "port": 3901}, {"name": "keria-ext", "port": 3902}, {"name": "keria-boot", "port": 3903}]` |
| `keria.secret.name`  | Name of the secret                 | String | `cf-idw-secrets`|
| `keria.secret.keriaPasscodeKey` | Key for the Keria passcode in the secret | String | `KERIA_PASSCODE` |

### Keria Provisioning (`keriaProvisioning`)

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `keriaProvisioning.enabled`      | Enable or disable the service      | Boolean| `false`         |
| `keriaProvisioning.kind`         | Kubernetes kind for the service. `Deployment` kind will be dependent of a postgres db. | String | `StatefulSet`   |
| `keriaProvisioning.image.repository` | Docker repository for the image | String | `cardanofoundation/cf-keria-provisioning` |
| `keriaProvisioning.image.tag`    | Tag of the image                   | String | `main`          |
| `keriaProvisioning.port`         | Port on which the service listens  | Integer| `9030`          |
| `keriaProvisioning.ingress.enabled` | Enable or disable ingress       | Boolean| `true`          |
| `keriaProvisioning.ingress.hosts` | subdomain that will be preprended to the `ingressTLDs` | Array of strings | `["keria-provisioning"]` |
| `keriaProvisioning.smtp.secret.name` | Name of the secret for SMTP    | String | `cf-idw-secrets`|
| `keriaProvisioning.smtp.secret.sesAccessKeyIdKey` | Key for the AWS SES access key in the secret | String | `SES_ACCESS_KEY_ID` |
| `keriaProvisioning.smtp.secret.sesPasswordKey` | Key for the AWS SES password in the secret | String | `SES_SMTP_PASSWORD` |
| `keriaProvisioning.db.secret.name` | Name of the secret for the database | String | `cf-idw-secrets` |
| `keriaProvisioning.db.secret.usernameKey` | Key for the database username in the secret | String | `POSTGRES_USER` |
| `keriaProvisioning.db.secret.passwordKey` | Key for the database password in the secret | String | `POSTGRES_PASSWORD` |
| `keriaProvisioning.db.secret.hostKey` | Key for the database host in the secret | String | `POSTGRES_HOST` |
| `keriaProvisioning.db.secret.dbNameKey` | Key for the database name in the secret | String | `POSTGRES_DB` |

### Witness (`witness`)

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `witness.enabled`      | Enable or disable the service      | Boolean| `true`          |
| `witness.image.repository` | Docker repository for the image | String | `cardanofoundation/cf-idw-witness` |
| `witness.image.tag`    | Tag of the image                   | String | `0.1.1-customize-keria-docker-image-863f2c2-9956455103` |
| `witness.witnessCount` | Number of witnesses                | Integer| `6`             |
| `witness.initialHTTPPort` | Initial HTTP port. Any extra witness will increment its port from this one | Integer| `5642`          |
| `witness.initialTCPPort` | Initial TCP port. Any extra witness will increment its port from this one | Integer| `5632`          |
| `witness.logLevel`     | Log level for the service          | String | `INFO`          |
| `witness.ingress.enabled` | Enable or disable ingress       | Boolean| `true`          |
| `witness.ingress.hosts` | subdomain that will be preprended to the `ingressTLDs` | Array of strings | `["witness"]`   |


[helm]: https://helm.sh
[kubectl]: https://kubernetes.io/docs/tasks/tools/#kubectl
