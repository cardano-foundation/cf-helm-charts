{{- define "gateway.fullname" -}}
{{- if .Values.fullnameOverride }}{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else }}{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name }}{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else }}{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}{{- end }}{{- end }}
{{- end }}

{{- define "gateway.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: cardano-ibc
{{- end }}

{{- define "gateway.selectorLabels" -}}
app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "gateway.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{- define "gateway.kupoEndpoint" -}}
{{- if and .Values.global (index .Values.global "kupoEndpoint") }}{{- index .Values.global "kupoEndpoint" -}}
{{- else }}{{- .Values.env.KUPO_ENDPOINT -}}
{{- end }}
{{- end }}

{{- define "gateway.ogmiosEndpoint" -}}
{{- if and .Values.global (index .Values.global "ogmiosEndpoint") }}{{- index .Values.global "ogmiosEndpoint" -}}
{{- else }}{{- .Values.env.OGMIOS_ENDPOINT -}}
{{- end }}
{{- end }}

{{- define "gateway.cardanoNodeHost" -}}
{{- if and .Values.global (index .Values.global "cardanoNodeSocatHost") }}{{- index .Values.global "cardanoNodeSocatHost" -}}
{{- else }}{{- .Values.env.CARDANO_CHAIN_HOST -}}
{{- end }}
{{- end }}

{{- define "gateway.gatewayDbHost" -}}
{{- if and .Values.global (index .Values.global "gatewayDb") (index .Values.global "gatewayDb" "host") }}{{- (index .Values.global "gatewayDb").host -}}
{{- else if and .Values.global (index .Values.global "postgres") }}{{- $pg := index .Values.global "postgres" -}}{{- printf "%s.%s.svc.cluster.local" $pg.clusterName ($pg.namespace | default .Release.Namespace) -}}
{{- else }}{{- .Values.env.GATEWAY_DB_HOST | default "postgres-gateway" -}}
{{- end }}
{{- end }}

{{- define "gateway.gatewayDbName" -}}
{{- if and .Values.global (index .Values.global "gatewayDb") }}{{- (index .Values.global "gatewayDb").name -}}
{{- else }}{{- .Values.env.GATEWAY_DB_NAME | default "gateway_app" -}}
{{- end }}
{{- end }}

{{- define "gateway.historyDbHost" -}}
{{- if and .Values.global (index .Values.global "historyDb") (index .Values.global "historyDb" "host") }}{{- (index .Values.global "historyDb").host -}}
{{- else if and .Values.global (index .Values.global "postgres") }}{{- $pg := index .Values.global "postgres" -}}{{- printf "%s.%s.svc.cluster.local" $pg.clusterName ($pg.namespace | default .Release.Namespace) -}}
{{- else }}{{- .Values.env.HISTORY_DB_HOST | default "yaci-store-postgres" -}}
{{- end }}
{{- end }}

{{- define "gateway.gatewayDbSecretName" -}}
{{- if and .Values.global (index .Values.global "gatewayDb") (index .Values.global "gatewayDb" "secretName") }}{{- (index .Values.global "gatewayDb").secretName -}}
{{- else if and .Values.global (index .Values.global "postgres") }}{{- printf "%s-gateway" (index .Values.global "postgres").clusterName -}}
{{- else }}{{- "gateway-pg-credentials" -}}
{{- end }}
{{- end }}

{{- define "gateway.historyDbSecretName" -}}
{{- if and .Values.global (index .Values.global "historyDb") (index .Values.global "historyDb" "secretName") }}{{- (index .Values.global "historyDb").secretName -}}
{{- else if and .Values.global (index .Values.global "postgres") }}{{- printf "%s-yaci" (index .Values.global "postgres").clusterName -}}
{{- else }}{{- "" -}}
{{- end }}
{{- end }}
