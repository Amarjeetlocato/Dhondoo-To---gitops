# helm/common/templates/_pdb.tpl

{{- define "dhondoo.pdb" -}}

{{- if .Values.pdb.enabled }}

apiVersion: policy/v1
kind: PodDisruptionBudget

metadata:
  name: {{ include "dhondoo.fullname" . }}
  labels:
    {{- include "dhondoo.labels" . | nindent 4 }}

spec:
  selector:
    matchLabels:
      {{- include "dhondoo.selectorLabels" . | nindent 6 }}

  {{- if .Values.pdb.maxUnavailable }}
  maxUnavailable: {{ .Values.pdb.maxUnavailable }}
  {{- else }}
  minAvailable: {{ default 1 .Values.pdb.minAvailable }}
  {{- end }}

{{- end }}

{{- end -}}