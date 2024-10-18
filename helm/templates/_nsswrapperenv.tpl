{{- define "nss-wrapper-env" -}}
- name: LD_PRELOAD
  value: libnss_wrapper.so
- name: NSS_WRAPPER_PASSWD
  value: /tmp/passwd
- name: NSS_WRAPPER_GROUP
  value: /tmp/group
{{- end -}}
