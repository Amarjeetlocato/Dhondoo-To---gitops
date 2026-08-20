# helm/common/templates/_deployment.tpl

{{- define "dhondoo.deployment" -}}

{{- /*
  Normalize optional nested values so Helm never attempts to access
  a child property from a nil parent object.
*/ -}}

{{- $strategy := .Values.strategy | default dict -}}
{{- $rollingUpdate := $strategy.rollingUpdate | default dict -}}

{{- $podAntiAffinity := .Values.podAntiAffinity | default dict -}}
{{- $topologySpreadConstraints := .Values.topologySpreadConstraints | default dict -}}

{{- $containerSecurityContext := .Values.containerSecurityContext | default dict -}}

{{- $configMap := .Values.configMap | default dict -}}
{{- $secret := .Values.secret | default dict -}}

{{- $java := .Values.java | default dict -}}

{{- $lifecycle := .Values.lifecycle | default dict -}}
{{- $preStop := $lifecycle.preStop | default dict -}}

{{- $probes := .Values.probes | default dict -}}
{{- $startupProbe := $probes.startup | default dict -}}
{{- $readinessProbe := $probes.readiness | default dict -}}
{{- $livenessProbe := $probes.liveness | default dict -}}

{{- $strategyType := $strategy.type | default "RollingUpdate" -}}

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
    type: {{ $strategyType }}

    {{- if eq $strategyType "RollingUpdate" }}
    rollingUpdate:
      maxUnavailable: {{ $rollingUpdate.maxUnavailable | default 0 }}
      maxSurge: {{ $rollingUpdate.maxSurge | default 1 }}
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

      {{- if or .Values.affinity $podAntiAffinity.enabled }}

      affinity:

        {{- with .Values.affinity }}
        {{- toYaml . | nindent 8 }}
        {{- end }}

        {{- if and $podAntiAffinity.enabled (not .Values.affinity.podAntiAffinity) }}

        podAntiAffinity:

          {{- if eq ($podAntiAffinity.type | default "preferred") "required" }}

          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  {{- include "dhondoo.selectorLabels" . | nindent 18 }}
              topologyKey: {{ default "kubernetes.io/hostname" $podAntiAffinity.topologyKey }}

          {{- else }}

          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: {{ default 100 $podAntiAffinity.weight }}
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    {{- include "dhondoo.selectorLabels" . | nindent 20 }}
                topologyKey: {{ default "kubernetes.io/hostname" $podAntiAffinity.topologyKey }}

          {{- end }}

        {{- end }}

      {{- end }}

      {{- if $topologySpreadConstraints.enabled }}

      topologySpreadConstraints:
        - maxSkew: {{ default 1 $topologySpreadConstraints.maxSkew }}
          topologyKey: {{ default "kubernetes.io/hostname" $topologySpreadConstraints.topologyKey }}
          whenUnsatisfiable: {{ default "ScheduleAnyway" $topologySpreadConstraints.whenUnsatisfiable }}
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

          {{- if $containerSecurityContext.enabled }}

          securityContext:
            runAsUser: {{ default 1000 $containerSecurityContext.runAsUser }}
            runAsGroup: {{ default 1000 $containerSecurityContext.runAsGroup }}
            runAsNonRoot: {{ default true $containerSecurityContext.runAsNonRoot }}
            allowPrivilegeEscalation: {{ default false $containerSecurityContext.allowPrivilegeEscalation }}
            readOnlyRootFilesystem: {{ default false $containerSecurityContext.readOnlyRootFilesystem }}

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

            {{- if $java.enabled }}
            - name: JAVA_TOOL_OPTIONS
              value: {{ $java.options | quote }}
            {{- end }}

            {{- with .Values.env }}
            {{- toYaml . | nindent 12 }}
            {{- end }}

                    {{- if or .Values.envFrom $configMap.enabled $configMap.commonName $configMap.existingName $secret.commonName $secret.existingName }}

          envFrom:

            {{- with .Values.envFrom }}
            {{- toYaml . | nindent 12 }}
            {{- end }}

            {{- if $configMap.commonName }}
            - configMapRef:
                name: {{ $configMap.commonName }}
            {{- end }}
            {{- if $configMap.existingName }}
            - configMapRef:
                name: {{ $configMap.existingName }}
            {{- else if $configMap.enabled }}
            - configMapRef:
                name: {{ include "dhondoo.fullname" . }}
            {{- end }}

            {{- if $secret.commonName }}
            - secretRef:
                name: {{ $secret.commonName }}
            {{- end }}
            {{- if $secret.existingName }}
            - secretRef:
                name: {{ $secret.existingName }}
            {{- end }}

          {{- end }}

          {{- with .Values.extraVolumeMounts }}
          volumeMounts:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- if $lifecycle.enabled }}

          lifecycle:

            {{- if $preStop.enabled }}

            preStop:
              exec:
                command:
                  {{- toYaml $preStop.command | nindent 18 }}

            {{- end }}

          {{- end }}

          resources:
            {{- toYaml .Values.resources | nindent 12 }}

          {{- if $startupProbe.enabled }}

          startupProbe:
            httpGet:
              path: {{ $startupProbe.path }}
              port: http
              scheme: HTTP

            initialDelaySeconds: {{ default 10 $startupProbe.initialDelaySeconds }}
            timeoutSeconds: {{ default 5 $startupProbe.timeoutSeconds }}
            periodSeconds: {{ default 5 $startupProbe.periodSeconds }}
            failureThreshold: {{ default 36 $startupProbe.failureThreshold }}
            successThreshold: {{ default 1 $startupProbe.successThreshold }}

          {{- end }}

          {{- if $readinessProbe.enabled }}

          readinessProbe:
            httpGet:
              path: {{ $readinessProbe.path }}
              port: http
              scheme: HTTP

            initialDelaySeconds: {{ default 10 $readinessProbe.initialDelaySeconds }}
            timeoutSeconds: {{ default 5 $readinessProbe.timeoutSeconds }}
            periodSeconds: {{ default 10 $readinessProbe.periodSeconds }}
            failureThreshold: {{ default 6 $readinessProbe.failureThreshold }}
            successThreshold: {{ default 1 $readinessProbe.successThreshold }}

          {{- end }}

          {{- if $livenessProbe.enabled }}

          livenessProbe:
            httpGet:
              path: {{ $livenessProbe.path }}
              port: http
              scheme: HTTP

            initialDelaySeconds: {{ default 10 $livenessProbe.initialDelaySeconds }}
            timeoutSeconds: {{ default 5 $livenessProbe.timeoutSeconds }}
            periodSeconds: {{ default 20 $livenessProbe.periodSeconds }}
            failureThreshold: {{ default 3 $livenessProbe.failureThreshold }}
            successThreshold: {{ default 1 $livenessProbe.successThreshold }}

          {{- end }}

{{- end -}}