{{/* dapps helpers (was the dapps subchart at charts/dapps/).
     Value shapes are unchanged from the subchart — see values.yaml. */}}
{{- define "dapps.fullname" -}}{{- if .Values.dapps.fullnameOverride }}{{- .Values.dapps.fullnameOverride | trunc 63 | trimSuffix "-" -}}{{- else }}{{- printf "%s-dapps" .Release.Name | trunc 63 | trimSuffix "-" -}}{{- end }}{{- end }}
{{- define "dapps.swapFullname" -}}{{- printf "%s-swap-client" .Release.Name | trunc 63 | trimSuffix "-" -}}{{- end }}
{{- define "dapps.explorerFullname" -}}{{- printf "%s-explorer" .Release.Name | trunc 63 | trimSuffix "-" -}}{{- end }}

{{- define "dapps.cardanoNetwork" -}}
{{- if and .Values.dapps.swapClient .Values.dapps.swapClient.cardanoNetwork -}}{{- .Values.dapps.swapClient.cardanoNetwork -}}{{- else if and .Values.global .Values.global.cardanoNetwork -}}{{- .Values.global.cardanoNetwork -}}{{- else -}}preprod{{- end -}}
{{- end }}

{{- define "dapps.protocolMagic" -}}
{{- if and .Values.global (hasKey .Values.global "protocolMagic") -}}{{- .Values.global.protocolMagic -}}{{- else -}}1{{- end -}}
{{- end }}

{{- define "dapps.swapMode" -}}
{{- if .Values.dapps.swapClient.mode -}}{{- .Values.dapps.swapClient.mode -}}
{{- else if eq (include "dapps.cardanoNetwork" .) "mainnet" -}}mainnet
{{- else -}}testnet{{- end -}}
{{- end }}

{{- define "dapps.cardanoChainId" -}}
{{- if .Values.dapps.swapClient.cardanoChainId -}}{{- .Values.dapps.swapClient.cardanoChainId -}}{{- else -}}{{- include "dapps.protocolMagic" . -}}{{- end -}}
{{- end }}

{{- define "dapps.cardanoIbcChainId" -}}
{{- if .Values.dapps.swapClient.cardanoIbcChainId -}}{{- .Values.dapps.swapClient.cardanoIbcChainId -}}{{- else -}}cardano-{{ include "dapps.cardanoNetwork" . }}{{- end -}}
{{- end }}

{{- define "dapps.gatewayEndpoint" -}}
{{- if .Values.dapps.swapClient.gatewayEndpoint -}}{{- .Values.dapps.swapClient.gatewayEndpoint -}}{{- else -}}http://{{ .Release.Name }}-gateway:8000{{- end -}}
{{- end }}

{{- define "dapps.publicGatewayEndpoint" -}}
{{- if .Values.dapps.swapClient.publicGatewayEndpoint -}}{{- .Values.dapps.swapClient.publicGatewayEndpoint -}}
{{- else if and .Values.global (index .Values.global "publicGatewayEndpoint") -}}{{- index .Values.global "publicGatewayEndpoint" -}}
{{- else -}}{{- include "dapps.gatewayEndpoint" . -}}{{- end -}}
{{- end }}

{{- define "dapps.cardanoBridgeManifestUrl" -}}
{{- if .Values.dapps.swapClient.cardanoBridgeManifestUrl -}}{{- .Values.dapps.swapClient.cardanoBridgeManifestUrl -}}{{- else -}}{{ include "dapps.gatewayEndpoint" . }}/api/bridge-manifest{{- end -}}
{{- end }}

{{- define "dapps.kupoEndpoint" -}}
{{- if .Values.dapps.swapClient.kupoEndpoint -}}{{- .Values.dapps.swapClient.kupoEndpoint -}}
{{- else if and .Values.global (index .Values.global "kupoEndpoint") -}}{{- index .Values.global "kupoEndpoint" -}}
{{- else -}}http://{{ .Release.Name }}-cf-kupo:1442{{- end -}}
{{- end }}

{{- define "dapps.ogmiosEndpoint" -}}
{{- if .Values.dapps.swapClient.ogmiosEndpoint -}}{{- .Values.dapps.swapClient.ogmiosEndpoint -}}
{{- else if and .Values.global (index .Values.global "ogmiosEndpoint") -}}{{- index .Values.global "ogmiosEndpoint" -}}
{{- else -}}http://{{ .Release.Name }}-cf-ogmios:1337{{- end -}}
{{- end }}

{{- define "dapps.kupmiosUrl" -}}
{{- if .Values.dapps.swapClient.kupmiosUrl -}}{{- .Values.dapps.swapClient.kupmiosUrl -}}{{- else -}}{{ include "dapps.kupoEndpoint" . }},{{ include "dapps.ogmiosEndpoint" . }}{{- end -}}
{{- end }}

{{- define "dapps.injectiveRpcEndpoint" -}}
{{- if .Values.dapps.swapClient.injectiveRpcEndpoint -}}{{- .Values.dapps.swapClient.injectiveRpcEndpoint -}}
{{- else if and .Values.global .Values.global.injective (index .Values.global.injective "rpcAddr") -}}{{- index .Values.global.injective "rpcAddr" -}}
{{- end -}}
{{- end }}

{{- define "dapps.injectiveRestEndpoint" -}}
{{- if .Values.dapps.swapClient.injectiveRestEndpoint -}}{{- .Values.dapps.swapClient.injectiveRestEndpoint -}}
{{- else if and .Values.global .Values.global.injective (index .Values.global.injective "restAddr") -}}{{- index .Values.global.injective "restAddr" -}}
{{- end -}}
{{- end }}

{{- define "dapps.explorerCardanoChainId" -}}
{{- if .Values.dapps.explorer.cardanoChainId -}}{{- .Values.dapps.explorer.cardanoChainId -}}{{- else -}}{{- include "dapps.protocolMagic" . -}}{{- end -}}
{{- end }}
