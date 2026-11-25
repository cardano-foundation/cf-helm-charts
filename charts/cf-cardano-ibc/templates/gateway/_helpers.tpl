{{/* gateway helpers (was the gateway subchart at charts/gateway/).
     Value shapes are unchanged from the subchart — see values.yaml. */}}
{{- define "gateway.fullname" -}}
{{- if .Values.gateway.fullnameOverride }}{{- .Values.gateway.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else }}{{- $name := default "gateway" .Values.gateway.nameOverride -}}
{{- if contains $name .Release.Name }}{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else }}{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}{{- end }}{{- end }}
{{- end }}

{{- define "gateway.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ default "gateway" .Values.gateway.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: cardano-ibc
{{- end }}

{{- define "gateway.selectorLabels" -}}
app.kubernetes.io/name: {{ default "gateway" .Values.gateway.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "gateway.image" -}}
{{- include "cf-cardano-ibc.image" .Values.gateway.image -}}
{{- end }}

{{- define "gateway.readinessHttpTimeoutSeconds" -}}
{{- $ms := .Values.gateway.env.GATEWAY_READINESS_PROOF_TIMEOUT_MS | toString -}}
{{- if or (not (regexMatch "^[1-9][0-9]{0,5}$" $ms)) (gt (atoi $ms) 300000) -}}
{{- fail "gateway.env.GATEWAY_READINESS_PROOF_TIMEOUT_MS must be an integer between 1 and 300000" -}}
{{- end -}}
{{- add (div (add (atoi $ms) 999) 1000) 15 -}}
{{- end }}

{{- define "gateway.deploymentConfigMountedPath" -}}
{{- printf "%s/%s" .Values.gateway.deploymentConfig.mountPath .Values.gateway.deploymentConfig.fileName -}}
{{- end }}

{{- define "gateway.deploymentConfigPath" -}}
{{- .Values.gateway.deploymentConfig.path | default (include "gateway.deploymentConfigMountedPath" .) -}}
{{- end }}

{{- define "gateway.deploymentConfigKey" -}}
{{- .Values.gateway.deploymentConfig.configMap.key | default .Values.gateway.deploymentConfig.fileName -}}
{{- end }}

{{- define "gateway.deploymentConfigConfigMapName" -}}
{{- if .Values.gateway.deploymentConfig.configMap.name -}}{{- .Values.gateway.deploymentConfig.configMap.name -}}
{{- else -}}{{- printf "%s-deployment-config" (include "gateway.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "gateway.deploymentConfigVolumeEnabled" -}}
{{- if not .Values.gateway.deploymentConfig.path -}}true{{- end -}}
{{- end }}

{{- define "gateway.deploymentConfigInlineConfigMapEnabled" -}}
{{- if and (include "gateway.deploymentConfigVolumeEnabled" .) .Values.gateway.deploymentConfig.configMap.content -}}true{{- end -}}
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
{{- else if .Values.gateway.env.KUPO_ENDPOINT -}}{{- .Values.gateway.env.KUPO_ENDPOINT -}}
{{- else -}}{{- printf "http://%s:1442" (include "gateway.kupoHost" .) -}}
{{- end -}}
{{- end }}

{{- define "gateway.ogmiosEndpoint" -}}
{{- if and .Values.global (index .Values.global "ogmiosEndpoint") -}}{{- index .Values.global "ogmiosEndpoint" -}}
{{- else if .Values.gateway.env.OGMIOS_ENDPOINT -}}{{- .Values.gateway.env.OGMIOS_ENDPOINT -}}
{{- else -}}{{- printf "http://%s:1337" (include "gateway.ogmiosHost" .) -}}
{{- end -}}
{{- end }}

{{- define "gateway.yaciStoreEndpoint" -}}
{{- if and .Values.global (index .Values.global "yaciStoreEndpoint") -}}{{- index .Values.global "yaciStoreEndpoint" -}}
{{- else if .Values.gateway.env.YACI_STORE_ENDPOINT -}}{{- .Values.gateway.env.YACI_STORE_ENDPOINT -}}
{{- else -}}{{- printf "http://%s:8080" (include "gateway.yaciStoreHost" .) -}}
{{- end -}}
{{- end }}

{{- define "gateway.gatewayDbHost" -}}
{{- if and .Values.global (index .Values.global "gatewayDb") (index .Values.global "gatewayDb" "host") }}{{- (index .Values.global "gatewayDb").host -}}
{{- else if and .Values.global (index .Values.global "postgres") }}{{- $pg := index .Values.global "postgres" -}}{{- printf "%s.%s.svc.cluster.local" $pg.clusterName ($pg.namespace | default .Release.Namespace) -}}
{{- else }}{{- .Values.gateway.env.GATEWAY_DB_HOST | default "postgres-gateway" -}}
{{- end }}
{{- end }}

{{- define "gateway.gatewayDbName" -}}
{{- if and .Values.global (index .Values.global "gatewayDb") (index .Values.global "gatewayDb" "name") }}{{- (index .Values.global "gatewayDb").name -}}
{{- else }}{{- .Values.gateway.env.GATEWAY_DB_NAME | default "gateway" -}}
{{- end }}
{{- end }}

{{- define "gateway.gatewayDbSecretName" -}}
{{- if and .Values.global (index .Values.global "gatewayDb") (index .Values.global "gatewayDb" "secretName") }}{{- (index .Values.global "gatewayDb").secretName -}}
{{- else if and .Values.global (index .Values.global "postgres") }}{{- $pg := index .Values.global "postgres" -}}{{- printf "%s-owner-user.%s.credentials.postgresql.acid.zalan.do" (include "gateway.gatewayDbName" .) $pg.clusterName -}}
{{- else }}{{- "gateway-pg-credentials" -}}
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
