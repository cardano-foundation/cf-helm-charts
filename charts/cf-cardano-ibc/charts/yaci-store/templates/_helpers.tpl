{{- define "yaci-store.fullname" -}}
{{- if .Values.fullnameOverride }}{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else }}{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name }}{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else }}{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}{{- end }}{{- end }}
{{- end }}

{{- define "yaci-store.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: yaci-store
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: cardano-ibc
{{- end }}

{{- define "yaci-store.selectorLabels" -}}
app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: yaci-store
{{- end }}

{{- define "yaci-store.image" -}}{{- printf "%s:%s" .Values.image.repository .Values.image.tag }}{{- end }}

{{- define "yaci-store.cardanoNodeHost" -}}
{{- if .Values.cardanoNode.host }}{{- .Values.cardanoNode.host -}}
{{- else if and .Values.global (index .Values.global "cardanoNodeSocatHost") }}{{- index .Values.global "cardanoNodeSocatHost" -}}
{{- else }}{{- printf "%s-cf-cardano-node" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}
{{- end }}

{{- define "yaci-store.yaciDbHost" -}}
{{- if .Values.yaciDb.host }}{{- .Values.yaciDb.host -}}
{{- else if and .Values.global .Values.global.yaciDb .Values.global.yaciDb.host }}{{- (index .Values.global "yaciDb").host -}}
{{- else if and .Values.global (index .Values.global "postgres") }}{{- $pg := index .Values.global "postgres" -}}{{- printf "%s.%s.svc.cluster.local" $pg.clusterName ($pg.namespace | default .Release.Namespace) -}}
{{- else }}{{- "yaci-store-postgres" -}}
{{- end }}
{{- end }}

{{- define "yaci-store.yaciDbName" -}}
{{- if and .Values.global (index .Values.global "yaciDb") (index .Values.global "yaciDb" "name") }}{{- (index .Values.global "yaciDb").name -}}
{{- else }}{{- .Values.yaciDb.name | default "yaci" -}}
{{- end }}
{{- end }}

{{- define "yaci-store.yaciDbSecretName" -}}
{{- if and .Values.global (index .Values.global "yaciDb") (index .Values.global "yaciDb" "secretName") }}{{- (index .Values.global "yaciDb").secretName -}}
{{- else if and .Values.global (index .Values.global "postgres") }}{{- $pg := index .Values.global "postgres" -}}{{- printf "%s-owner-user.%s.credentials.postgresql.acid.zalan.do" (include "yaci-store.yaciDbName" .) $pg.clusterName -}}
{{- else }}{{- "yaci-pg-credentials" -}}
{{- end }}
{{- end }}
