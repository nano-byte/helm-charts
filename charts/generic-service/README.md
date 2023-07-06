# Generic Service Helm Chart

This Helm chart simplifies deploying a typical "80% case" service on Kubernetes. It takes care of creating common [Resources](#resources) such as `Deployment`, `Service` and `Ingress`. It also provides optional support for:

- [nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/), [Contour](https://projectcontour.io/) or [Istio](https://istio.io/) for routing
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) for monitoring
- [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator) or [Jaeger Operator](https://www.jaegertracing.io/docs/latest/operator/) for tracing
- [Flagger](https://flagger.app/) and [Argo Rollouts](https://argoproj.github.io/argo-rollouts/) for canary and blue-green deployments

The [Generic Service Grafana Dashboard](https://grafana.com/grafana/dashboards/14759) is a useful companion to this chart.

## Getting started

This chart is most commonly used as a dependency instead of installing it directly. You can reference it in your chart by adding this to your `Chart.yaml`:

```yaml
dependencies:
  - name: generic-service
    version: ~1.7.0
    repository: https://helm.nano-byte.net
    alias: app
```

You can then add static configuration to your `values.yaml` like this:

```yaml
app:
  image:
    repository: myservice
    tag: 1.2.3
```

## Values

| Value                               | Default                     | Description                                                                                              |
| ----------------------------------- | --------------------------- | -------------------------------------------------------------------------------------------------------- |
| `name`                              | Release Name                | The name of the service (used for `app.kubernetes.io/name` label)                                        |
| `fullname`                          | Release Name (+ `name`)     | The name of the service instance (used for resource names and `app.kubernetes.io/instance` label)        |
| `version`                           | same as `image.tag`         | The version of the service (used for `app.kubernetes.io/version` label)                                  |
| `image.registry`                    | `docker.io`                 | The Registry containing the image to run                                                                 |
| `image.repository`                  | __required__                | The name of the image image to run (without the Registry)                                                |
| `image.tag`                         | __required__                | The tag of the image to run; start with `@` for digest instead of tag (e.g., `@sha256:abc...`)           |
| `image.pullPolicy`                  | `IfNotPresent`              | Set to `Always` to try to pull new versions of the image                                                 |
| `image.pullSecret`                  |                             | Name of the Kubernetes Secret providing credentials for pulling the image                                |
| `securityContext.pod`               | `{}`                        | Security context to use for the pod                                                                      |
| `securityContext.container`         | `{}`                        | Security context to use for the container                                                                |
| `command`                           | `[]`                        | Overrides the command to launch in the image                                                             |
| `args`                              | `[]`                        | The command-line arguments passed to the service                                                         |
| `env`                               | `{}`                        | Environment variables passed to the service as a key-value map                                           |
| `envFrom`                           | `{}`                        | Environment variables passed to the service from other sources (e.g., `secretKeyRef`)                    |
| `config`                            | `{}`                        | YAML/JSON configuration to be mounted as a file in the container                                         |
| `configMountPath`                   | `/config/config.yaml`       | The file path in the container to mount the data from `config` into (exposed via `$CONFIG_FILE`)         |
| `additionalConfigs`                 | `[]`                        | Additional `ConfigMap`s with key named `data.yaml` to be mounted (paths appended to `$CONFIG_FILE`)      |
| `startupProbe`                      |                             | Probe that waits for the service to initially start up                                                   |
| `livenessProbe`                     |                             | Probe that causes the service to be restarted when failing                                               |
| `readinessProbe`                    |                             | Probe that prevents the service from receiving traffic when failing                                      |
| `maxShutdownSeconds`                | `30`                        | The number of seconds the pod has to shutdown before it is terminated                                    |
| `labels`                            | `{}`                        | Additional labels to set on all generated resources                                                      |
| `annotations`                       | `{}`                        | Additional annotations to set on the `Pod` controller and `Pod`s                                         |
| `resources.requests.memory`         | `64Mi`                      | The amount of memory requested for the service (recommendation: slightly higher than average usage)      |
| `resources.requests.cpu`            | `10m`                       | The number of CPU cores requested for the service                                                        |
| `resources.limits.memory`           | `96Mi`                      | The maximum amount of memory the service may use (recommendation: slightly higher than worst-case usage) |
| `resources.limits.cpu`              | `2000m`                     | The maximum number of CPU cores the service may use                                                      |
| `rollout.controller`                | `Deployment`                | The type of `Pod` controller to create (`Deployment`, `StatefulSet`, `DaemonSet` or `ArgoRollout`)       |
| `rollout.strategy`                  | `RollingUpdate`             | The rollout strategy (`RollingUpdate`, `Recreate`, `OnDelete`, `Canary` or `BlueGreen`)                  |
| `rollout.autoPromotion`             | `true`                      | Automatically promote rollouts (if `rollout.strategy` is `BlueGreen` and `rollout.flagger` if `false`)   |
| `rollout.flagger`                   | `false`                     | Use Flagger to control rollouts (`rollout.controller` must be `Deployment` or `StatefulSet`)             |
| `rollout.analysis`                  | req. for Canary or Flagger  | Flagger or Argo Rollouts analysis for automatic `Canary` or `BlueGreen` promotion                        |
| `replicas`                          | `1`                         | The number of instances of the service to run (set at least `2` for Pod Disruption Budget)               |
| `autoscaling.enabled`               | `false`                     | Enables automatic starting of additional instances                                                       |
| `autoscaling.maxReplicas`           | `3`                         | The maximum number of instances to run (must be larger than `replicas`)                                  |
| `autoscaling.metric.type`           | `Resource`                  | The type of metric to use for scaling (`Resource`, `Pods`, `Object` or `External`)                       |
| `autoscaling.metric.name`           | `cpu`                       | The name of the metric to use for scaling                                                                |
| `autoscaling.metric.object`         | req. if `type` = `Object`   | Reference to the Kubernetes object the metric describes                                                  |
| `autoscaling.metric.selector`       | `{}`                        | Labels for selecting the metric as a key-value map                                                       |
| `autoscaling.targetValue`           | `80`                        | The desired value of the metric to achieve through scaling (e.g., CPU utilization in percent)            |
| `autoscaling.behavior`              | `{}`                        | Scaling behavior configuration (see `HorizontalPodAutoscalerBehavior`)                                   |
| `scheduling.priority`               |                             | The name of the `PriorityClass` to use for scheduling this service                                       |
| `scheduling.nodeSelector`           | `{}`                        | Labels to select nodes this service may be run on                                                        |
| `scheduling.nodePeferences`         | `{}`                        | Sets of label values to select nodes this service should be run on if possible                           |
| `scheduling.nodeExclusions`         | `{}`                        | Sets of label values to select nodes this service must not run on                                        |
| `scheduling.podAffinity`            | `{}`                        | Labels to select other pods this service should share nodes with if possible                             |
| `scheduling.enforceReplicaSpread`   | `false`                     | Make even spread of replicas across nodes mandatory                                                      |
| `persistence.enabled`               | `false`                     | Enables persistent storage for the service                                                               |
| `persistence.storageClass`          |                             | The type of disk to use for storage instead of the cluster default                                       |
| `persistence.accessModes`           | `[ReadWriteOnce]`           | The support access modes the volume can be mounted with                                                  |
| `persistence.size`                  | `1G`                        | The size of the persistent volume to create for the service                                              |
| `persistence.mountPath`             | __required if enabled__     | The mount path for the storage inside the container                                                      |
| `secrets.SECRET_NAME.mountPath`     | __required if used__        | The mount path for the `Secret` named `SECRET_NAME` (supports templating) inside the container           |
| `secrets.SECRET_NAME.subPath`       |                             | The path of a single file in the `Secret` named `SECRET_NAME` to mount; leave empty to mount all files   |
| `secrets.SECRET_NAME.files`         |                             | Map of file names to base64-encoded content; leave empty to reference existing `Secret`                  |
| `additionalMounts.PATH.name`        | __required if used__        | The name of an additional volume to be mounted at `PATH` inside the container                            |
| `additionalMounts.PATH.*`           | __required if used__        | The configuration for the additional volume (e.g., `emptyDir: {}`)                                       |
| `ingress.enabled`                   | `false`                     | Enables ingress into the service (either cluster-internal or public)                                     |
| `ingress.port`                      | `80`                        | The container port ingress traffic is routed to                                                          |
| `ingress.protocol`                  | `http`                      | The internal protocol used for ingress (e.g., `http`, `https`, `grpc` or `grpcs`)                        |
| `ingress.timeoutSeconds`            |                             | Number of seconds after which to timeout waiting for response from service                               |
| `ingress.domains`                   | `[]`                        | The public domain names under which the service is exposed (leave empty for cluster-internal only)       |
| `ingress.paths`                     | `[]`                        | HTTP path prefixes to accept ingress traffic for (leave empty to accept traffic for any path)            |
| `ingress.tls.enabled`               | `false`                     | Enables TLS termination at the ingress (not applicable if `ingress.istio.enabled`)                       |
| `ingress.tls.secret`                | `{{ .Release.Name }}-tls`   | The name of the `Secret` holding the TLS private key (not applicable if `ingress.istio.enabled`)         |
| `ingress.cors.enabled`              | `false`                     | Enables CORS (only applicable if `ingress.class` is `nginx` or `ingress.istio.enabled` is `true`)        |
| `ingress.cors.allowOrigin`          | `[]`                        | List of origins allowed to access the ingress via CORS; leave empty to allow any                         |
| `ingress.cors.allowMethods`         | `[GET]`                     | List of HTTP methods allowed to access the ingress via CORS                                              |
| `ingress.cors.allowHeaders`         | `[Content-Type]`            | List of HTTP headers that can be used when requesting the ingress via CORS                               |
| `ingress.cors.allowCredentials`     | `true`                      | Indicates whether the caller is allowed to send the actual request (not the preflight) using credentials |
| `ingress.cors.exposeHeaders`        | `[]`                        | List of HTTP headers that the browsers are allowed to access                                             |
| `ingress.class`                     |                             | The ingress controller to use (not applicable if `ingress.istio.enabled`)                                |
| `ingress.annotations`               | `{}`                        | Annotations for `Ingress` resource (not applicable if `ingress.istio.enabled`)                           |
| `ingress.headless`                  | `false`                     | Creates an additional `Service` with the suffix `-headless` that directly exposes Pod IPs                |
| `ingress.headlessExposesAll`        | `false`                     | Exposes all replicas, including unready ones, via the `-headless` `Service`                              |
| `ingress.nodeLocal`                 | `false`                     | Creates an additional `Service` with the suffix `-local` that only routes to pods on the same node       |
| `ingress.additionalSelectors`       | `{}`                        | Additional label selectors used to restrict the `Pod`s selected by the `Service`                         |
| `ingress.istio.enabled`             | `false`                     | Use Istio `VirtualService` instead of Kubernetes `Ingress` resource                                      |
| `ingress.istio.gateways`            | `[]`                        | The names of the Istio `Gateway`s to use                                                                 |
| `ingress.istio.httpHeaders`         | `{}`                        | Custom HTTP response headers                                                                             |
| `ingress.istio.retries`             | `{}`                        | [Istio retry policy](https://istio.io/docs/reference/config/networking/virtual-service/#HTTPRetry)       |
| `ingress.extra.*.class`             | same as `ingress.class`     | Additional ingress controller to use (not applicable if `ingress.istio.enabled`)                         |
| `ingress.extra.*.port`              | same as `ingress.port`      | Additional container port ingress traffic is routed to (not applicable if `ingress.istio.enabled`)       |
| `ingress.extra.*.protocol`          | `http`                      | The protocol used for the port (e.g., `http` or `grpc`)                                                  |
| `ingress.extra.*.timeoutSeconds`    |                             | Number of seconds after which to timeout waiting for response from service                               |
| `ingress.extra.*.domains`           | `[]`                        | The public domain names under which the port is exposed (leave empty for cluster-internal only)          |
| `ingress.extra.*.paths`             | `[]`                        | HTTP path prefixes to accept ingress traffic for (leave empty to accept traffic for any path)            |
| `ingress.extra.*.tls.enabled`       | `false`                     | Enables TLS termination at the ingress                                                                   |
| `ingress.extra.*.tls.secret`        | Release Name + `*` + `-tls` | The name of the `Secret` holding the TLS private key                                                     |
| `ingress.extra.*.annotations`       | `{}`                        | Additional annotations, merged with `ingress.annotations` (use string `nil` to unset existing values)    |
| `netpol.enabled`                    | `false`                     | Apply network policies for the `Pod`s                                                                    |
| `netpol.ingress`                    | Allow from same namespace   | Ingress network policy rules to apply                                                                    |
| `netpol.egress`                     | `[]`                        | Egress network policy rules to apply                                                                     |
| `tracing.enabled`                   | `false`                     | Enables tracing with OpenTelemetry or Jaeger agent (injected as sidecar)                                 |
| `tracing.probability`               | `1`                         | Probability of any single trace being sampled; can be overridden for incoming requests e.g. via Istio    |
| `tracing.class`                     |                             | Custom value to set for tracing sidecar injection annotations                                            |
| `monitoring.enabled`                | `false`                     | Use Prometheus for monitoring / metrics scraping                                                         |
| `monitoring.port`                   | `9100`                      | The port to be scraped for monitoring data                                                               |
| `monitoring.path`                   | `/metrics`                  | The path to be scraped for monitoring data                                                               |
| `monitoring.interval`               | `1m`                        | The interval at which monitoring data is scraped                                                         |
| `alerting.enabled`                  | `false`                     | Deploys Prometheus alert rule for issues like like unavailable pods or high memory use                   |
| `alerting.pod.maxStartupSeconds`    | `120`                       | The maximum amount of time a Pod is allowed to take for startup                                          |
| `alerting.pod.maxAgeSeconds`        |                             | The maximum allowed age of a `Pod` in seconds (useful to ensure regular deployments)                     |
| `alerting.memory.enabled`           | `true`                      | Enables alerts relating to memory usage                                                                  |
| `alerting.memory.maxUsageFactor`    | `0.9`                       | The maximum usage factor of the memory limit (between `0` and `1`)                                       |
| `alerting.memory.quotaBufferFactor` | `1.0`                       | Multiplied with `resources.*.memory` to determine minimum allowed unused memory quota in namespace       |
| `alerting.cpu.sampleInterval`       | `1m`                        | The time interval in which to measure CPU usage                                                          |
| `alerting.cpu.maxThrottleFactor`    | `0.01`                      | The maximum fraction of the container's execution time during which it experiences CPU throttling        |
| `alerting.cpu.quotaBufferFactor`    | `1.0`                       | Multiplied with `resources.*.cpu` to determine minimum allowed unused CPU quota in namespace             |
| `alerting.http.sampleInterval`      | `20m`                       | The time interval in which to measure HTTP responses for triggering alerts                               |
| `alerting.http.referenceInterval`   | `1w`                        | The time interval to to compare with the sample interval to detect changes                               |
| `alerting.http.maxSlowdown`         | `2.5`                       | The maximum HTTP response slowdown in the sample interval compared to the reference interval             |
| `alerting.http.max4xxRatio`         | `2.5`                       | The maximum HTTP 4xx ratio increase in the sample interval compared to the reference interval            |
| `alerting.http.max5xxCount`         | `0`                         | The maximum number of HTTP 5xx responses in the sample interval                                          |
| `alerting.grpc.requestsMetric`      | `grpc_server_handled_total` | The name of the Prometheus metric counting gRPC requests                                                 |
| `alerting.grpc.sampleInterval`      | `20m`                       | The time interval in which to measure gRPC responses                                                     |
| `alerting.grpc.referenceInterval`   | `1w`                        | The time interval to to compare with the sample interval to detect changes                               |
| `alerting.grpc.maxErrorRatio`       | `2.5`                       | The maximum gRPC error ratio increase in the sample interval compared to the reference interval          |
| `alerting.grpc.maxCriticalErrors`   | `0`                         | The maximum number of critical gRPC errors responses in the sample interval                              |
| `alerting.grpc.criticalCodes`       | `[Internal, Unimplemented]` | Which gRPC status codes are considered critical errors                                                   |
| `alerting.custom.*.metric`          | __required if used__        | The name of the Prometheus metric exposed by the service                                                 |
| `alerting.custom.*.metricLabels`    | `{}`                        | Labels to use for filtering the metric                                                                   |
| `alerting.custom.*.aggregate`       | __required if used__        | The aggregate function to use to combine metric values from multiple replicas (e.g., `max` or `sum`)     |
| `alerting.custom.*.increaseOver`    |                             | A sliding window in which to calculate the increase of the metric (e.g., `10m`)                          |
| `alerting.custom.*.averageOver`     |                             | A sliding window in which to calculate the average value of the metric (e.g., `10m`)                     |
| `alerting.custom.*.round`           | `false`                     | Round the result before evaluating the predicate                                                         |
| `alerting.custom.*.predicate`       | __required if used__        | An expression that triggers the alert when the metric fulfills it                                        |
| `alerting.custom.*.severity`        | `warning`                   | The severity of the alert                                                                                |
| `alerting.custom.*.topic`           |                             | The severity of the alert                                                                                |
| `alerting.custom.*.summary`         | __required if used__        | A short summary of the alert                                                                             |
| `alerting.custom.*.description`     | __required if used__        | A longer description of the alert; can include metric labels via templating                              |
| `sidecars`                          | `[]`                        | Additional sidecar containers to be added to the `Pod`                                                   |
| `sidecarTemplates`                  | `[]`                        | Strings to be templated providing additional sidecar containers to be added to the Pod                   |
| `rbac.roles`                        | `[]`                        | Namespace-specific Kubernetes RBAC Roles to assign to the service (supports templating)                  |
| `rbac.clusterRoles`                 | `[]`                        | Cluster-wide Kubernetes RBAC Roles to assign to the service (supports templating)                        |
| `global.alertLabels`                | `{}`                        | Additional labels to apply to alert rules                                                                |
| `global.grafana.url`                |                             | The URL of a Grafana instance with access to the service's metrics                                       |
| `global.grafana.dashboard`          | `qqsCbY5Zz`                 | The UID of the Grafana dashboard visualizing the service's metrics                                       |

## Environment variables

In addition to the environment variables specified via the `env` value, the following dynamic environment variables are automatically set:

| Value            | Description                                                                                                                                                                               |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `RELEASE_NAME`   | The name of the Helm Release                                                                                                                                                              |
| `POD_CONTROLLER` | The value of `rollout.controller`                                                                                                                                                         |
| `POD_NAME`       | The name of the Kubernetes pod                                                                                                                                                            |
| `POD_NAMESPACE`  | The namespace of the Kubernetes pod                                                                                                                                                       |
| `POD_IP`         | The cluster-internal IP of the Kubernetes pod                                                                                                                                             |
| `NODE_NAME`      | The name of the Kubernetes node the pod is running on                                                                                                                                     |
| `REPLICAS`       | The desired number of instances of the service that should be running (unset if `autoscaling.enabled` is `true`)                                                                          |
| `CONFIG_FILE`    | `:`-separated list of paths of mounted YAML/JSON config files                                                                                                                             |
| `PORT`           | The `ingress.port` (if `ingress.enabled` is `true`)                                                                                                                                       |
| `METRICS_PORT`   | The `monitoring.port` (if `monitoring.enabled` is `true`)                                                                                                                                 |
| `OTEL_*`         | [OpenTelemetry client configuration](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/sdk-environment-variables.md) (if `tracing.enabled` is `true`) |
| `JAEGER_*`       | [Jaeger client configuration](https://www.jaegertracing.io/docs/latest/client-features/) (if `tracing.enabled` is `true`)                                                                 |

## Resources

This Helm chart generates a number of Resources based on the specified [Values](#values). These resources reference each other:

![Resources](https://raw.githubusercontent.com/nano-byte/helm-charts/master/charts/generic-service/docs/resources.svg)

Legend:  
![Legend](https://raw.githubusercontent.com/nano-byte/helm-charts/master/charts/generic-service/docs/legend.svg)

**Deployment**  
Instructs Kubernetes to create a certain number of `Pod`s (`replicas`) running a specific `image`.

**Service**  
Created if `ingress.enabled` or `monitoring.enabled` is `true`.

**Ingress**  
Created if `ingress.enabled` is `true`, `ingress.domains` is not empty and `ingress.istio.enabled` is `false`.

**VirtualService**  
Created if `ingress.enabled` and `ingress.istio.enabled` are both `true`.

**PodMonitor**  
Created if `monitoring.enabled` is `true`.

**PrometheusRule**  
Created if `alerting.enabled` is `true`.

**ConfigMap**
Created if `config` is not empty.

**PersistentVolumeClaim**  
Created if `persistence.enabled` is `true`.

**ServiceAccount**  
Created if `rbac.roles` and/or `rbac.clusterRoles` is not empty.

**RoleBinding**  
Created once for every entry in `rbac.roles`.

**ClusterRoleBinding**  
Created once for every entry in `rbac.clusterRoles`.

**PodDisruptionBudget**  
Created if `replicas` is greater than `1`.

**HorizontalPodAutoscaler**  
Created if `autoscaling.enabled` is `true`.
