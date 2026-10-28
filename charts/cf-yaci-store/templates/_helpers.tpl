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
{{/* The Zalando Postgres cluster this chart talks to.
     - postgres.clusterName wins for standalone releases.
     - global.postgres.clusterName is inherited from a parent chart (cf-cardano-ibc)
       that owns one shared cluster; its presence also suppresses this chart's
       own postgresql CRD (see postgres.yaml).
     - otherwise a standalone cluster is named <release name>-pg.
*/}}
{{- define "cf-yaci-store.globalPostgresClusterName" -}}
{{- if and .Values.global (index .Values.global "postgres") (index .Values.global.postgres "clusterName") -}}{{- .Values.global.postgres.clusterName -}}{{- end -}}
{{- end }}

{{- define "cf-yaci-store.postgresClusterName" -}}
{{- if .Values.postgres.clusterName -}}{{- .Values.postgres.clusterName -}}
{{- else if (include "cf-yaci-store.globalPostgresClusterName" .) -}}{{- include "cf-yaci-store.globalPostgresClusterName" . -}}
{{- else if .Values.postgres.enabled -}}{{- printf "%s-pg" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "cf-yaci-store.postgresNamespace" -}}
{{- if .Values.postgres.namespace -}}{{- .Values.postgres.namespace -}}
{{- else if and .Values.global (index .Values.global "postgres") (index .Values.global.postgres "namespace") -}}{{- .Values.global.postgres.namespace -}}
{{- else -}}{{- .Release.Namespace -}}{{- end -}}
{{- end }}

{{- define "cf-yaci-store.postgresSecretNamespace" -}}
{{- if .Values.postgres.secretNamespace -}}{{- .Values.postgres.secretNamespace -}}
{{- else if and .Values.global (index .Values.global "postgres") (index .Values.global.postgres "secretNamespace") -}}{{- .Values.global.postgres.secretNamespace -}}
{{- else -}}{{- .Release.Namespace -}}{{- end -}}
{{- end }}

{{/* Render this chart's own postgresql CRD. A parent that supplies
     global.postgres.clusterName already prepares the yaci database in the
     shared cluster, so the CRD is skipped and only its names are consumed.
*/}}
{{- define "cf-yaci-store.ownPostgresEnabled" -}}
{{- if and .Values.postgres.enabled (not (include "cf-yaci-store.globalPostgresClusterName" .)) -}}true{{- end -}}
{{- end }}

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

{{/* Empty chart-local/global hosts fall back to the operator's master Service
     <cluster>.<namespace>.svc.cluster.local
*/}}
{{- define "cf-yaci-store.yaciDbHost" -}}
{{- if .Values.yaciDb.host -}}
{{- .Values.yaciDb.host -}}
{{- else if and .Values.global (index .Values.global "yaciDb") (index .Values.global.yaciDb "host") -}}
{{- .Values.global.yaciDb.host -}}
{{- else if (include "cf-yaci-store.postgresClusterName" .) -}}
{{- printf "%s.%s.svc.cluster.local" (include "cf-yaci-store.postgresClusterName" .) (include "cf-yaci-store.postgresNamespace" .) -}}
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

{{/* Zalando names the prepared-database owner Secret
     <db>-owner-user.<cluster>.credentials.postgresql.acid.zalan.do
*/}}
{{- define "cf-yaci-store.yaciDbSecretName" -}}
{{- if .Values.yaciDb.secretName -}}
{{- .Values.yaciDb.secretName -}}
{{- else if and .Values.global (index .Values.global "yaciDb") (index .Values.global.yaciDb "secretName") -}}
{{- .Values.global.yaciDb.secretName -}}
{{- else if (include "cf-yaci-store.postgresClusterName" .) -}}
{{- printf "%s-owner-user.%s.credentials.postgresql.acid.zalan.do" (include "cf-yaci-store.yaciDbName" .) (include "cf-yaci-store.postgresClusterName" .) -}}
{{- else -}}
{{- "yaci-pg-credentials" -}}
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
