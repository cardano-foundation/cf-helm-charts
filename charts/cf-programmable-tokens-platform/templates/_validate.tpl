{{/*
Render-time guards. Helm silently ignores unknown or misspelled keys, so every key that the
POC chart used and this chart renamed is refused by name, as are the inputs whose absence
would otherwise boot the backend on a committed default.
*/}}
{{- define "cfpt.validate" -}}
{{- $v := .Values -}}

{{- if not (has (toString $v.network) (list "preview" "preprod" "mainnet")) }}
{{- fail (printf "network must be one of preview, preprod, mainnet (got %q)." (toString $v.network)) }}
{{- end }}

{{/* Keys from programmable-tokens-poc that moved. */}}
{{- if hasKey $v "replicas" }}
{{- fail "`replicas` is not a value of this chart. The indexer is a singleton by design (it can sign on-chain updates); use ui.replicas for the frontend." }}
{{- end }}
{{- if hasKey $v "ingress" }}
{{- fail "`ingress:` moved: hostnames are hosts.ui / hosts.indexer, and the routing kind is exposure.type (ingress | httproute | none)." }}
{{- end }}
{{- if and (hasKey $v "blockfrost") (hasKey $v.blockfrost "key") }}
{{- fail "blockfrost.key (plaintext) is not supported. Put the project id in a Secret and set blockfrost.existingSecret.name / .key." }}
{{- end }}
{{- if hasKey $v.indexer "replicas" }}
{{- fail "indexer.replicas is not supported: the indexer runs exactly one pod." }}
{{- end }}
{{- if hasKey $v "secrets" }}
{{- fail "values set `secrets:` - this chart has no such key. Secrets are blockfrost.existingSecret, keri.secret and postgres.secret." }}
{{- end }}

{{- if not (has $v.exposure.type (list "ingress" "httproute" "none")) }}
{{- fail (printf "exposure.type must be ingress, httproute or none (got %q)." $v.exposure.type) }}
{{- end }}
{{- if and (eq $v.exposure.type "httproute") (not $v.exposure.httpRoute.parentRefs) (or $v.hosts.ui $v.hosts.indexer) }}
{{- fail "exposure.type is httproute but exposure.httpRoute.parentRefs is empty: name the Gateway (and listener) the routes attach to." }}
{{- end }}

{{- if and $v.ui.enabled (not $v.ui.image.digest) (not $v.ui.image.tag) }}
{{- fail "ui.image.tag (or ui.image.digest) is required. The chart appends -<network> to the tag." }}
{{- end }}

{{- if $v.indexer.enabled }}
{{- if and (not $v.indexer.image.digest) (not $v.indexer.image.tag) }}
{{- fail "indexer.image.tag (or indexer.image.digest) is required." }}
{{- end }}
{{- if not $v.blockfrost.existingSecret.name }}
{{- fail "blockfrost.existingSecret.name is required: the backend Blockfrost project id is read only from a Secret." }}
{{- end }}
{{- if and $v.indexer.rwaToken.enabled (not (include "cfpt.rwaAudience" .)) }}
{{- fail "indexer.rwaToken.enabled is true but neither indexer.rwaToken.creationAudience nor hosts.indexer is set, so no audience can be resolved. RwaTokenCreationRequestVerifier validates it in its constructor and an empty value stops the backend from starting." }}
{{- end }}
{{- if $v.keri.enabled }}
{{- if not $v.keri.secret.name }}
{{- fail (printf "keri.enabled is true but keri.secret.name is empty, so the pod would set neither KERI_BRAN nor KERI_SIGNING_MNEMONIC.\n\nKERI_BRAN: the backend falls back to a passcode committed in the platform's PUBLIC application.yaml. KERI would run on a published passcode, silently.\n\nKERI_SIGNING_MNEMONIC: blank means root sync publishing is DISABLED and getAdminAddress/getAdminPkh throw. Images built before that change carry a committed 24-word mnemonic and would sign with it instead.\n\nCreate a Secret in namespace %s with keys %s and %s, then set keri.secret.name. To run without KERI, set keri.enabled: false." .Release.Namespace $v.keri.secret.branKey $v.keri.secret.signingMnemonicKey) }}
{{- end }}
{{- if or (not $v.keri.secret.branKey) (not $v.keri.secret.signingMnemonicKey) }}
{{- fail "keri.secret.branKey and keri.secret.signingMnemonicKey must both be named." }}
{{- end }}
{{- if or (not $v.keri.url) (not $v.keri.bootUrl) }}
{{- fail "keri.enabled is true but keri.url or keri.bootUrl is empty; the image would fall back to http://localhost:3901 / :3903." }}
{{- end }}
{{- end }}
{{- if and $v.indexer.kycExtended.enabled (not $v.keri.enabled) }}
{{- fail "indexer.kycExtended.enabled needs keri.enabled (it signs root updates with keri.signing-mnemonic)." }}
{{- end }}
{{- if and (not $v.postgres.create) (or (not $v.postgres.host) (not $v.postgres.secret.name)) }}
{{- fail "postgres.create is false: set postgres.host and postgres.secret.name for the external database." }}
{{- end }}
{{- end }}
{{- end }}
