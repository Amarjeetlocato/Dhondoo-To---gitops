{{/*
==============================================================================
Dhondoo Enterprise Helm Library
Common Helper Templates

This file contains reusable helper functions shared by all application charts.
These helpers provide consistent naming, labels, selectors, and ServiceAccount
generation across the entire platform.
==============================================================================
*/}}

{{/*
------------------------------------------------------------------------------
Chart Name

Returns the chart name or nameOverride if provided.

Example:
Chart Name   : gateway
nameOverride : api

Result:
api
------------------------------------------------------------------------------
*/}}
{{- define "dhondoo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
------------------------------------------------------------------------------
Full Resource Name

Generates a unique Kubernetes resource name.

Example:

Release Name : dev
Chart Name   : gateway

Result:
dev-gateway
------------------------------------------------------------------------------
*/}}
{{- define "dhondoo.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "dhondoo.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
------------------------------------------------------------------------------
Chart Label

Example:

gateway-1.0.0
------------------------------------------------------------------------------
*/}}
{{- define "dhondoo.chart" -}}
{{- printf "%s-%s" .Chart.Name (.Chart.Version | replace "+" "_") | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
------------------------------------------------------------------------------
Common Labels

Applied to every Kubernetes resource.

Reference:
https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/
------------------------------------------------------------------------------
*/}}
{{- define "dhondoo.labels" -}}
helm.sh/chart: {{ include "dhondoo.chart" . }}
app.kubernetes.io/name: {{ include "dhondoo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: dhondoo
{{- end -}}

{{/*
------------------------------------------------------------------------------
Selector Labels

These labels are used by:

- Deployment
- Service
- HorizontalPodAutoscaler

IMPORTANT:
Never change selector labels after a resource has been created.
------------------------------------------------------------------------------
*/}}
{{- define "dhondoo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dhondoo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
------------------------------------------------------------------------------
Service Account Name

If serviceAccount.create=true

Use:
- serviceAccount.name (if specified)
- otherwise generated fullname

If create=false

Use Kubernetes default ServiceAccount.
------------------------------------------------------------------------------
*/}}
{{- define "dhondoo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "dhondoo.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
default
{{- end -}}
{{- end -}}