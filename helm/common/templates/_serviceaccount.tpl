{{- define "dhondoo.serviceaccount" -}}

{{- if .Values.serviceAccount.create }}

apiVersion: v1
kind: ServiceAccount

metadata:
  name: {{ include "dhondoo.serviceAccountName" . }}

  labels:
    {{- include "dhondoo.labels" . | nindent 4 }}

  {{- with .Values.serviceAccount.annotations }}
  annotations:
{{ toYaml . | nindent 4 }}
  {{- end }}

automountServiceAccountToken: false

{{- end }}

{{- end -}}