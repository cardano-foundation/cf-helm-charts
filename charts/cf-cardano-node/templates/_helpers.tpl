{{/* Expand the chart name. */}}
{{- define "cf-cardano-node.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Fully qualified app name. */}}
{{- define "cf-cardano-node.fullname" -}}
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

{{/* Headless service name for the StatefulSet. */}}
{{- define "cf-cardano-node.headlessName" -}}
{{- printf "%s-headless" (include "cf-cardano-node.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Chart name + version label. */}}
{{- define "cf-cardano-node.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels. */}}
{{- define "cf-cardano-node.labels" -}}
helm.sh/chart: {{ include "cf-cardano-node.chart" . }}
{{ include "cf-cardano-node.selectorLabels" . }}
app.kubernetes.io/part-of: cardano-ibc
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels. */}}
{{- define "cf-cardano-node.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cf-cardano-node.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: cardano-node
{{- end }}

{{/* Image reference. */}}
{{- define "cf-cardano-node.image" -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag }}
{{- end }}

{{/* socat image reference. */}}
{{- define "cf-cardano-node.socatImage" -}}
{{- printf "%s:%s" .Values.socat.image.repository .Values.socat.image.tag }}
{{- end }}

{{/* Resolve the config volume: either an existing ConfigMap or the inline one. */}}
{{- define "cf-cardano-node.configConfigMapName" -}}
{{- if .Values.existingConfigMap }}
{{- .Values.existingConfigMap }}
{{- else }}
{{- printf "%s-config" (include "cf-cardano-node.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
