{{/* hermes helpers (was the hermes subchart at charts/hermes/).
     Value shapes are unchanged from the subchart. hermes.fullname is the ONLY
     helper that changed on flattening: the subchart derived the component name
     from .Chart.Name (="hermes"); in the parent chart that would be
     "cf-cardano-ibc". Pin the component suffix explicitly so the rendered name
     is unchanged. */}}
{{- define "hermes.fullname" -}}
{{- if .Values.hermes.fullnameOverride }}{{- .Values.hermes.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else }}{{- $name := default "hermes" .Values.hermes.nameOverride -}}
{{- if contains $name .Release.Name }}{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else }}{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}{{- end }}{{- end }}
{{- end }}

{{- define "hermes.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ default "hermes" .Values.hermes.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: cardano-ibc
{{- end }}

{{- define "hermes.selectorLabels" -}}
app.kubernetes.io/name: {{ default "hermes" .Values.hermes.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: hermes
{{- end }}

{{- define "hermes.image" -}}
{{- $tag := .Values.hermes.image.tag | default .Chart.AppVersion -}}
{{- printf "%s:%s" .Values.hermes.image.repository $tag }}
{{- end }}

{{- define "hermes.gatewayUrl" -}}
{{- printf "http://%s-gateway:5001" .Release.Name -}}
{{- end }}

{{- define "hermes.injectiveRpcAddr" -}}
{{- if and .Values.global (index .Values.global "injective") }}{{- (index .Values.global "injective").rpcAddr -}}
{{- else }}{{- .Values.hermes.config.injective.rpcAddr -}}
{{- end }}
{{- end }}

{{- define "hermes.injectiveGrpcAddr" -}}
{{- if and .Values.global (index .Values.global "injective") }}{{- (index .Values.global "injective").grpcAddr -}}
{{- else }}{{- .Values.hermes.config.injective.grpcAddr -}}
{{- end }}
{{- end }}

{{- define "hermes.injectiveEventSourceUrl" -}}
{{- if and .Values.global (index .Values.global "injective") }}{{- (index .Values.global "injective").eventSourceUrl -}}
{{- else }}{{- .Values.hermes.config.injective.eventSourceUrl -}}
{{- end }}
{{- end }}

{{- define "hermes.injectiveChainId" -}}
{{- if and .Values.global (index .Values.global "injective") }}{{- (index .Values.global "injective").chainId -}}
{{- else }}{{- .Values.hermes.config.injective.chainId -}}
{{- end }}
{{- end }}
