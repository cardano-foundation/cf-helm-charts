{{/*
Expand the name of the chart.
*/}}
{{- define "cf-signoz.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cf-signoz.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cf-signoz.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cf-signoz.labels" -}}
helm.sh/chart: {{ include "cf-signoz.chart" . }}
{{ include "cf-signoz.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cf-signoz.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cf-signoz.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cf-signoz.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cf-signoz.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "isBool" -}}
  {{- if and (eq (typeOf .) "bool") (not (empty .)) -}}
    true
  {{- else -}}
    false
  {{- end -}}
{{- end -}}

{{- define "isInt" -}}
  {{- if and (eq (typeOf .) "int") (not (empty .)) -}}
    true
  {{- else -}}
    false
  {{- end -}}
{{- end -}}
{{- define "isMap" -}}
  {{- if and (eq (typeOf .) "map") (not (empty .)) -}}
    true
  {{- else -}}
    false
  {{- end -}}
{{- end -}}
