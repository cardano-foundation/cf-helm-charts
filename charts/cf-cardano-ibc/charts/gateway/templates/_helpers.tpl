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

{{- define "gateway.kupoHost" -}}
{{- printf "%s-cf-kupo" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "gateway.ogmiosHost" -}}
{{- printf "%s-cf-ogmios" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "gateway.yaciStoreHost" -}}
{{- printf "%s-yaci-store" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "gateway.kupoEndpoint" -}}
{{- if and .Values.global (index .Values.global "kupoEndpoint") -}}{{- index .Values.global "kupoEndpoint" -}}
{{- else if .Values.env.KUPO_ENDPOINT -}}{{- .Values.env.KUPO_ENDPOINT -}}
{{- else -}}{{- printf "http://%s:1442" (include "gateway.kupoHost" .) -}}
{{- end -}}
{{- end }}

{{- define "gateway.ogmiosEndpoint" -}}
{{- if and .Values.global (index .Values.global "ogmiosEndpoint") -}}{{- index .Values.global "ogmiosEndpoint" -}}
{{- else if .Values.env.OGMIOS_ENDPOINT -}}{{- .Values.env.OGMIOS_ENDPOINT -}}
{{- else -}}{{- printf "http://%s:1337" (include "gateway.ogmiosHost" .) -}}
{{- end -}}
{{- end }}

{{- define "gateway.yaciStoreEndpoint" -}}
{{- if and .Values.global (index .Values.global "yaciStoreEndpoint") -}}{{- index .Values.global "yaciStoreEndpoint" -}}
{{- else if .Values.env.YACI_STORE_ENDPOINT -}}{{- .Values.env.YACI_STORE_ENDPOINT -}}
{{- else -}}{{- printf "http://%s:8080" (include "gateway.yaciStoreHost" .) -}}
{{- end -}}
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
{{- if and .Values.global (index .Values.global "gatewayDb") (index .Values.global "gatewayDb" "name") }}{{- (index .Values.global "gatewayDb").name -}}
{{- else }}{{- .Values.env.GATEWAY_DB_NAME | default "gateway" -}}
{{- end }}
{{- end }}

{{- define "gateway.yaciDbName" -}}
{{- if and .Values.global (index .Values.global "yaciDb") (index .Values.global "yaciDb" "name") }}{{- (index .Values.global "yaciDb").name -}}
{{- else }}{{- .Values.env.HISTORY_DB_NAME | default "yaci" -}}
{{- end }}
{{- end }}

{{- define "gateway.yaciDbHost" -}}
{{- if and .Values.global (index .Values.global "yaciDb") (index .Values.global "yaciDb" "host") }}{{- (index .Values.global "yaciDb").host -}}
{{- else if and .Values.global (index .Values.global "postgres") }}{{- $pg := index .Values.global "postgres" -}}{{- printf "%s.%s.svc.cluster.local" $pg.clusterName ($pg.namespace | default .Release.Namespace) -}}
{{- else }}{{- .Values.env.HISTORY_DB_HOST | default "yaci-store-postgres" -}}
{{- end }}
{{- end }}

{{- define "gateway.gatewayDbSecretName" -}}
{{- if and .Values.global (index .Values.global "gatewayDb") (index .Values.global "gatewayDb" "secretName") }}{{- (index .Values.global "gatewayDb").secretName -}}
{{- else if and .Values.global (index .Values.global "postgres") }}{{- $pg := index .Values.global "postgres" -}}{{- printf "%s-owner-user.%s.credentials.postgresql.acid.zalan.do" (include "gateway.gatewayDbName" .) $pg.clusterName -}}
{{- else }}{{- "gateway-pg-credentials" -}}
{{- end }}
{{- end }}

{{- define "gateway.yaciDbSecretName" -}}
{{- if and .Values.global (index .Values.global "yaciDb") (index .Values.global "yaciDb" "secretName") }}{{- (index .Values.global "yaciDb").secretName -}}
{{- else if and .Values.global (index .Values.global "postgres") }}{{- $pg := index .Values.global "postgres" -}}{{- printf "%s-owner-user.%s.credentials.postgresql.acid.zalan.do" (include "gateway.yaciDbName" .) $pg.clusterName -}}
{{- else }}{{- "yaci-pg-credentials" -}}
{{- end }}
{{- end }}

{{- define "gateway.gatewayDbSecretUsernameKey" -}}
{{- if and .Values.global (index .Values.global "gatewayDb") (index .Values.global "gatewayDb" "secretUsernameKey") }}{{- (index .Values.global "gatewayDb").secretUsernameKey -}}
{{- else }}{{- "username" -}}
{{- end }}
{{- end }}

{{- define "gateway.gatewayDbSecretPasswordKey" -}}
{{- if and .Values.global (index .Values.global "gatewayDb") (index .Values.global "gatewayDb" "secretPasswordKey") }}{{- (index .Values.global "gatewayDb").secretPasswordKey -}}
{{- else }}{{- "password" -}}
{{- end }}
{{- end }}

{{- define "gateway.yaciDbSecretUsernameKey" -}}
{{- if and .Values.global (index .Values.global "yaciDb") (index .Values.global "yaciDb" "secretUsernameKey") }}{{- (index .Values.global "yaciDb").secretUsernameKey -}}
{{- else }}{{- "username" -}}
{{- end }}
{{- end }}

{{- define "gateway.yaciDbSecretPasswordKey" -}}
{{- if and .Values.global (index .Values.global "yaciDb") (index .Values.global "yaciDb" "secretPasswordKey") }}{{- (index .Values.global "yaciDb").secretPasswordKey -}}
{{- else }}{{- "password" -}}
{{- end }}
{{- end }}
