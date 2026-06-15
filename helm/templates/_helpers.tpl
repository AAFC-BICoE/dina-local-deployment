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
