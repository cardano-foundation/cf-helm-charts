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
{{- printf "%s.%s.svc.cluster.local" .Values.global.postgres.clusterName (.Values.global.postgres.namespace | default .Release.Namespace) -}}
{{- end }}

{{/* Credential Secret names for prepared-database owner users are resolved in
     the gateway / yaci-store subcharts from global.gatewayDb.secretName and
     global.yaciDb.secretName, falling back to Zalando's preparedDatabases
     default: <db>-owner-user.<cluster>.credentials.postgresql.acid.zalan.do. */}}
