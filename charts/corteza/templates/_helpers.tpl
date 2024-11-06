{{/*
Expand the name of the chart.
*/}}
{{- define "corteza.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "corteza.fullname" -}}
{{- $name := .Chart.Name }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "corteza.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Return  the proper Storage Class
{{ include "corteza.storage.class" ( dict "persistence" .Values.path.to.the.persistence "global" $) }}
*/}}
{{- define "corteza.storage.class" -}}
{{- $storageClass := (.global).storageClass | default .persistence.storageClass | default "" -}}
{{- if $storageClass -}}
  {{- if (eq "-" $storageClass) -}}
      {{- printf "storageClassName: \"\"" -}}
  {{- else -}}
      {{- printf "storageClassName: %s" $storageClass -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the storageClass snippet for corteza server.
*/}}
{{- define "corteza.server.storageClass" -}}
{{- include "corteza.storage.class" (dict "persistence" .Values.server.persistence "global" .Values.global) -}}
{{- end -}}

{{/*
Create the storageClass snippet for corredor.
*/}}
{{- define "corteza.corredor.storageClass" -}}
{{- include "corteza.storage.class" (dict "persistence" .Values.corredor.persistence "global" .Values.global) -}}
{{- end -}}

{{/*
Create a default fully qualified app name for corteza server.
*/}}
{{- define "corteza.server.fullname" -}}
{{- if .Values.server.nameOverride }}
{{- printf "%s-%s" .Values.server.nameOverride .Values.server.name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" (include "corteza.fullname" .) .Values.server.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create host of server
*/}}
{{- define "corteza.server.host" -}}
{{- $insecure := .Values.global.insecure | toString -}}
{{- $scheme := (eq $insecure "true") | ternary "http" "https" -}}
{{- $host := .Values.global.domain }}
{{- printf "%s://%s" $scheme $host -}}
{{- end -}}

{{/*
Create auth external redirect url of server
*/}}
{{- define "corteza.server.authExternalRedirectUrl" -}}
{{- $host := include "corteza.server.host" . }}
{{- $endpoint := "auth/external/{provider}/callback" }}
{{- printf "%s/%s" $host $endpoint -}}
{{- end -}}

{{/*
Create auth base url of server
*/}}
{{- define "corteza.server.authBaseUrl" -}}
{{- $host := include "corteza.server.host" . }}
{{- $endpoint := "auth" }}
{{- printf "%s/%s" $host $endpoint -}}
{{- end -}}

{{/*
Create a default fully qualified app name for corredor.
*/}}
{{- define "corteza.corredor.fullname" -}}
{{- if .Values.corredor.nameOverride }}
{{- printf "%s-%s" .Values.corredor.nameOverride .Values.corredor.name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" (include "corteza.fullname" .) .Values.corredor.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create address of corredor
*/}}
{{- define "corteza.corredor.address" -}}
{{- $host := include "corteza.corredor.fullname" . }}
{{- $port := int .Values.corredor.service.port }}
{{- printf "%s:%d" $host $port -}}
{{- end -}}

{{/*
Create address of corteza for corredor
*/}}
{{- define "corredor.corteza.address" -}}
{{- printf "http://%s" (include "corteza.server.fullname" .) -}}
{{- end -}}

CORREDOR_EXEC_CSERVERS_API_BASEURL_TEMPLATE

{{/*
Create address of corredor exec cservers api baseurl template
*/}}
{{- define "corredor.exec.cservers.api.baseurl.template" -}}
{{- printf "%s/%s" (include "corredor.corteza.address" .) "api/{service}" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "corteza.labels" -}}
helm.sh/chart: {{ include "corteza.chart" .context }}
{{ include "corteza.selectorLabels" (dict "context" .context "component" .component "name" .name) }}
app.kubernetes.io/managed-by: {{ .context.Release.Service }}
{{- if .context.Chart.AppVersion }}
app.kubernetes.io/version: {{ .context.Chart.AppVersion }}
{{- end }}
app.kubernetes.io/part-of: corteza
{{- end }}

{{/*
Selector labels
*/}}
{{- define "corteza.selectorLabels" -}}
app.kubernetes.io/name: {{ include "corteza.name" .context }}-{{ .name }}
app.kubernetes.io/instance: {{ .context.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "corteza.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "corteza.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account of corteza server to use
*/}}
{{- define "corteza.server.serviceAccountName" -}}
{{- if .Values.server.serviceAccount.create }}
{{- default (include "corteza.server.fullname" .) .Values.server.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.server.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account of corredor to use
*/}}
{{- define "corteza.corredor.serviceAccountName" -}}
{{- if .Values.corredor.serviceAccount.create }}
{{- default (include "corteza.corredor.fullname" .) .Values.corredor.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.corredor.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create DB DSN.
*/}}
{{- define "corteza.dbDsn" -}}
{{- printf "postgres://%s:%s@%s-postgresql:%s/%s?sslmode=disable" .Values.postgresql.auth.username .Values.postgresql.auth.password .Release.Name .Values.postgresql.global.postgresql.service.ports.postgresql .Values.postgresql.auth.database  }}
{{- end }}

{{/*
Create Corredor init clone repo command list
*/}}
{{- define "corteza.corredor.initCloneRepo.commandList" -}}
- '/bin/bash'
- '-c'
- |
  gcloud secrets versions access 1 --secret=ssh-privatekey > id_rsa
  perl -e 'chmod 0600, "id_rsa"'
  eval "$(ssh-agent -s)"
  ssh-add id_rsa
  mkdir ~/.ssh
  ssh-keyscan -H github.com >> ~/.ssh/known_hosts
  git clone --depth=1 git@github.com:origoss/corteza-corredor-scripts.git
  mkdir -p /corredor/usr/client-scripts/compose
  cp -r corteza-corredor-scripts/client-scripts/compose/* /corredor/usr/client-scripts/compose
  ls /corredor/usr/client-scripts/compose
{{- end }}
