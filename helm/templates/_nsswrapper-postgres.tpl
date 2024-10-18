{{- define "nss-wrapper-init-postgres" -}}
initContainers:
  - name: nss-wrapper-init
    imagePullPolicy: IfNotPresent
    command:
      - bash
      - -cx
      - |
        echo "Starting nss-wrapper-init"
        grep -v postgres /etc/passwd | sed "s/$(id -u)/postgres/" > /tmp/passwd
        echo "Updated passwd file:"
        cat /tmp/passwd
        cp /etc/group /tmp/group
        echo "Updated group file:"
        cat /tmp/group
        echo "postgres:x:$(id -u):postgres" >> /tmp/group
        export LD_PRELOAD=libnss_wrapper.so
        export NSS_WRAPPER_PASSWD=/tmp/passwd
        export NSS_WRAPPER_GROUP=/tmp/group
        echo "Environment variables set"
    resources:
      requests:
        memory: {{ .Values.resources.initcontainers.requests.memory }}
        cpu: {{ .Values.resources.initcontainers.requests.cpu }}
      limits:
        memory: {{ .Values.resources.initcontainers.limits.memory }}
        cpu: {{ .Values.resources.initcontainers.limits.cpu }}
    terminationMessagePath: /dev/termination-log
    volumeMounts:
      - mountPath: /tmp
        name: tmp
{{- end -}}
