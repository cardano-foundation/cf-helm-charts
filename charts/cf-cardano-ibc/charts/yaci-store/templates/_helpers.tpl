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

{{- define "yaci-store.historyDbHost" -}}
{{- if .Values.historyDb.host }}{{- .Values.historyDb.host -}}
{{- else if and .Values.global (index .Values.global "historyDb") }}{{- (index .Values.global "historyDb").host -}}
{{- else }}{{- "yaci-store-postgres" -}}
{{- end }}
{{- end }}

{{- define "yaci-store.historyDbUsername" -}}
{{- if and .Values.global (index .Values.global "historyDb") (index .Values.global "historyDb" "username") }}{{- (index .Values.global "historyDb").username -}}
{{- else }}{{- "yaci" -}}
{{- end }}
{{- end }}

{{- define "yaci-store.historyDbPassword" -}}
{{- if and .Values.global (index .Values.global "historyDb") (index .Values.global "historyDb" "password") }}{{- (index .Values.global "historyDb").password -}}
{{- else }}{{- "dbpass" -}}
{{- end }}
{{- end }}
