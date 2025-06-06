{{ define "generic-service.name" -}}
  {{- if .Values.name -}}
    {{ .Values.name }}
  {{- else if and .Values.app .Values.app.name -}}
    {{ .Values.app.name }}
  {{- else -}}
    {{ .Release.Name }}
  {{- end -}}
{{- end }}

{{ define "generic-service.fullname" -}}
  {{- if .Values.fullname -}}
    {{ .Values.fullname }}
  {{- else -}}
    {{ .Release.Name }}
    {{- if .Values.name -}}
      {{- if not (contains .Values.name .Release.Name) }}-{{ .Values.name }}{{ end }}
    {{- else if and .Values.app .Values.app.name -}}
      {{- if not (contains .Values.app.name .Release.Name) }}-{{ .Values.app.name }}{{ end }}
    {{- end }}
  {{- end -}}
{{- end }}


{{ define "generic-service.selector-labels" -}}
app: {{ include "generic-service.name" . }}
release: {{ include "generic-service.fullname" . }}
{{- end }}


{{ define "generic-service.default-labels" -}}

{{ include "generic-service.selector-labels" . }}
app.kubernetes.io/name: {{ include "generic-service.name" . }}
app.kubernetes.io/instance: {{ include "generic-service.fullname" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}

{{- if or .Values.version (not (hasPrefix "@" .Values.image.tag)) }}
version: {{ .Values.version | default .Values.image.tag |  replace "+" "_" | quote }}
app.kubernetes.io/version: {{ .Values.version | default .Values.image.tag | replace "+" "_" | quote }}
{{- end }}

{{- with .Values.labels }}
{{ . | toYaml }}
{{- end }}

{{- end }}

{{ define "generic-service.top-level-labels" -}}
{{ include "generic-service.default-labels" . }}
helm.sh/chart: 'generic-service-{{ .Chart.Version | replace "+" "_" }}'
{{- end }}


{{ define "generic-service.alert-labels" -}}
{{ include "generic-service.selector-labels" . }}
{{- with .Values.global.alertLabels }}
{{ . | toYaml }}
{{- end }}
namespace: {{ .Release.Namespace }}
severity:
{{- end }}


{{ define "generic-service.alert-annotations" -}}
{{- if and .Values.global.grafana.url .Values.global.grafana.dashboard -}}
dashboard: '{{ .Values.global.grafana.url }}/d/{{ .Values.global.grafana.dashboard }}?var-namespace={{ .Release.Namespace }}&var-service={{ include "generic-service.fullname" . }}
{{- range $variable, $value := .Values.global.grafana.queryVariables -}}
&var-{{ urlquery $variable }}={{ urlquery $value }}
{{- end }}'
{{ end -}}
summary: {{ .Release.Namespace }}/{{ include "generic-service.fullname" . }}
{{- end }}


{{ define "generic-service.normalize-protocol" -}}
{{ if eq . "h2c" }}grpc{{ else if or (eq . "http2") (eq . "h2") }}grpcs{{ else }}{{ . | default "http" }}{{ end }}
{{- end }}


{{ define "generic-service.normalize-app-protocol" -}}
{{ if or (eq . "h2c") (eq . "grpc") }}kubernetes.io/h2c{{ else if or (or (eq . "http2") (eq . "h2")) (eq . "grpcs") }}https{{ else }}{{ . | default "http" }}{{ end }}
{{- end }}


{{ define "generic-service.istio" -}}

{{- with .Values.ingress.istio.gateways }}
gateways: {{- . | toYaml | nindent 2 }}
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
{{- with .Values.ingress.cors.allowOrigin }}
allowOrigins:
  {{- range . }}
  - {{ if contains . "*" }}regex{{ else }}exact{{ end }}: {{ . | replace "*" ".*" | quote }}
  {{- end }}
{{- end }}
{{ if .Values.ingress.cors.allowMethods }}allowMethods: {{- .Values.ingress.cors.allowMethods | toYaml | nindent 2 }}{{ end }}
allowCredentials: {{ .Values.ingress.cors.allowCredentials }}
{{ if .Values.ingress.cors.allowHeaders }}allowHeaders: {{- .Values.ingress.cors.allowHeaders | toYaml | nindent 2 }}{{ end }}
{{ if .Values.ingress.cors.exposeHeaders }}exposeHeaders: {{- .Values.ingress.cors.exposeHeaders | toYaml | nindent 2 }}{{ end }}
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


{{ define "generic-service.rollout-notifications-annotations" -}}
{{- if and (eq .Values.rollout.controller "ArgoRollout") .Values.rollout.notifications.slackChannels }}
{{- $slackChannels := (join ";" .Values.rollout.notifications.slackChannels) }}
{{- if .Values.rollout.notifications.subscribe.analysisRunError -}}
notifications.argoproj.io/subscribe.on-analysis-run-error.slack: {{ $slackChannels }}
{{- end }}
{{- if .Values.rollout.notifications.subscribe.analysisRunFailed }}
notifications.argoproj.io/subscribe.on-analysis-run-failed.slack: {{ $slackChannels }}
{{- end }}
{{- if .Values.rollout.notifications.subscribe.analysisRunRunning }}
notifications.argoproj.io/subscribe.on-analysis-run-running.slack: {{ $slackChannels }}
{{- end }}
{{- if .Values.rollout.notifications.subscribe.rolloutAborted }}
notifications.argoproj.io/subscribe.on-rollout-aborted.slack: {{ $slackChannels }}
{{- end }}
{{- if .Values.rollout.notifications.subscribe.rolloutCompleted }}
notifications.argoproj.io/subscribe.on-rollout-completed.slack: {{ $slackChannels }}
{{- end }}
{{- if .Values.rollout.notifications.subscribe.rolloutPaused }}
notifications.argoproj.io/subscribe.on-rollout-paused.slack: {{ $slackChannels }}
{{- end }}
{{- if .Values.rollout.notifications.subscribe.rolloutStepCompleted }}
notifications.argoproj.io/subscribe.on-rollout-step-completed.slack: {{ $slackChannels }}
{{- end }}
{{- if .Values.rollout.notifications.subscribe.rolloutUpdated }}
notifications.argoproj.io/subscribe.on-rollout-updated.slack: {{ $slackChannels }}
{{- end }}
{{- if .Values.rollout.notifications.subscribe.scalingReplicasSet }}
notifications.argoproj.io/subscribe.on-scaling-replica-set.slack: {{ $slackChannels }}
{{- end }}
{{- end }}
{{- end }}

{{ define "generic-service.ingress-annotations" -}}
{{- range $annotationKey, $annotationValue := .annotations }}
{{- if ne $annotationKey "haproxy.org/backend-config-snippet" }}
{{ $annotationKey }}: {{ $annotationValue | quote }}
{{- end }}
{{- end }}
{{- if contains "nginx" .class }}
nginx.ingress.kubernetes.io/backend-protocol: {{ include "generic-service.normalize-protocol" .protocol | upper }}
{{- if .timeoutSeconds }}
nginx.ingress.kubernetes.io/proxy-read-timeout: '{{ .timeoutSeconds }}'
{{- if or (eq .protocol "grpc") (eq .protocol "grpcs") }}
nginx.ingress.kubernetes.io/configuration-snippet: |
  grpc_read_timeout {{ .timeoutSeconds }}s;
  {{- get .annotations "nginx.ingress.kubernetes.io/configuration-snippet" | nindent 6 }}
{{- end }}
{{- end }}
{{- if .cors.enabled }}
nginx.ingress.kubernetes.io/enable-cors: 'true'
{{ if .cors.allowOrigin }}nginx.ingress.kubernetes.io/cors-allow-origin: {{ join "," .cors.allowOrigin | quote }}{{ end }}
{{ if .cors.allowMethods }}nginx.ingress.kubernetes.io/cors-allow-methods: {{ join "," .cors.allowMethods | quote }}{{ end }}
{{ if .cors.allowHeaders }}nginx.ingress.kubernetes.io/cors-allow-headers: {{ join "," .cors.allowHeaders | quote }}{{ end }}
nginx.ingress.kubernetes.io/cors-allow-credentials: {{ .cors.allowCredentials | quote }}
{{ if .cors.exposeHeaders }}nginx.ingress.kubernetes.io/cors-expose-headers: {{ join "," .cors.exposeHeaders | quote }}{{ end }}
{{ if .cors.maxAge }}nginx.ingress.kubernetes.io/cors-max-age: {{ .cors.maxAge | int | quote }}{{ end }}
{{- end }}
{{- end }}
{{- if contains "contour" .class }}
{{- with .timeoutSeconds }}
projectcontour.io/response-timeout: '{{ if eq (int .) -1 }}infinity{{ else }}{{ . }}s{{ end }}'
{{- end }}
{{- if and .tls .tls.enabled .tls.secretNamespace }}
projectcontour.io/tls-cert-namespace: {{ .tls.secretNamespace }}
{{- end }}
{{- end }}
{{- if contains "haproxy" .class }}
{{ include "generic-service.haproxy-backend-config-snippet" . }}
{{- if or (eq .protocol "h2c") (eq .protocol "http2") (eq .protocol "h2") (eq .protocol "grpc") (eq .protocol "grpcs") }}
haproxy.org/server-proto: h2
{{- end }}
{{- if or (eq .protocol "https") (eq .protocol "http2") (eq .protocol "h2") (eq .protocol "grpcs") }}
haproxy.org/server-ssl: "true"
{{- end }}
{{- with .timeoutSeconds }}
haproxy.org/timeout-server: '{{ if eq (int .) -1 }}0{{ else }}{{ . }}s{{ end }}'
{{- end }}
{{- end }}
{{- end }}

{{ define "generic-service.haproxy-backend-config-snippet" -}}
{{- $configSnippet := get .annotations "haproxy.org/backend-config-snippet" | default "" }}
{{- if .cors.enabled }}
{{- $configSnippet = printf "%s\n%s" $configSnippet (printf "http-after-response set-header Access-Control-Allow-Origin %s" (join "," (.cors.allowOrigin | default (list "*"))))  }}
{{- if .cors.allowMethods }}
{{- $configSnippet = printf "%s\n%s" $configSnippet (printf "http-after-response set-header Access-Control-Allow-Methods %s" (join "," .cors.allowMethods))  }}
{{- end }}
{{ if .cors.allowHeaders }}
{{- $configSnippet = printf "%s\n%s" $configSnippet (printf "http-after-response set-header Access-Control-Allow-Headers %s" (join "," .cors.allowHeaders))  }}
{{- end }}
{{- if .cors.exposeHeaders }}
{{- $configSnippet = printf "%s\n%s" $configSnippet (printf "http-after-response set-header Access-Control-Expose-Headers %s" (join "," .cors.exposeHeaders))  }}
{{- end }}
{{- $configSnippet = printf "%s\n%s" $configSnippet (printf "http-after-response set-header Access-Control-Allow-Credentials %v" (.cors.allowCredentials| default "true"))  }}
{{- $configSnippet = printf "%s\n%s" $configSnippet (printf "http-after-response set-header Access-Control-Max-Age %d" (.cors.maxAge | default 1728000 | int))  }}
{{- $configSnippet = printf "%s\n%s" $configSnippet "http-request return status 204 content-type \"text/plain charset=UTF-8\" if METH_OPTIONS"  }}
{{- $configSnippet = trim $configSnippet }}
{{- end }}
{{- if $configSnippet }}
{{- $configSnippet = printf "%s\n" $configSnippet }}
haproxy.org/backend-config-snippet: {{ $configSnippet | toYaml }}
{{- end }}
{{- end }}
