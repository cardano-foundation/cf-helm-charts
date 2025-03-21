# Cardano Foundation ID Wallet Helm Chart

This Helm chart deploys various components of the Cardano Foundation ID Wallet (cf-idw) including credential issuance, CIP45 sample DApp, Keria, and others.

## Prerequisites

- A Kubernetes cluster
- [kubectl] installed
- [helm] installed
- Cardano Foundation helm chart repository added:
```
helm repo add cardano-foundation https://cardano-foundation.github.io/cf-helm-charts/
```

## Installation

First of all, ensure you have your the proper `KUBECONFIG` and `kubectl context` set for your destination cluster.

To install the chart with the release name `my-release` just execute:

```sh
helm install my-release cardano-foundation/cf-idw
```

# Helm Chart Values

This document provides an overview of the configurable values for the Helm chart. These values can be set in the `values.yaml` file to customize the deployment of the chart.

## Global Configuration

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `ingressTLDs`  | List of top-level domains for ingress | Array of strings | `["example.com"]` |

## Services

### Credential Issuance (`credIssuance`)

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `enabled`      | Enable or disable the service      | Boolean| `true`          |
| `image.repository` | Docker repository for the image | String | `cardanofoundation/cf-cred-issuance` |
| `image.tag`    | Tag of the image                   | String | `main`          |
| `port`         | Port on which the service listens  | Integer| `3001`          |
| `ingress.enabled` | Enable or disable ingress       | Boolean| `true`          |
| `ingress.hosts` | subdomain that will be preprended to the `ingressTLDs` | Array of strings | `["cred-issuance"]` |

### Credential Issuance UI (`credIssuanceUI`)

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `enabled`      | Enable or disable the service      | Boolean| `true`          |
| `image.repository` | Docker repository for the image | String | `cardanofoundation/cf-cred-issuance-ui` |
| `image.tag`    | Tag of the image                   | String | `main`          |
| `port`         | Port on which the service listens  | Integer| `80`            |
| `ingress.enabled` | Enable or disable ingress       | Boolean| `true`          |
| `ingress.hosts` | subdomain that will be preprended to the `ingressTLDs` | Array of strings | `["cred-issuance-ui"]` |

### CIP45 Sample DApp (`cip45`)

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `enabled`      | Enable or disable the service      | Boolean| `true`          |
| `image.repository` | Docker repository for the image | String | `cardanofoundation/cf-cip45-sample-dapp` |
| `image.tag`    | Tag of the image                   | String | `main`          |
| `port`         | Port on which the service listens  | Integer| `80`            |
| `ingress.enabled` | Enable or disable ingress       | Boolean| `true`          |
| `ingress.hosts` | subdomain that will be preprended to the `ingressTLDs` | Array of strings | `["cip45"]`     |

### Keria (`keria`)

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `enabled`      | Enable or disable the service      | Boolean| `true`          |
| `image.repository` | Docker repository for the image | String | `cardanofoundation/cf-idw-keria` |
| `image.tag`    | Tag of the image                   | String | `main`          |
| `logLevel`     | Log level for the service          | String | `INFO`          |
| `ports`        | Ports on which the service listens | Array of integers | `[3901, 3902, 3903]` |
| `ingress.enabled` | Enable or disable ingress       | Boolean| `true`          |
| `ingress.hosts` | subdomains-to-service-port that will be use as prefix for the ingress, preprended to each `ingressTLDs` | Array of objects | `[{"name": "keria", "port": 3901}, {"name": "keria-ext", "port": 3902}, {"name": "keria-boot", "port": 3903}]` |
| `secret.name`  | Name of the secret                 | String | `cf-idw-secrets`|
| `secret.keriaPasscodeKey` | Key for the Keria passcode in the secret | String | `KERIA_PASSCODE` |

### Keria Provisioning (`keriaProvisioning`)

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `enabled`      | Enable or disable the service      | Boolean| `false`         |
| `kind`         | Kubernetes kind for the service. `Deployment` kind will be dependent of a postgres db. | String | `StatefulSet`   |
| `image.repository` | Docker repository for the image | String | `cardanofoundation/cf-keria-provisioning` |
| `image.tag`    | Tag of the image                   | String | `main`          |
| `port`         | Port on which the service listens  | Integer| `9030`          |
| `ingress.enabled` | Enable or disable ingress       | Boolean| `true`          |
| `ingress.hosts` | subdomain that will be preprended to the `ingressTLDs` | Array of strings | `["keria-provisioning"]` |
| `smtp.secret.name` | Name of the secret for SMTP    | String | `cf-idw-secrets`|
| `smtp.secret.sesAccessKeyIdKey` | Key for the AWS SES access key in the secret | String | `SES_ACCESS_KEY_ID` |
| `smtp.secret.sesPasswordKey` | Key for the AWS SES password in the secret | String | `SES_SMTP_PASSWORD` |
| `db.secret.name` | Name of the secret for the database | String | `cf-idw-secrets` |
| `db.secret.usernameKey` | Key for the database username in the secret | String | `POSTGRES_USER` |
| `db.secret.passwordKey` | Key for the database password in the secret | String | `POSTGRES_PASSWORD` |
| `db.secret.hostKey` | Key for the database host in the secret | String | `POSTGRES_HOST` |
| `db.secret.dbNameKey` | Key for the database name in the secret | String | `POSTGRES_DB` |

### Witness (`witness`)

| Parameter      | Description                        | Type   | Default         |
|----------------|------------------------------------|--------|-----------------|
| `enabled`      | Enable or disable the service      | Boolean| `true`          |
| `image.repository` | Docker repository for the image | String | `cardanofoundation/cf-idw-witness` |
| `image.tag`    | Tag of the image                   | String | `0.1.1-customize-keria-docker-image-863f2c2-9956455103` |
| `witnessCount` | Number of witnesses                | Integer| `6`             |
| `initialHTTPPort` | Initial HTTP port               | Integer| `5642`          |
| `initialTCPPort` | Initial TCP port                 | Integer| `5632`          |
| `logLevel`     | Log level for the service          | String | `INFO`          |
| `ingress.enabled` | Enable or disable ingress       | Boolean| `true`          |
| `ingress.hosts` | subdomain that will be preprended to the `ingressTLDs` | Array of strings | `["witness"]`   |


[helm]: https://helm.sh
[kubectl]: https://kubernetes.io/docs/tasks/tools/#kubectl
