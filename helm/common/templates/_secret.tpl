{{- define "dhondoo.secret" -}}

{{- if .Values.secret.enabled }}

apiVersion: v1
kind: Secret

metadata:
  name: {{ include "dhondoo.fullname" . }}

  labels:
    {{- include "dhondoo.labels" . | nindent 4 }}

type: Opaque

stringData:
{{- range $key, $value := .Values.secret.data }}
  {{ $key }}: {{ $value | quote }}
{{- end }}

{{- end }}

{{- end -}}