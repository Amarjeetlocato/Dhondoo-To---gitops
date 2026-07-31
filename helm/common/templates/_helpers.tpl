{{/*
==============================================================================
Dhondoo Enterprise Helm Library
Common Helper Templates
==============================================================================

This file contains reusable helper functions that are shared by all Helm
templates in this chart.

These helpers eliminate duplication and provide consistent naming,
labels, selectors, and service account generation.

==============================================================================
*/}}

{{/*
------------------------------------------------------------------------------
Chart Name
Returns the chart name or nameOverride if specified.
------------------------------------------------------------------------------
*/}}
{{- define "dhondoo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
------------------------------------------------------------------------------
Fully Qualified Name
Generates a unique resource name.

Example:
Release Name : gateway
Chart Name   : service-registry

Result:
gateway-service-registry
------------------------------------------------------------------------------
*/}}
{{- define "dhondoo.fullname" -}}

{{- if .Values.fullnameOverride }}

{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}

{{- else }}

{{- printf "%s-%s" .Release.Name (include "dhondoo.name" .) | trunc 63 | trimSuffix "-" }}

{{- end }}

{{- end }}

{{/*
------------------------------------------------------------------------------
Chart Label

Example

gateway-1.0.0

------------------------------------------------------------------------------
*/}}
{{- define "dhondoo.chart" -}}

{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}

{{- end }}

{{/*
------------------------------------------------------------------------------
Common Labels

These labels are added to every Kubernetes resource.

Recommended Kubernetes labels:
https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/
------------------------------------------------------------------------------
*/}}

{{- define "dhondoo.labels" }}

helm.sh/chart: {{ include "dhondoo.chart" . }}

app.kubernetes.io/name: {{ include "dhondoo.name" . }}

app.kubernetes.io/instance: {{ .Release.Name }}

app.kubernetes.io/version: {{ .Chart.AppVersion }}

app.kubernetes.io/managed-by: {{ .Release.Service }}

{{- end }}

{{/*
------------------------------------------------------------------------------
Selector Labels

Selectors are used by

Deployment
Service
HPA

These MUST NEVER change after deployment.

------------------------------------------------------------------------------
*/}}

{{- define "dhondoo.selectorLabels" }}

app.kubernetes.io/name: {{ include "dhondoo.name" . }}

app.kubernetes.io/instance: {{ .Release.Name }}

{{- end }}

{{/*
------------------------------------------------------------------------------
Service Account Name

If create=true

Generate ServiceAccount

Else

Use default Kubernetes ServiceAccount

------------------------------------------------------------------------------
*/}}

{{- define "dhondoo.serviceAccountName" }}

{{- if .Values.serviceAccount.create }}

{{- default (include "dhondoo.fullname" .) .Values.serviceAccount.name }}

{{- else }}

default

{{- end }}

{{- end }}