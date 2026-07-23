{{/* Resolve the cardano-node socat host for subcharts.
     Defaults to <release>-cf-cardano-node when cf-cardano-node is a dependency. */}}
{{- define "cf-cardano-ibc.cardanoNodeSocatHost" -}}
{{- if .Values.global.cardanoNodeSocatHost }}
{{- .Values.global.cardanoNodeSocatHost }}
{{- else }}
{{- printf "%s-cf-cardano-node" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/* Resolve the ogmios host for kupo. */}}
{{- define "cf-cardano-ibc.ogmiosHost" -}}
{{- printf "%s-cf-ogmios" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Resolve the gateway host (for hermes). */}}
{{- define "cf-cardano-ibc.gatewayHost" -}}
{{- printf "%s-gateway" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}