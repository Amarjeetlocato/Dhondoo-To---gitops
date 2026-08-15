{{- define "dhondoo.notes" -}}

Thank you for installing {{ .Chart.Name }}

-----------------------------------------------------

Release Name:
{{ .Release.Name }}

Namespace:
{{ .Release.Namespace }}

Chart Version:
{{ .Chart.Version }}

Application Version:
{{ .Chart.AppVersion }}

-----------------------------------------------------

Application

Service:
{{ include "dhondoo.fullname" . }}

Port:
{{ .Values.service.port }}

Service Type:
{{ .Values.service.type }}

-----------------------------------------------------

Image

Repository:
{{ .Values.image.repository }}

Tag:
{{ .Values.image.tag }}

-----------------------------------------------------

Replicas

{{ .Values.replicaCount }}

-----------------------------------------------------

Ingress

{{- if .Values.ingress.enabled }}

Enabled

{{- range .Values.ingress.hosts }}

Host: {{ .host }}

{{- end }}

{{- else }}

Disabled

{{- end }}

-----------------------------------------------------

Dhondoo Enterprise Helm Library

{{- end -}}