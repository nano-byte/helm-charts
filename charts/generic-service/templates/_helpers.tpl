{{ define "generic-service.name" -}}
  {{ default .Values.name | default .Release.Name }}
{{- end }}


{{ define "generic-service.fullname" -}}
  {{- if .Values.fullname -}}
    {{ .Values.fullname }}
  {{- else -}}
    {{ .Release.Name }}{{ if not (contains .Values.name .Release.Name) }}-{{ .Values.name }}{{ end }}
  {{- end -}}
{{- end }}


{{ define "generic-service.selector-labels" -}}
app: {{ include "generic-service.name" . }}
release: {{ include "generic-service.fullname" . }}
{{- end }}


{{ define "generic-service.default-labels" -}}

{{ include "generic-service.selector-labels" . }}
version: {{ .Values.image.tag | quote }}
app.kubernetes.io/name: {{ include "generic-service.name" . }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/instance: {{ include "generic-service.fullname" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: 'generic-service-{{ .Chart.Version }}'

{{- if .Values.labels }}
{{ .Values.labels | toYaml }}
{{- end }}

{{- end }}


{{ define "generic-service.alert-labels" -}}
{{ include "generic-service.selector-labels" . }}
{{- if .Values.global.alertLabels }}
{{ .Values.global.alertLabels | toYaml }}
{{- end }}
namespace: {{ .Release.Namespace }}
severity:
{{- end }}


{{ define "generic-service.alert-annotations" -}}
{{ if and .Values.global.grafana.url .Values.global.grafana.dashboard -}}
dashboard: '{{ .Values.global.grafana.url }}/d/{{ .Values.global.grafana.dashboard }}?var-namespace={{ .Release.Namespace }}&var-service={{ include "generic-service.fullname" . }}'
{{- end }}
summary: {{ .Release.Namespace }}/{{ include "generic-service.fullname" . }}
{{- end }}


{{ define "generic-service.istio" -}}

{{- if .Values.ingress.istio.gateways }}
gateways: {{ .Values.ingress.istio.gateways | toYaml | nindent 2 }}
{{- end }}

hosts:
{{- if .Values.ingress.domains }}
{{ .Values.ingress.domains | toYaml | indent 2 }}
{{- else }}
  - {{ include "generic-service.fullname" . }}
{{- end }}

{{- end }}

{{ define "generic-service.istio-cors-policy" -}}
{{- if .Values.ingress.cors.enabled }}
{{- if .Values.ingress.cors.allowOrigins }}
allowOrigins:
  {{- range .Values.ingress.cors.allowOrigins }}
  - {{ if contains . "*" }}regex{{ else }}exact{{ end }}: {{ . | replace "*" ".*" | quote }}
  {{- end }}
{{- end }}
{{ if .Values.ingress.cors.allowMethods }}allowMethods: {{ .Values.ingress.cors.allowMethods | toYaml | nindent 2 }}{{ end }}
allowCredentials: {{ .Values.ingress.cors.allowCredentials }}
{{ if .Values.ingress.cors.allowHeaders }}allowHeaders: {{ .Values.ingress.cors.allowHeaders | toYaml | nindent 2 }}{{ end }}
{{ if .Values.ingress.cors.exposeHeaders }}exposeHeaders: {{ .Values.ingress.cors.exposeHeaders | toYaml | nindent 2 }}{{ end }}
{{- end }}
{{- end }}


{{ define "generic-service.request-count-metric" -}}
{{- if .Values.ingress.istio.enabled -}}
istio_requests_total{destination_service_namespace="{{ .Release.Namespace }}", destination_service_name="{{ include "generic-service.fullname" . }}", reporter="source"}
{{- else -}}
nginx_ingress_controller_requests{exported_namespace="{{ .Release.Namespace }}", exported_service="{{ include "generic-service.fullname" . }}"}
{{- end }}
{{- end }}


{{ define "generic-service.request-code-count-metric" -}}
{{- if .Values.ingress.istio.enabled -}}
istio_requests_total{destination_service_namespace="{{ .Release.Namespace }}", destination_service_name="{{ include "generic-service.fullname" . }}", reporter="source", response_code=~
{{- else -}}
nginx_ingress_controller_requests{exported_namespace="{{ .Release.Namespace }}", exported_service="{{ include "generic-service.fullname" . }}", status=~
{{- end }}
{{- end }}

{{ define "generic-service.request-duration-metric" -}}
{{- if .Values.ingress.istio.enabled -}}
istio_request_duration_seconds_sum{destination_service_namespace="{{ .Release.Namespace }}", destination_service_name="{{ include "generic-service.fullname" . }}", reporter="source"}
{{- else -}}
nginx_ingress_controller_response_duration_seconds_sum{exported_namespace="{{ .Release.Namespace }}", exported_service="{{ include "generic-service.fullname" . }}"}
{{- end }}
{{- end }}
