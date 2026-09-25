{{/* Expand the chart name. */}}
{{- define "cf-cardano-x402-facilitator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Create a fully qualified app name. */}}
{{- define "cf-cardano-x402-facilitator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/* Chart name and version label. */}}
{{- define "cf-cardano-x402-facilitator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels. */}}
{{- define "cf-cardano-x402-facilitator.labels" -}}
helm.sh/chart: {{ include "cf-cardano-x402-facilitator.chart" . }}
{{ include "cf-cardano-x402-facilitator.selectorLabels" . }}
app.kubernetes.io/part-of: cardano-x402
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Stable selector labels. */}}
{{- define "cf-cardano-x402-facilitator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cf-cardano-x402-facilitator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Facilitator image reference. */}}
{{- define "cf-cardano-x402-facilitator.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end }}

{{/* Zalando Postgres cluster name and namespace. */}}
{{- define "cf-cardano-x402-facilitator.postgresClusterName" -}}
{{- required "postgres.clusterName is required when postgres.enabled=true" .Values.postgres.clusterName -}}
{{- end }}

{{- define "cf-cardano-x402-facilitator.postgresNamespace" -}}
{{- required "postgres.namespace is required when postgres.enabled=true" .Values.postgres.namespace -}}
{{- end }}

{{- define "cf-cardano-x402-facilitator.postgresSecretNamespace" -}}
{{- default .Release.Namespace .Values.postgres.secretNamespace -}}
{{- end }}

{{/* Resolve the database endpoint. */}}
{{- define "cf-cardano-x402-facilitator.databaseHost" -}}
{{- if .Values.database.host -}}
{{- .Values.database.host -}}
{{- else if .Values.postgres.enabled -}}
{{- printf "%s.%s.svc.cluster.local" (include "cf-cardano-x402-facilitator.postgresClusterName" .) (include "cf-cardano-x402-facilitator.postgresNamespace" .) -}}
{{- else -}}
{{- fail "database.host is required when postgres.enabled=false and database.url is empty" -}}
{{- end -}}
{{- end }}

{{- define "cf-cardano-x402-facilitator.databaseUrl" -}}
{{- if .Values.database.url -}}
{{- .Values.database.url -}}
{{- else -}}
{{- printf "jdbc:postgresql://%s:%v/%s" (include "cf-cardano-x402-facilitator.databaseHost" .) .Values.database.port (required "database.name is required" .Values.database.name) -}}
{{- end -}}
{{- end }}

{{/* Resolve the credential Secret generated for the prepared database owner. */}}
{{- define "cf-cardano-x402-facilitator.databaseSecretName" -}}
{{- if .Values.database.secretName -}}
{{- .Values.database.secretName -}}
{{- else if .Values.postgres.enabled -}}
{{- printf "%s-owner-user.%s.credentials.postgresql.acid.zalan.do" (required "database.name is required" .Values.database.name) (include "cf-cardano-x402-facilitator.postgresClusterName" .) -}}
{{- else -}}
{{- fail "database.secretName is required when postgres.enabled=false" -}}
{{- end -}}
{{- end }}
