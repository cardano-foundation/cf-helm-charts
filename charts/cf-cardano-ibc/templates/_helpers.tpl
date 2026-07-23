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

{{/* Common labels for the umbrella chart's own templates (postgres CRD). */}}
{{- define "cf-cardano-ibc.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ .Chart.Name | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: cardano-ibc
{{- end }}

{{/* Postgres master Service DNS for the Zalando cluster.
     <clusterName>.<namespace>.svc.cluster.local */}}
{{- define "cf-cardano-ibc.pgHost" -}}
{{- printf "%s.%s.svc.cluster.local" .Values.postgres.clusterName .Values.postgres.namespace -}}
{{- end }}

{{/* Credential Secret name for a given PG user.
     Matches the operator's default secret_name_template '{cluster}-{user}'.
     If your operator uses a different template, override via
     global.gatewayDb.secretName / global.historyDb.secretName. */}}
{{- define "cf-cardano-ibc.pgSecret" -}}
{{- printf "%s-%s" .Values.postgres.clusterName . | trunc 63 | trimSuffix "-" }}
{{- end }}