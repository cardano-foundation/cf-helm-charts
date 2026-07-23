{{- define "cf-ogmios.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "cf-ogmios.fullname" -}}
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

{{- define "cf-ogmios.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "cf-ogmios.labels" -}}
helm.sh/chart: {{ include "cf-ogmios.chart" . }}
{{ include "cf-ogmios.selectorLabels" . }}
app.kubernetes.io/part-of: cardano-ibc
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "cf-ogmios.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cf-ogmios.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: ogmios
{{- end }}

{{- define "cf-ogmios.image" -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag }}
{{- end }}

{{- define "cf-ogmios.socatImage" -}}
{{- printf "%s:%s" .Values.socat.image.repository .Values.socat.image.tag }}
{{- end }}

{{/*
Resolve the cardano-node socat host. When deployed as a subchart of
cf-cardano-ibc, allow the parent to override via global.cardanoNode.socatHost.
*/}}
{{- define "cf-ogmios.cardanoNodeSocatHost" -}}
{{- if .Values.global }}
  {{- if (index .Values.global "cardanoNodeSocatHost") }}
    {{- index .Values.global "cardanoNodeSocatHost" }}
  {{- else }}
    {{- .Values.cardanoNode.socatHost }}
  {{- end }}
{{- else }}
{{- .Values.cardanoNode.socatHost }}
{{- end }}
{{- end }}
