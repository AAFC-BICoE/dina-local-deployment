{{- define "javaOpsMemory" -}}
{{- $memoryLimitMB := .memoryLimitMB -}}
{{- $xmxValueMB := mulf $memoryLimitMB 0.8 }}
{{ printf "%.0f" $xmxValueMB }}
{{- end -}}

{{/*
Construct the full image name.
Usage: {{ include "dina-helm.build-image-name" .Values.agentapi }}
*/}}
{{- define "dina-helm.build-image-name" -}}
{{- $registry := .registry -}}
{{- $repository := .repository -}}
{{- $tag := .tag | toString -}}

{{- /* Validation: Repository and Tag are required */ -}}
{{- if not $repository -}}
  {{- fail "An image repository is required" -}}
{{- end -}}
{{- if not $tag -}}
  {{- fail "An image tag is required" -}}
{{- end -}}

{{- /* Logic: If registry exists, add it with a trailing slash */ -}}
{{- if $registry -}}
  {{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- else -}}
  {{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end -}}

{{/* Common check-db init container */}}
{{- define "dina-helm.initContainer.checkDb" -}}
- name: check-db
  {{- with .Values.initdb.image }}
  image: {{ include "dina-helm.build-image-name" . | quote }}
  imagePullPolicy: {{ .pullPolicy | default "IfNotPresent" | quote }}
  {{- end }}
  command:
    - sh
    - -c
    - until pg_isready -h {{ tpl .Values.services.initdb.environment.POSTGRES_HOST . }}; do echo waiting for database; sleep 10; done;
  resources:
    {{- toYaml .Values.resources.initcontainers | nindent 4 }}
{{- end -}}

{{/*
  Common init-db container
  Usage: {{ include "dina-helm.initContainer.initDb" (dict "root" . "serviceKey" "agentapi" "environmentKey" "agent_api" "shortName" "agent") }}
*/}}
{{- define "dina-helm.initContainer.initDb" -}}
{{- $root := .root -}}
{{- $serviceKey := .serviceKey -}}
{{- $environmentKey := .environmentKey -}}
{{- $shortName := .shortName -}}
{{- $config := index $root.Values.services.initdb.config $serviceKey -}}
{{- $serviceConfig := index $root.Values.services $serviceKey -}}
- name: init-db
  {{- with $root.Values.initdb.image }}
  image: {{ include "dina-helm.build-image-name" . | quote }}
  imagePullPolicy: {{ .pullPolicy | default "IfNotPresent" | quote }}
  {{- end }}
  env:
  - name: POSTGRES_DB
    value: {{ tpl $root.Values.services.initdb.environment.POSTGRES_DB $root }}
  - name: POSTGRES_HOST
    value: {{ tpl $root.Values.services.initdb.environment.POSTGRES_HOST $root }}
  - name: POSTGRES_USER
    value: {{ tpl $root.Values.services.initdb.environment.POSTGRES_USER $root }}
  - name: POSTGRES_PASSWORD
    {{- if not $root.Values.global.environment.config.dina_db.db_password }}
    valueFrom:
      secretKeyRef:
        name: dina-db-secret
        key: password
    {{- else }}
    value: {{ tpl $root.Values.services.initdb.environment.POSTGRES_PASSWORD $root }}
    {{- end }}
  - name: DINA_DB
    value: {{ $config.DINA_DB }}
  - name: MIGRATION_USER_{{ $shortName }}
    value: {{ $serviceConfig.environment.spring.liquibase.username }}
  - name: MIGRATION_USER_PW_{{ $shortName }}
    {{- /* We use the shortName to dynamically find the secret name pattern */}}
    {{- $secretBase := (replace "-" "" $serviceKey) -}}
    {{- if $serviceConfig.environment.spring.liquibase.password }}
    value: {{ $serviceConfig.environment.spring.liquibase.password }}
    {{- else }}
    valueFrom:
      secretKeyRef:
        name: {{ $secretBase }}-liquibase-secret
        key: password
    {{- end }}
  - name: WEB_USER_{{ $shortName }}
    value: {{ $serviceConfig.environment.spring.datasource.username }}
  - name: WEB_USER_PW_{{ $shortName }}
    {{- if $serviceConfig.environment.spring.datasource.password }}
    value: {{ $serviceConfig.environment.spring.datasource.password }}
    {{- else }}
    valueFrom:
      secretKeyRef:
        name: {{ $secretBase }}-datasource-secret
        key: password
    {{- end }}
  {{- /* Dynamically construct the extension key name, e.g., PG_EXTENSION_seqdb */ -}}
  {{- $pgExtKey := printf "PG_EXTENSION_%s" $shortName -}}
  {{- /* Look up that dynamic key in the $config map */ -}}
  {{- $pgExtValue := index $config $pgExtKey -}}
  {{- if $pgExtValue }}
  - name: {{ $pgExtKey }}
    value: {{ $pgExtValue }}
  {{- end }}
  resources:
    {{- toYaml $root.Values.resources.initcontainers | nindent 4 }}
{{- end -}}
