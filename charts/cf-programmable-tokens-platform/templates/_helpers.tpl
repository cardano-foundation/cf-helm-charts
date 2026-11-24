{{- define "cfpt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "cfpt.fullname" -}}
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

{{- define "cfpt.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "cfpt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: programmable-tokens
cardano.org/network: {{ .Values.network | quote }}
{{- end }}

{{- define "cfpt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cfpt.name" .ctx }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{- define "cfpt.ui.fullname" -}}
{{- printf "%s-ui" (include "cfpt.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "cfpt.indexer.fullname" -}}
{{- printf "%s-indexer" (include "cfpt.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "cfpt.postgres.cluster" -}}
{{- printf "%s-%s" .Values.postgres.teamId (default (include "cfpt.fullname" .) .Values.postgres.clusterName) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "cfpt.postgres.host" -}}
{{- if .Values.postgres.host }}{{ .Values.postgres.host }}{{ else }}{{ include "cfpt.postgres.cluster" . }}{{ end }}
{{- end }}

{{- define "cfpt.postgres.secretName" -}}
{{- if .Values.postgres.secret.name }}{{ .Values.postgres.secret.name }}{{ else }}{{ printf "%s.%s.credentials.postgresql.acid.zalan.do" .Values.postgres.user (include "cfpt.postgres.cluster" .) }}{{ end }}
{{- end }}

{{- define "cfpt.rwaAudience" -}}
{{- if .Values.indexer.rwaToken.creationAudience }}{{ .Values.indexer.rwaToken.creationAudience }}{{ else if .Values.hosts.indexer }}{{ printf "https://%s/api/v1" .Values.hosts.indexer }}{{ end }}
{{- end }}

{{- define "cfpt.image" -}}
{{- if .image.digest }}{{ printf "%s@%s" .image.repository .image.digest }}{{ else }}{{ printf "%s:%s%s" .image.repository .image.tag (default "" .suffix) }}{{ end }}
{{- end }}
