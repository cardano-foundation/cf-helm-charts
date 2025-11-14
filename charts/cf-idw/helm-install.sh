#!/bin/bash
set -e

HELM_RELEASE_NAME=${HELM_RELEASE_NAME:-cf-idw}
NAMESPACE=${NAMESPACE:-${HELM_RELEASE_NAME}-services}
WITNESS_COUNT=${WITNESS_COUNT:-6}
PUBLIC_DOMAINS=${PUBLIC_DOMAINS:-3x4mpl3.com,example.com}
CHART_LOCATION=${CHART_LOCATION:-.}

helm repo add cardano-foundation https://cardano-foundation.github.io/cf-helm-charts

helm install \
  ${HELM_RELEASE_NAME} \
  ${CHART_LOCATION} \
  --create-namespace \
  --namespace ${NAMESPACE} \
  --set ingressTLDs="{$PUBLIC_DOMAINS}" \
  --set witness.witnessCount=${WITNESS_COUNT}

echo "[+] Install script is now updating your deployment to use the self-hosted witnesses..."

helm get notes -n ${NAMESPACE} ${HELM_RELEASE_NAME} | grep -v ^NOTES > /tmp/$$.helm.notes.sh

bash /tmp/$$.helm.notes.sh
