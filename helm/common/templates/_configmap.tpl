# helm/common/templates/_configmap.tpl

{{- define "dhondoo.configmap" -}}

{{- if .Values.configMap.enabled }}

apiVersion: v1
kind: ConfigMap

metadata:
  name: {{ include "dhondoo.fullname" . }}

  labels:
    {{- include "dhondoo.labels" . | nindent 4 }}

data:
  {{- with .Values.configMap.data }}
  {{- toYaml . | nindent 2 }}
  {{- end }}

{{- end }}

{{- end }}