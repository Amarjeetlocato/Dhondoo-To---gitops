# helm/common/templates/_hpa.tpl

{{- define "dhondoo.hpa" -}}

{{- if .Values.autoscaling.enabled }}

apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler

metadata:
  name: {{ include "dhondoo.fullname" . }}
  labels:
    {{- include "dhondoo.labels" . | nindent 4 }}

spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "dhondoo.fullname" . }}

  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}

  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}

    {{- if .Values.autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}

  {{- if .Values.autoscaling.behavior.enabled }}
  behavior:

    scaleUp:
      stabilizationWindowSeconds: {{ default 0 .Values.autoscaling.behavior.scaleUp.stabilizationWindowSeconds }}
      selectPolicy: {{ default "Max" .Values.autoscaling.behavior.scaleUp.selectPolicy }}
      policies:
        {{- toYaml .Values.autoscaling.behavior.scaleUp.policies | nindent 8 }}

    scaleDown:
      stabilizationWindowSeconds: {{ default 300 .Values.autoscaling.behavior.scaleDown.stabilizationWindowSeconds }}
      selectPolicy: {{ default "Min" .Values.autoscaling.behavior.scaleDown.selectPolicy }}
      policies:
        {{- toYaml .Values.autoscaling.behavior.scaleDown.policies | nindent 8 }}

  {{- end }}

{{- end }}

{{- end -}}