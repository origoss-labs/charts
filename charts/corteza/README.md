# Corteza Helm Chart

A Helm chart for Corteza, a low-code platform that lets you build and iterate CRM, business process and other structured data apps fast, create intelligent business process workflows and connect with almost any data source.

* The Corteza platform is maintained by [Planet Crust](https://www.planetcrust.com/), its founder.
* The chart is community maintained, driven by [Origoss](https://origoss.com/).

The default installation comes with two example applications (CRM and Case Management) provided by Planet Crust; otherwise, it only includes the building blocks needed to create your own application.

This chart is ideal for quickly deploying the Corteza platform to Kubernetes cluster with optional configurations for specific Ingress controllers and databases.

## Installation

Since switching to [Zalando's Postgres Operator](https://github.com/zalando/postgres-operator.git), the Corteza chart must be installed in two steps. The reason for that is that the PostgreSQL database is now deployed by Zalando's operator using a Custom Resource, which must first be defined by the operator's chart.

### 1. Deploy Operator with CRDs

Disable the `postgresql` component in the `values.yaml`, then install the chart. As the operator spins up, it creates the necessary CRDs, allowing the deployment of the PostgreSQL database. Minimal example `values.yaml`:
``` yaml
# 01-values.yaml
postgresoperator:
  enabled: true

postgresql:
  enabled: false
externalDatabase:
  enabled: false
```

``` sh
helm install my-corteza corteza/corteza -f 01-values.yaml
```

### 2. Deploy the rest of the chart

After the CRDs and the operator are installed, the database can be enabled and deployed.

## Ingress configuration

### Prerequisites

You need an Ingress controlled installed in your Kubernetes cluster. Preferably, Nginx Ingress Controller.

### Google Cloud (GCP) configuration

This configuration is tailored for clusters running on Google Cloud Platform (GCP) and uses the Google Cloud Ingress controller. Select this setup if your cluster is hosted on GCP. Note that the `server.ingress.controller` must be set to `gcp` in order to use the Google Cloud Ingress controller.

```yaml
global:
  domain: &domain "yourdomain.com"

server:
  replicaCount: 1
  name: server
  ingress:
    enabled: true
    controller: "gcp"
    hosts:
      - host: *domain
        paths:
          - path: /
            pathType: ImplementationSpecific
    tls:
     - secretName: corteza-test-tls
       hosts:
         - *domain
    frontendConfig:
      redirectToHttps:
        enabled: true
        responseCodeName: MOVED_PERMANENTLY_DEFAULT
```

### Generic, NGINX Ingress controller configuration

This configuration is designed for generic use across different cloud providers and is compatible with the NGINX Ingress controller.

```yaml
global:
  domain: &domain "yourdomain.com"

server:
  replicaCount: 1
  name: server
  ingress:
    enabled: true
    controller: regular
    className: ""
    annotations:
      kubernetes.io/ingress.class: nginx
      kubernetes.io/tls-acme: "true"
    hosts:
      - host: *domain
        paths:
          - path: /
            pathType: ImplementationSpecific
    tls:
     - secretName: corteza-test-tls
       hosts:
         - *domain
```

## Corredor

[Corredor](https://github.com/cortezaproject/corteza-server-corredor) is an automation script runner and bundler. It loads and processes provided automation scripts and serves them to the Corteza server backend.

Corredor is disabled by default. To enable it in the chart, use the below configuration.

```yaml
corredor:
  enabled: true
  name: corredor
  nameOverride: ""
  image:
    repository: cortezaproject/corteza-server-corredor
    tag: "2024.9.0"
    imagePullPolicy: IfNotPresent
  persistence:
    enabled: true
    storageClass: ""
    accessModes:
      - ReadWriteOnce
    size: 5Gi
```

## PostgreSQL

Persistance is a key element of Corteza. It uses PostgreSQL managed by [Zalando's Postgres Operator](https://github.com/zalando/postgres-operator.git) to store data. To manage your own database in the cluster use the below configuration. Enabling `externalDatabase` overrides the `postgresql` configuration.

> **IMPORTANT**
>
> The Postgres Operator deploys the PostgreSQL database using a Custom Resource Definition. When installing the chart for the first time, disable the `postgresql` component in the `values.yaml`. As the operator spins up, it creates the necessary CRDs, allowing the deployment of the PostgreSQL database. After enabling the database in the values file, run `helm upgrade`.

```yaml
postgresql:
  enabled: true
  name: postgresql
  version: "17"
  volume:
    size: 8Gi
    storageClass: ""
  instances: 1
externalDatabase:
  enabled: false
```

## External Database

You may want to have Corteza connect to an external database rather than installing one inside your cluster. Typical reasons for this are to use a managed database service, or to share a common database server for all your applications. To achieve this, the chart allows you to specify credentials for an external database with the externalDatabase parameter.

The chart constructs the connection string to the database using environmental variables, provided in the `values.yaml` below.

```yaml
externalDatabase:
  enabled: true
  auth:
    username: ""
    password: ""
    host: ""
    database: ""
```

## Parameters

### Global variables

| Name                  | Description                                                    | Value  |
| --------------------- | -------------------------------------------------------------- | ------ |
| `global.domain`       | The domain of the installed Corteza application.               | `""`   |
| `global.storageClass` | The storage class for persistent volumes.                      | `""`   |
| `global.insecure`     | Whether to enable insecure communication with the application. | `true` |

### Server configuration

| Name                                                 | Description                                                                                                                                                                                                                                                                                                 | Value                          |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| `server.environment`                                 | The environment to run the server in (development, production, etc.).                                                                                                                                                                                                                                       | `development`                  |
| `server.name`                                        | The name of the server service.                                                                                                                                                                                                                                                                             | `server`                       |
| `server.nameOverride`                                | The name to override the default name.                                                                                                                                                                                                                                                                      | `""`                           |
| `server.auth.development`                            | When enabled, corteza reloads template before every execution. Enable this for debugging or when developing auth templates.                                                                                                                                                                                 | `true`                         |
| `server.webConsole.enabled`                          | Enable web console. When running in dev environment, web console is enabled by default.                                                                                                                                                                                                                     | `true`                         |
| `server.apiGateway.profiler.global`                  | When enabled, profiler is enabled for all routes.                                                                                                                                                                                                                                                           | `true`                         |
| `server.image.repository`                            | The repository of the image used to deploy the Corteza application.                                                                                                                                                                                                                                         | `cortezaproject/corteza`       |
| `server.image.pullPolicy`                            | The pull policy for the image used to deploy the Corteza application.                                                                                                                                                                                                                                       | `IfNotPresent`                 |
| `server.image.tag`                                   | The tag of the image used to deploy the Corteza application. Overrides the image tag whose default is the chart appVersion.                                                                                                                                                                                 | `2024.9.0`                     |
| `server.service.type`                                | The service type used to expose the Corteza application.                                                                                                                                                                                                                                                    |
| `server.service.annotations`                         | Annotations of the server's service .                                                                                                                                                                                                                                                    | `{}`                    |
| `server.service.port`                                | The port on which the server service listens.                                                                                                                                                                                                                                                               | `80`                           |
| `server.service.containerPort`                       | The port on which the server container listens.                                                                                                                                                                                                                                                             | `80`                           |
| `server.serviceAccount.create`                       | Whether a service account should be created.                                                                                                                                                                                                                                                                | `true`                         |
| `server.serviceAccount.annotations`                  | The annotations to add to the service account.                                                                                                                                                                                                                                                              | `{}`                           |
| `server.serviceAccount.name`                         | The name of the service account to use. If not set and create is true, a name is generated using the fullname template                                                                                                                                                                                      | `""`                           |
| `server.ingress.enabled`                             | Whether to enable ingress.                                                                                                                                                                                                                                                                                  | `false`                        |
| `server.ingress.controller`                          | The controller to use for ingress. Value can be either regular or gcp.                                                                                                                                                                                                                                      | `regular`                      |
| `server.ingress.className`                           | The class name to use for ingress.                                                                                                                                                                                                                                                                          | `""`                           |
| `server.ingress.annotations`                         | Annotations to use for the created ingress. For NGINX add: kubernetes.io/ingress.class: nginx                                                                                                                                                                                                               | `nil`                          |
| `server.ingress.hosts[0].host`                       | The hosts to use for ingress.                                                                                                                                                                                                                                                                               | `""`                           |
| `server.ingress.hosts[0].paths[0].path`              | The paths to use for ingress.                                                                                                                                                                                                                                                                               | `/`                            |
| `server.ingress.hosts[0].paths[0].pathType`          | The path type for the ingress.                                                                                                                                                                                                                                                                              | `ImplementationSpecific`       |
| `server.ingress.tls`                                 | TLS configuration for the ingress.                                                                                                                                                                                                                                                                          | `[]`                           |
| `server.ingress.gcp.backendConfig`                   | The backend configuration for Google Cloud Ingress.                                                                                                                                                                                                                                                         | `{}`                           |
| `server.ingress.gcp.frontendConfig`                  | The frontend configuration for Google Cloud Ingress.                                                                                                                                                                                                                                                        | `{}`                           |
| `server.ingress.gcp.managedCertificate.create`       | When enabled Google Cloud's managed certificate service will be used for the domain.                                                                                                                                                                                                                        | `true`                         |
| `server.ingress.gcp.managedCertificate.extraDomains` | List with the domains that should be handled by Google.                                                                                                                                                                                                                                                     | `[]`                           |
| `server.assets.path`                                 | Corteza will directly serve these assets (static files). When empty path is set (default value), embedded files are used.                                                                                                                                                                                   | `""`                           |
| `server.assets.auth.path`                            | Path to js, css, images and template source files. When corteza starts, if path exists it tries to load template files from it. When empty path is set (default value), embedded files are used.                                                                                                            | `""`                           |
| `server.locale.enabled`                              | When enabled locale languages configuration will take place.                                                                                                                                                                                                                                                | `false`                        |
| `server.locale.languages`                            | List of comma delimited languages (language tags) to enable. In case when an enabled language can not be loaded, error is logged.                                                                                                                                                                           | `""`                           |
| `server.locale.enableDevelopmentMode`                | When enabled, Corteza reloads language files on every request Enable this for debugging or developing.                                                                                                                                                                                                      | `true`                         |
| `server.locale.path`                                 | Path to locale files.                                                                                                                                                                                                                                                                                       | `/mnt/corteza/corteza-locale/` |
| `server.log.debug`                                   | Disables json format for logging and enables more human-readable output with colors.                                                                                                                                                                                                                        | `false`                        |
| `server.log.level`                                   | Minimum logging level. If set to "warn", Levels warn, error, dpanic panic and fatal will be logged. Recommended value for production: warn. Possible values: debug, info, warn, error, dpanic, panic, fatal.                                                                                                | `warn`                         |
| `server.log.stacktraceLevel`                         | Include stack-trace when logging at a specified level or below. Disable for production. Possible values: debug, info, warn, error, dpanic, panic, fatal.                                                                                                                                                    | `error`                        |
| `server.log.includeCaller`                           | Set to true to see where the logging was called from. Disable for production.                                                                                                                                                                                                                               | `false`                        |
| `server.log.filter`                                  | Log filtering rules by level and name (log-level:log-namespace). Please note that level (LOG_LEVEL) is applied before filter and it affects the final output! Leave unset for production. https://docs.cortezaproject.org/corteza-docs/2024.9/devops-guide/references/configuration/server.html#_log_filter | `nil`                          |
| `server.log.components.http.request`                 | Log HTTP requests.                                                                                                                                                                                                                                                                                          | `false`                        |
| `server.log.components.http.response`                | Log HTTP responses.                                                                                                                                                                                                                                                                                         | `false`                        |
| `server.log.components.rbac`                         | Log RBAC related events and actions.                                                                                                                                                                                                                                                                        | `false`                        |
| `server.log.components.locale`                       | Log locale related events and actions.                                                                                                                                                                                                                                                                      | `false`                        |
| `server.log.components.auth`                         | Enable extra logging for authentication flows                                                                                                                                                                                                                                                               | `false`                        |
| `server.log.components.actionLog.enabled`            | Enable action log.                                                                                                                                                                                                                                                                                          | `false`                        |
| `server.log.components.actionLog.debug`              | Enable debug logging for action log.                                                                                                                                                                                                                                                                        | `false`                        |
| `server.log.components.actionLog.workflowFunctions`  | Enable logging workflow functions.                                                                                                                                                                                                                                                                          | `false`                        |
| `server.log.components.apiGateway.enabled`           | Enable extra logging API Gateway related events and actions.                                                                                                                                                                                                                                                | `false`                        |
| `server.log.components.apiGateway.requestBody`       | Enable incoming request body output in logs.                                                                                                                                                                                                                                                                | `false`                        |
| `server.log.components.apiGateway.proxy.debug`       | Enable full debug log on requests / responses - warning, includes sensitive data.                                                                                                                                                                                                                           | `false`                        |
| `server.persistence.enabled`                         | Enable persistent storage for the intalled Corteza instance.                                                                                                                                                                                                                                                | `true`                         |
| `server.persistence.storageClass`                    | The storage class for the persistent volume.                                                                                                                                                                                                                                                                | `""`                           |
| `server.persistence.accessModes`                     | The access modes for the persistent volume.                                                                                                                                                                                                                                                                 | `["ReadWriteOnce"]`            |
| `server.persistence.size`                            | The size of the persistent volume.                                                                                                                                                                                                                                                                          | `5Gi`                          |
| `server.autoscaling.enabled`                         | Enable autoscaling for the installed Corteza deployment.                                                                                                                                                                                                                                                    | `false`                        |
| `server.autoscaling.minReplicas`                     | The minimum number of replicas for the installed Corteza deployment.                                                                                                                                                                                                                                        | `1`                            |
| `server.autoscaling.maxReplicas`                     | The maximum number of replicas for the installed Corteza deployment.                                                                                                                                                                                                                                        | `100`                          |
| `server.autoscaling.targetCPUUtilizationPercentage`  | The target CPU utilization percentage for autoscaling.                                                                                                                                                                                                                                                      | `80`                           |
| `server.replicaCount`                                | The required number of replicas for the installed Corteza deployment. replicaCount is only used when autoscaling is not enabled.                                                                                                                                                                            | `1`                            |
| `server.extraEnv`                                    | An array to add extra env vars.                                                                                                                                                                                                                                                                             | `{}`                           |
| `server.initContainers`                              | Add additional init containers to the Corteza server pods.                                                                                                                                                                                                                                                  | `[]`                           |
| `server.imagePullSecrets`                            | Specify docker-registry secret names as an array. The specified secrets MUST be in the same namespace.                                                                                                                                                                                                      | `[]`                           |
| `server.podAnnotations`                              | Annotations for the Corteza pods.                                                                                                                                                                                                                                                                           | `{}`                           |
| `server.podSecurityContext`                          | Security context for the Corteza pods.                                                                                                                                                                                                                                                                      | `{}`                           |
| `server.securityContext`                             | Security context for the Corteza container.                                                                                                                                                                                                                                                                 | `{}`                           |
| `server.resources`                                   | Resource limits and requests for the Corteza server pods.                                                                                                                                                                                                                                                   | `{}`                           |
| `server.nodeSelector`                                | Node labels for pod assignment.                                                                                                                                                                                                                                                                             | `{}`                           |
| `server.tolerations`                                 | Tolerations for pod assignment.                                                                                                                                                                                                                                                                             | `[]`                           |
| `server.affinity`                                    | Affinity settings for pod assignment.                                                                                                                                                                                                                                                                       | `{}`                           |

### Corredor configuration

| Name                                                  | Description                                                                                                                       | Value                                    |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| `corredor.enabled`                                    | Enable the installation of the Corredor automation script runner and bundler.                                                     | `false`                                  |
| `corredor.name`                                       | Name of the Corredor deployment.                                                                                                  | `corredor`                               |
| `corredor.nameOverride`                               | The name to override the default name.                                                                                            | `""`                                     |
| `corredor.image.repository`                           | Image repository for the Corredor container image.                                                                                | `cortezaproject/corteza-server-corredor` |
| `corredor.image.tag`                                  | Image tag for the Corredor container image.                                                                                       | `2024.9.0`                               |
| `corredor.image.imagePullPolicy`                      | Image pull policy for the Corredor container image.                                                                               | `IfNotPresent`                           |
| `corredor.service.type`                               | Service type for the Corredor service.                                                                                            | `ClusterIP`                              |
| `corredor.service.port`                               | Service port for the Corredor service.                                                                                            | `80`                                     |
| `corredor.service.containerPort`                      | Service port for the Corredor container.                                                                                          | `80`                                     |
| `corredor.serviceAccount.create`                      | Specifies whether a service account should be created.                                                                            | `true`                                   |
| `corredor.serviceAccount.annotations`                 | Annotations to add to the service account.                                                                                        | `{}`                                     |
| `corredor.serviceAccount.name`                        | The name of the service account to use. If not set and create is true, a name is generated using the fullname template.           | `""`                                     |
| `corredor.persistence.enabled`                        | Enable persistent storage for the intalled Corredor instance.                                                                     | `true`                                   |
| `corredor.persistence.storageClass`                   | The storage class for the persistent volume.                                                                                      | `""`                                     |
| `corredor.persistence.accessModes`                    | The access modes for the persistent volume.                                                                                       | `["ReadWriteOnce"]`                      |
| `corredor.persistence.size`                           | The size of the persistent volume.                                                                                                | `5Gi`                                    |
| `corredor.autoscaling.enabled`                        | Enable autoscaling for the installed corredor deployment.                                                                         | `false`                                  |
| `corredor.autoscaling.minReplicas`                    | The minimum number of replicas for the installed corredor deployment.                                                             | `1`                                      |
| `corredor.autoscaling.maxReplicas`                    | The maximum number of replicas for the installed corredor deployment.                                                             | `100`                                    |
| `corredor.autoscaling.targetCPUUtilizationPercentage` | The target CPU utilization percentage for autoscaling.                                                                            | `80`                                     |
| `corredor.replicaCount`                               | The required number of replicas for the installed Corredor deployment. replicaCount is only used when autoscaling is not enabled. | `1`                                      |
| `corredor.initContainers`                             | Add additional init containers to the Corredorx pods.                                                                             | `[]`                                     |
| `corredor.imagePullSecrets`                           | Specify docker-registry secret names as an array. The specified secrets MUST be in the same namespace.                            | `[]`                                     |
| `corredor.podAnnotations`                             | Annotations for the Corredor pods.                                                                                                | `{}`                                     |
| `corredor.podSecurityContext`                         | Security context for the Corredor pods.                                                                                           | `{}`                                     |
| `corredor.securityContext`                            | Security context for the Corredor container.                                                                                      | `{}`                                     |
| `corredor.resources`                                  | Resource limits and requests for the Corredor server pods.                                                                        | `{}`                                     |
| `corredor.nodeSelector`                               | Node labels for pod assignment.                                                                                                   | `{}`                                     |
| `corredor.tolerations`                                | Tolerations for pod assignment.                                                                                                   | `[]`                                     |
| `corredor.affinity`                                   | Affinity settings for pod assignment.                                                                                             | `{}`                                     |

### PostgreSQL configuration

Configuring an external database overrides postgresql configuration.

| Name                                                    | Description                                     | Value        |
| ------------------------------------------------------- | ----------------------------------------------- | ------------ |
| `postgresql.enabled`                                    | Enable the installation of PostgreSQL database. | `true`       |
| `postgresql.name`                                       | The name of the PostgreSQL database.            | `postgresql` |
| `postgresql.version`                                    | Major version of the PostgreSQL database.       | `17`         |
| `postgresql.volume.size`                                | Size of the PostgreSQL database storage.        | `8Gi`        |
| `postgresql.volume.storageClass`                        | Storage class for the PV of the database.       | `""`         |
| `postgresql.instances`                                  | Number of database instances.                   | `1`          |

### External database

Overrides postgresql configuration.

| Name                                         | Description                                                                            | Value   |
| -------------------------------------------- | -------------------------------------------------------------------------------------- | ------- |
| `externalDatabase.enabled`                   | Enable using an external PostgresSQL database.                                         | `false` |
| `externalDatabase.auth.username`             | The username used to log in to the external database.                                  | `""`    |
| `externalDatabase.auth.password`             | The password used to log in to the external database.                                  | `""`    |
| `externalDatabase.auth.host`                 | The address of the external PostgreSQL database.                                       | `""`    |
| `externalDatabase.auth.database`             | The name of the database to be used by corteza.                                        | `""`    |
