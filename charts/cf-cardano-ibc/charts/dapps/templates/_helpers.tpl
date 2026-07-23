{{- define "dapps.fullname" -}}{{- if .Values.fullnameOverride }}{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}{{- else }}{{- printf "%s-dapps" .Release.Name | trunc 63 | trimSuffix "-" -}}{{- end }}{{- end }}
{{- define "dapps.swapFullname" -}}{{- printf "%s-swap-client" .Release.Name | trunc 63 | trimSuffix "-" -}}{{- end }}
{{- define "dapps.explorerFullname" -}}{{- printf "%s-explorer" .Release.Name | trunc 63 | trimSuffix "-" -}}{{- end }}
