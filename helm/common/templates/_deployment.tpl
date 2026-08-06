{{- define "dhondoo.deployment" -}}

apiVersion: apps/v1
kind: Deployment

metadata:
  name: {{ include "dhondoo.fullname" . }}
  labels:
    {{- include "dhondoo.labels" . | nindent 4 }}

spec:
  replicas: {{ default 1 .Values.replicaCount }}
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
{{ toYaml . | indent 8 }}
      {{- end }}

    spec:

      {{- if .Values.securityContext }}
      securityContext:
        fsGroup: {{ default 1000 .Values.securityContext.fsGroup }}
      {{- end }}

      serviceAccountName: {{ include "dhondoo.serviceAccountName" . }}

      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
{{ toYaml . | indent 8 }}
      {{- end }}

      containers:
        - name: {{ include "dhondoo.name" . }}

          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ default "IfNotPresent" .Values.image.pullPolicy }}

          {{- if .Values.securityContext }}
          securityContext:
            runAsUser: {{ default 1000 .Values.securityContext.runAsUser }}
            runAsGroup: {{ default 1000 .Values.securityContext.runAsGroup }}
            runAsNonRoot: {{ default true .Values.securityContext.runAsNonRoot }}
            allowPrivilegeEscalation: {{ default false .Values.securityContext.allowPrivilegeEscalation }}
            readOnlyRootFilesystem: {{ default false .Values.securityContext.readOnlyRootFilesystem }}
            capabilities:
              drop:
                - ALL
          {{- end }}

          ports:
            - name: http
              containerPort: {{ default 8080 .Values.service.targetPort }}
              protocol: TCP

          env:

            {{- if .Values.springProfile }}
            - name: SPRING_PROFILES_ACTIVE
              value: {{ .Values.springProfile | quote }}
            {{- end }}

            {{- if .Values.timezone }}
            - name: TZ
              value: {{ .Values.timezone | quote }}
            {{- end }}

          {{- if or .Values.configMap.commonName .Values.configMap.existingName .Values.secret.commonName .Values.secret.existingName }}
          envFrom:

            {{- if .Values.configMap.commonName }}
            - configMapRef:
                name: {{ .Values.configMap.commonName }}
            {{- end }}

            {{- if .Values.configMap.existingName }}
            - configMapRef:
                name: {{ .Values.configMap.existingName }}
            {{- end }}

            {{- if .Values.secret.commonName }}
            - secretRef:
                name: {{ .Values.secret.commonName }}
            {{- end }}

            {{- if .Values.secret.existingName }}
            - secretRef:
                name: {{ .Values.secret.existingName }}
            {{- end }}

          {{- end }}

          {{- with .Values.resources }}
          resources:
{{ toYaml . | indent 12 }}
          {{- end }}

          {{- if .Values.probes.liveness }}
          livenessProbe:
            httpGet:
              path: {{ .Values.probes.liveness.path }}
              port: {{ default 8080 $.Values.service.targetPort }}
            initialDelaySeconds: {{ default 30 .Values.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ default 10 .Values.probes.liveness.periodSeconds }}
          {{- end }}

          {{- if .Values.probes.readiness }}
          readinessProbe:
            httpGet:
              path: {{ .Values.probes.readiness.path }}
              port: {{ default 8080 $.Values.service.targetPort }}
            initialDelaySeconds: {{ default 15 .Values.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ default 5 .Values.probes.readiness.periodSeconds }}
          {{- end }}

          {{- if .Values.probes.startup }}
          startupProbe:
            httpGet:
              path: {{ .Values.probes.startup.path }}
              port: {{ default 8080 $.Values.service.targetPort }}
            failureThreshold: {{ default 30 .Values.probes.startup.failureThreshold }}
            periodSeconds: {{ default 10 .Values.probes.startup.periodSeconds }}
          {{- end }}

      {{- with .Values.nodeSelector }}
      nodeSelector:
{{ toYaml . | indent 8 }}
      {{- end }}

      {{- with .Values.affinity }}
      affinity:
{{ toYaml . | indent 8 }}
      {{- end }}

      {{- with .Values.tolerations }}
      tolerations:
{{ toYaml . | indent 8 }}
      {{- end }}

{{- end -}}