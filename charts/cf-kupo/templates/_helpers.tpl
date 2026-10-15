{{- define "cf-kupo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "cf-kupo.fullname" -}}
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

{{- define "cf-kupo.headlessName" -}}
{{- printf "%s-headless" (include "cf-kupo.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "cf-kupo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "cf-kupo.labels" -}}
helm.sh/chart: {{ include "cf-kupo.chart" . }}
{{ include "cf-kupo.selectorLabels" . }}
app.kubernetes.io/part-of: cardano-ibc
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "cf-kupo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cf-kupo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: kupo
{{- end }}

{{- define "cf-kupo.image" -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag }}
{{- end }}

{{- define "cf-kupo.socatImage" -}}
{{- printf "%s:%s" .Values.socat.image.repository .Values.socat.image.tag }}
{{- end }}

{{/*
Resolve the Ogmios host. Defaults to the cf-ogmios Service created in the same
Helm release; override via global.ogmiosHost or ogmios.host when connecting to
an externally managed Ogmios instance.
*/}}
{{- define "cf-kupo.ogmiosHost" -}}
{{- if and .Values.global (index .Values.global "ogmiosHost") -}}
{{- index .Values.global "ogmiosHost" -}}
{{- else if .Values.ogmios.host -}}
{{- .Values.ogmios.host -}}
{{- else -}}
{{- printf "%s-cf-ogmios" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{/* cardano-node socat host, overridable via parent global. */}}
{{- define "cf-kupo.cardanoNodeSocatHost" -}}
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