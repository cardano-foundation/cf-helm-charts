{{- define "cf-yaci-store.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "cf-yaci-store.fullname" -}}
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

{{- define "cf-yaci-store.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "cf-yaci-store.labels" -}}
helm.sh/chart: {{ include "cf-yaci-store.chart" . }}
{{ include "cf-yaci-store.selectorLabels" . }}
app.kubernetes.io/part-of: cardano-ibc
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "cf-yaci-store.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cf-yaci-store.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: yaci-store
{{- end }}

{{- define "cf-yaci-store.image" -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag }}
{{- end }}

{{/*
Resolve the cardano-node n2n host. The global endpoint is used when no
chart-local host is configured.
*/}}
{{- define "cf-yaci-store.cardanoNodeHost" -}}
{{- if .Values.cardanoNode.host -}}
{{- .Values.cardanoNode.host -}}
{{- else if and .Values.global (index .Values.global "cardanoNodeSocatHost") -}}
{{- index .Values.global "cardanoNodeSocatHost" -}}
{{- else -}}
{{- printf "%s-cf-cardano-node" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "cf-yaci-store.cardanoNodeNetworkMagic" -}}
{{- if and .Values.cardanoNode (hasKey .Values.cardanoNode "networkMagic") -}}
{{- .Values.cardanoNode.networkMagic -}}
{{- else if and .Values.global (hasKey .Values.global "protocolMagic") -}}
{{- .Values.global.protocolMagic -}}
{{- else -}}
{{- 1 -}}
{{- end -}}
{{- end }}

{{- define "cf-yaci-store.yaciDbHost" -}}
{{- if .Values.yaciDb.host -}}
{{- .Values.yaciDb.host -}}
{{- else if and .Values.global (index .Values.global "yaciDb") (index .Values.global.yaciDb "host") -}}
{{- .Values.global.yaciDb.host -}}
{{- else if and .Values.global (index .Values.global "postgres") (index .Values.global.postgres "clusterName") -}}
{{- printf "%s.%s.svc.cluster.local" .Values.global.postgres.clusterName (.Values.global.postgres.namespace | default .Release.Namespace) -}}
{{- else -}}
{{- "yaci-store-postgres" -}}
{{- end -}}
{{- end }}

{{- define "cf-yaci-store.yaciDbName" -}}
{{- if and .Values.global (index .Values.global "yaciDb") (index .Values.global.yaciDb "name") -}}
{{- .Values.global.yaciDb.name -}}
{{- else -}}
{{- .Values.yaciDb.name | default "yaci" -}}
{{- end -}}
{{- end }}

{{- define "cf-yaci-store.yaciDbSecretName" -}}
{{- if and .Values.global (index .Values.global "yaciDb") (index .Values.global.yaciDb "secretName") -}}
{{- .Values.global.yaciDb.secretName -}}
{{- else if and .Values.global (index .Values.global "postgres") (index .Values.global.postgres "clusterName") -}}
{{- printf "%s-owner-user.%s.credentials.postgresql.acid.zalan.do" (include "cf-yaci-store.yaciDbName" .) .Values.global.postgres.clusterName -}}
{{- else -}}
{{- .Values.yaciDb.secretName | default "yaci-pg-credentials" -}}
{{- end -}}
{{- end }}

{{- define "cf-yaci-store.yaciDbSecretUsernameKey" -}}
{{- if and .Values.global (index .Values.global "yaciDb") (index .Values.global.yaciDb "secretUsernameKey") -}}
{{- .Values.global.yaciDb.secretUsernameKey -}}
{{- else -}}
{{- .Values.yaciDb.secretUsernameKey | default "username" -}}
{{- end -}}
{{- end }}

{{- define "cf-yaci-store.yaciDbSecretPasswordKey" -}}
{{- if and .Values.global (index .Values.global "yaciDb") (index .Values.global.yaciDb "secretPasswordKey") -}}
{{- .Values.global.yaciDb.secretPasswordKey -}}
{{- else -}}
{{- .Values.yaciDb.secretPasswordKey | default "password" -}}
{{- end -}}
{{- end }}
