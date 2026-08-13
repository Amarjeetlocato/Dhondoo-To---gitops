# helm/common/templates/_deployment.tpl

{{- define "dhondoo.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "dhondoo.fullname" . }}
  labels:
    {{- include "dhondoo.labels" . | nindent 4 }}
spec:
  replicas: {{ default 1 .Values.replicaCount }}
  revisionHistoryLimit: {{ default 10 .Values.revisionHistoryLimit }}
  minReadySeconds: {{ default 0 .Values.minReadySeconds }}

  strategy:
    type: {{ default "RollingUpdate" .Values.strategy.type }}
    {{- if eq (default "RollingUpdate" .Values.strategy.type) "RollingUpdate" }}
    rollingUpdate:
      maxUnavailable: {{ default 0 .Values.strategy.rollingUpdate.maxUnavailable }}
      maxSurge: {{ default 1 .Values.strategy.rollingUpdate.maxSurge }}
    {{- end }}

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
      terminationGracePeriodSeconds: {{ default 30 .Values.terminationGracePeriodSeconds }}

      {{- if .Values.securityContext }}
      securityContext:
        runAsNonRoot: {{ default true .Values.securityContext.runAsNonRoot }}
        runAsUser: {{ default 1000 .Values.securityContext.runAsUser }}
        runAsGroup: {{ default 1000 .Values.securityContext.runAsGroup }}
        fsGroup: {{ default 1000 .Values.securityContext.fsGroup }}
        {{- if hasKey .Values.securityContext "seccompProfile" }}
        seccompProfile:
          {{- toYaml .Values.securityContext.seccompProfile | nindent 10 }}
        {{- end }}
      {{- end }}

      serviceAccountName: {{ include "dhondoo.serviceAccountName" . }}

      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- if or .Values.affinity .Values.podAntiAffinity.enabled }}
      affinity:
        {{- with .Values.affinity }}
        {{- toYaml . | nindent 8 }}
        {{- end }}

        {{- if and .Values.podAntiAffinity.enabled (not .Values.affinity.podAntiAffinity) }}
        podAntiAffinity:
          {{- if eq .Values.podAntiAffinity.type "required" }}
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  {{- include "dhondoo.selectorLabels" . | nindent 18 }}
              topologyKey: {{ default "kubernetes.io/hostname" .Values.podAntiAffinity.topologyKey }}
          {{- else }}
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: {{ default 100 .Values.podAntiAffinity.weight }}
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    {{- include "dhondoo.selectorLabels" . | nindent 20 }}
                topologyKey: {{ default "kubernetes.io/hostname" .Values.podAntiAffinity.topologyKey }}
          {{- end }}
        {{- end }}
      {{- end }}

      {{- if .Values.topologySpreadConstraints.enabled }}
      topologySpreadConstraints:
        - maxSkew: {{ default 1 .Values.topologySpreadConstraints.maxSkew }}
          topologyKey: {{ default "kubernetes.io/hostname" .Values.topologySpreadConstraints.topologyKey }}
          whenUnsatisfiable: {{ default "ScheduleAnyway" .Values.topologySpreadConstraints.whenUnsatisfiable }}
          labelSelector:
            matchLabels:
              {{- include "dhondoo.selectorLabels" . | nindent 14 }}
      {{- end }}

      {{- with .Values.extraVolumes }}
      volumes:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      containers:
        - name: {{ include "dhondoo.name" . }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ default "IfNotPresent" .Values.image.pullPolicy }}

          {{- if .Values.containerSecurityContext.enabled }}
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

            {{- if .Values.java.enabled }}
            - name: JAVA_TOOL_OPTIONS
              value: {{ .Values.java.options | quote }}
            {{- end }}

            {{- with .Values.env }}
            {{- toYaml . | nindent 12 }}
            {{- end }}

          {{- if or .Values.envFrom .Values.configMap.commonName .Values.configMap.existingName .Values.secret.commonName .Values.secret.existingName }}
          envFrom:

            {{- with .Values.envFrom }}
            {{- toYaml . | nindent 12 }}
            {{- end }}

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

          {{- with .Values.extraVolumeMounts }}
          volumeMounts:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- if .Values.lifecycle.enabled }}
          lifecycle:
            {{- if .Values.lifecycle.preStop.enabled }}
            preStop:
              exec:
                command:
                  {{- toYaml .Values.lifecycle.preStop.command | nindent 18 }}
            {{- end }}
          {{- end }}

          resources:
            {{- toYaml .Values.resources | nindent 12 }}

          {{- if .Values.probes.startup.enabled }}
          startupProbe:
            httpGet:
              path: {{ .Values.probes.startup.path }}
              port: http
              scheme: HTTP
            initialDelaySeconds: {{ default 10 .Values.probes.startup.initialDelaySeconds }}
            timeoutSeconds: {{ default 5 .Values.probes.startup.timeoutSeconds }}
            periodSeconds: {{ default 5 .Values.probes.startup.periodSeconds }}
            failureThreshold: {{ default 36 .Values.probes.startup.failureThreshold }}
            successThreshold: {{ default 1 .Values.probes.startup.successThreshold }}
          {{- end }}

          {{- if .Values.probes.readiness.enabled }}
          readinessProbe:
            httpGet:
              path: {{ .Values.probes.readiness.path }}
              port: http
              scheme: HTTP
            initialDelaySeconds: {{ default 10 .Values.probes.readiness.initialDelaySeconds }}
            timeoutSeconds: {{ default 5 .Values.probes.readiness.timeoutSeconds }}
            periodSeconds: {{ default 10 .Values.probes.readiness.periodSeconds }}
            failureThreshold: {{ default 6 .Values.probes.readiness.failureThreshold }}
            successThreshold: {{ default 1 .Values.probes.readiness.successThreshold }}
          {{- end }}

          {{- if .Values.probes.liveness.enabled }}
          livenessProbe:
            httpGet:
              path: {{ .Values.probes.liveness.path }}
              port: http
              scheme: HTTP
            initialDelaySeconds: {{ default 10 .Values.probes.liveness.initialDelaySeconds }}
            timeoutSeconds: {{ default 5 .Values.probes.liveness.timeoutSeconds }}
            periodSeconds: {{ default 20 .Values.probes.liveness.periodSeconds }}
            failureThreshold: {{ default 3 .Values.probes.liveness.failureThreshold }}
            successThreshold: {{ default 1 .Values.probes.liveness.successThreshold }}
          {{- end }}

{{- end -}}