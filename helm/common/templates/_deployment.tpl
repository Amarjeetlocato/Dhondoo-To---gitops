{{- define "dhondoo.deployment" -}}

apiVersion: apps/v1
kind: Deployment

metadata:
  name: {{ include "dhondoo.fullname" . }}
  labels:
    {{- include "dhondoo.labels" . | nindent 4 }}

spec:
  replicas: {{ .Values.replicaCount }}

  revisionHistoryLimit: 10

  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1

  selector:
    matchLabels:
      {{- include "dhondoo.selectorLabels" . | nindent 6 }}

  template:
    metadata:
      labels:
        {{- include "dhondoo.selectorLabels" . | nindent 8 }}

      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}

    spec:

      {{- with .Values.securityContext }}
      securityContext:
        fsGroup: {{ .fsGroup }}
      {{- end }}

      serviceAccountName: {{ include "dhondoo.serviceAccountName" . }}

      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      containers:
        - name: {{ include "dhondoo.name" . }}

          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}

          {{- with .Values.securityContext }}
          securityContext:
            runAsUser: {{ .runAsUser }}
            runAsGroup: {{ .runAsGroup }}
            runAsNonRoot: {{ .runAsNonRoot }}
            allowPrivilegeEscalation: {{ .allowPrivilegeEscalation }}
            readOnlyRootFilesystem: {{ .readOnlyRootFilesystem }}
            capabilities:
              drop:
                - ALL
          {{- end }}

          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP

          env:
            - name: SPRING_PROFILES_ACTIVE
              value: {{ .Values.springProfile | quote }}

            - name: TZ
              value: {{ .Values.timezone | quote }}

          envFrom:
  - configMapRef:
      name: {{ include "dhondoo.name" . }}-config

  - secretRef:
      name: {{ include "dhondoo.name" . }}-secret

          resources:
            {{- toYaml .Values.resources | nindent 12 }}

          livenessProbe:
            httpGet:
              path: {{ .Values.probes.liveness.path }}
              port: {{ .Values.service.targetPort }}
            initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.liveness.periodSeconds }}

          readinessProbe:
            httpGet:
              path: {{ .Values.probes.readiness.path }}
              port: {{ .Values.service.targetPort }}
            initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.readiness.periodSeconds }}

          startupProbe:
            httpGet:
              path: {{ .Values.probes.startup.path }}
              port: {{ .Values.service.targetPort }}
            failureThreshold: {{ .Values.probes.startup.failureThreshold }}
            periodSeconds: {{ .Values.probes.startup.periodSeconds }}

      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}

{{- end -}}