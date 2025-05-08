{{- define "javaOpsMemory" -}}
{{- $memoryLimitMB := .memoryLimitMB -}}
{{- $xmxValueMB := mulf $memoryLimitMB 0.8 }}
{{ printf "%.0f" $xmxValueMB }}
{{- end -}}

