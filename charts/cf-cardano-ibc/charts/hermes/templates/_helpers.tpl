{{- define "hermes.fullname" -}}
{{- if .Values.fullnameOverride }}{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else }}{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name }}{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else }}{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}{{- end }}{{- end }}
{{- end }}

{{- define "hermes.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: cardano-ibc
{{- end }}

{{- define "hermes.selectorLabels" -}}
app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: hermes
{{- end }}

{{- define "hermes.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{- define "hermes.gatewayUrl" -}}
{{- printf "http://%s-gateway:5001" .Release.Name -}}
{{- end }}

{{- define "hermes.injectiveRpcAddr" -}}
{{- if and .Values.global (index .Values.global "injective") }}{{- (index .Values.global "injective").rpcAddr -}}
{{- else }}{{- .Values.config.injective.rpcAddr -}}
{{- end }}
{{- end }}

{{- define "hermes.injectiveGrpcAddr" -}}
{{- if and .Values.global (index .Values.global "injective") }}{{- (index .Values.global "injective").grpcAddr -}}
{{- else }}{{- .Values.config.injective.grpcAddr -}}
{{- end }}
{{- end }}

{{- define "hermes.injectiveEventSourceUrl" -}}
{{- if and .Values.global (index .Values.global "injective") }}{{- (index .Values.global "injective").eventSourceUrl -}}
{{- else }}{{- .Values.config.injective.eventSourceUrl -}}
{{- end }}
{{- end }}

{{- define "hermes.injectiveChainId" -}}
{{- if and .Values.global (index .Values.global "injective") }}{{- (index .Values.global "injective").chainId -}}
{{- else }}{{- .Values.config.injective.chainId -}}
{{- end }}
{{- end }}
