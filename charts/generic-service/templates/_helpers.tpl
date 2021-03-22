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
version: {{ .Values.image.tag }}
app.kubernetes.io/name: {{ include "generic-service.name" . }}
app.kubernetes.io/version: {{ .Values.image.tag }}
app.kubernetes.io/instance: {{ include "generic-service.fullname" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: '{{ .Chart.Name }}-{{ .Chart.Version }}'

{{- if .Values.labels }}
{{ .Values.labels | toYaml }}
{{- end }}

{{- end }}


{{ define "generic-service.istio" -}}

{{- if .Values.ingress.istio.gateways }}
gateways: {{ toYaml .Values.ingress.istio.gateways | nindent 2 }}
{{- end }}

hosts:
{{- if .Values.ingress.domains }}
{{ toYaml .Values.ingress.domains | indent 2 }}
{{- else }}
  - {{ include "generic-service.fullname" . }}
{{- end }}

{{- end }}


{{ define "generic-service.istio-filter" -}}
  destination_service_namespace="{{ .Release.Namespace }}", destination_service_name="{{ include "generic-service.fullname" . }}"
{{- end }}
