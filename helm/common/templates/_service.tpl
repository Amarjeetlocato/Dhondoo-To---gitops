# helm/common/templates/_service.tpl

{{- define "dhondoo.service" -}}

apiVersion: v1
kind: Service

metadata:
  name: {{ include "dhondoo.fullname" . }}

  labels:
    {{- include "dhondoo.labels" . | nindent 4 }}

spec:

  type: {{ default "ClusterIP" .Values.service.type }}

  selector:
    {{- include "dhondoo.selectorLabels" . | nindent 4 }}

  ports:

    - name: http
      protocol: TCP
      port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}

{{- end }}