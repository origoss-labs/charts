# Corteza Helm Chart

A Helm chart for Corteza, a low-code platform that lets you build and iterate CRM, business process and other structured data apps fast, create intelligent business process workflows and connect with almost any data source.

* The Corteza platform is maintained by [Planet Crust](https://www.planetcrust.com/), its founder.
* The chart is community maintained, driven by [Origoss](https://origoss.com/).

The default installation comes with two example applications (CRM and Case Management) provided by Planet Crust; otherwise, it only includes the building blocks needed to create your own application.

This chart is ideal for quickly deploying the Corteza platform to Kubernetes cluster with optional configurations for specific Ingress controllers and databases.


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

Persistance is a key element of Corteza. It uses PostgreSQL to store data. To manage your own database in the cluster use the below configuration. Enabling `externalDatabase` overrides the `postgresql` configuration.

```yaml
postgresql:
  enabled: true
  auth:
    enablePostgresUser: true
    username: "corteza"
    password: "corteza"
    database: "corteza"
  architecture: standalone
  global:
    postgresql:
      service:
        ports:
          postgresql: "5432"
externalDatabase:
  enabled: false
```

## External Database

You may want to have Corteza connect to an external database rather than installing one inside your cluster. Typical reasons for this are to use a managed database service, or to share a common database server for all your applications. To achieve this, the chart allows you to specify credentials for an external database with the externalDatabase parameter.

The `existingSecret` secret should store the database DSN under the `existingSecretPasswordKey` key. This must exist before installing the chart.

```yaml
externalDatabase:
  enabled: true
  existingSecret: postgres-creds
  existingSecretPasswordKey: db-dsn
```

## Parameters

### Global variables

| Name                  | Description                                                    | Value  |
| --------------------- | -------------------------------------------------------------- | ------ |
| `global.domain`       | The domain of the installed Corteza application.               | `""`   |
| `global.storageClass` | The storage class for persistent volumes.                      | `""`   |
| `global.insecure`     | Whether to enable insecure communication with the application. | `true` |

### Server configuration

| Name                                                 | Description                                                                                                                                                                                                                                                                                     | Value                          |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| `server.environment`                                 | The environment to run the server in (development, production, etc.).                                                                                                                                                                                                                           | `development`                  |
| `server.name`                                        | The name of the server service.                                                                                                                                                                                                                                                                 | `server`                       |
| `server.nameOverride`                                | The name to override the default name.                                                                                                                                                                                                                                                          | `""`                           |
| `server.auth.development`                            | When enabled, corteza reloads template before every execution. Enable this for debugging or when developing auth templates.                                                                                                                                                                     | `true`                         |
| `server.webConsole.enabled`                          | Enable web console. When running in dev environment, web console is enabled by default.                                                                                                                                                                                                         | `true`                         |
| `server.apiGateway.profiler.global`                  | When enabled, profiler is enabled for all routes.                                                                                                                                                                                                                                               | `true`                         |
| `server.image.repository`                            | The repository of the image used to deploy the Corteza application.                                                                                                                                                                                                                             | `cortezaproject/corteza`       |
| `server.image.pullPolicy`                            | The pull policy for the image used to deploy the Corteza application.                                                                                                                                                                                                                           | `IfNotPresent`                 |
| `server.image.tag`                                   | The tag of the image used to deploy the Corteza application. Overrides the image tag whose default is the chart appVersion.                                                                                                                                                                     | `2024.9.0`                     |
| `server.service.type`                                | The service type used to expose the Corteza application.                                                                                                                                                                                                                                        | `ClusterIP`                    |
| `server.service.port`                                | The port on which the server service listens.                                                                                                                                                                                                                                                   | `80`                           |
| `server.service.containerPort`                       | The port on which the server container listens.                                                                                                                                                                                                                                                 | `80`                           |
| `server.serviceAccount.create`                       | Whether a service account should be created.                                                                                                                                                                                                                                                    | `true`                         |
| `server.serviceAccount.annotations`                  | The annotations to add to the service account.                                                                                                                                                                                                                                                  | `{}`                           |
| `server.serviceAccount.name`                         | The name of the service account to use. If not set and create is true, a name is generated using the fullname template                                                                                                                                                                          | `""`                           |
| `server.ingress.enabled`                             | Whether to enable ingress.                                                                                                                                                                                                                                                                      | `false`                        |
| `server.ingress.controller`                          | The controller to use for ingress. Value can be either regular or gcp.                                                                                                                                                                                                                          | `regular`                      |
| `server.ingress.className`                           | The class name to use for ingress.                                                                                                                                                                                                                                                              | `""`                           |
| `server.ingress.annotations`                         | Annotations to use for the created ingress. For NGINX add: kubernetes.io/ingress.class: nginx                                                                                                                                                                                                   | `nil`                          |
| `server.ingress.hosts[0].host`                       | The hosts to use for ingress.                                                                                                                                                                                                                                                                   | `""`                           |
| `server.ingress.hosts[0].paths[0].path`              | The paths to use for ingress.                                                                                                                                                                                                                                                                   | `/`                            |
| `server.ingress.hosts[0].paths[0].pathType`          | The path type for the ingress.                                                                                                                                                                                                                                                                  | `ImplementationSpecific`       |
| `server.ingress.tls`                                 | TLS configuration for the ingress.                                                                                                                                                                                                                                                              | `[]`                           |
| `server.ingress.gcp.backendConfig`                   | The backend configuration for Google Cloud Ingress.                                                                                                                                                                                                                                             | `{}`                           |
| `server.ingress.gcp.frontendConfig`                  | The frontend configuration for Google Cloud Ingress.                                                                                                                                                                                                                                            | `{}`                           |
| `server.ingress.gcp.managedCertificate.create`       | When enabled Google Cloud's managed certificate service will be used for the domain.                                                                                                                                                                                                            | `true`                         |
| `server.ingress.gcp.managedCertificate.extraDomains` | List with the domains that should be handled by Google.                                                                                                                                                                                                                                         | `[]`                           |
| `server.assets.path`                                 | Corteza will directly serve these assets (static files). When empty path is set (default value), embedded files are used.                                                                                                                                                                       | `""`                           |
| `server.assets.auth.path`                            | Path to js, css, images and template source files. When corteza starts, if path exists it tries to load template files from it. When empty path is set (default value), embedded files are used.                                                                                                | `""`                           |
| `server.locale.enabled`                              | When enabled locale languages configuration will take place.                                                                                                                                                                                                                                    | `false`                        |
| `server.locale.languages`                            | List of comma delimited languages (language tags) to enable. In case when an enabled language can not be loaded, error is logged.                                                                                                                                                               | `""`                           |
| `server.locale.enableDevelopmentMode`                | When enabled, Corteza reloads language files on every request Enable this for debugging or developing.                                                                                                                                                                                          | `true`                         |
| `server.locale.path`                                 | Path to locale files.                                                                                                                                                                                                                                                                           | `/mnt/corteza/corteza-locale/` |
| `server.log.debug`                                   | Disables json format for logging and enables more human-readable output with colors.                                                                                                                                                                                                            | `false`                        |
| `server.log.level`                                   | Minimum logging level. If set to "warn", Levels warn, error, dpanic panic and fatal will be logged. Recommended value for production: warn. Possible values: debug, info, warn, error, dpanic, panic, fatal.                                                                                    | `warn`                         |
| `server.log.stacktraceLevel`                         | Include stack-trace when logging at a specified level or below. Disable for production. Possible values: debug, info, warn, error, dpanic, panic, fatal.                                                                                                                                        | `error`                        |
| `server.log.includeCaller`                           | Set to true to see where the logging was called from. Disable for production.                                                                                                                                                                                                                   | `false`                        |
| `server.log.filter`                                  | Log filtering rules by level and name (log-level:log-namespace). Please note that level (LOG_LEVEL) is applied before filter and it affects the final output! Leave unset for production. https://docs.cortezaproject.org/corteza-docs/2024.9/devops-guide/references/configuration/server.html | `nil`                          |
| `server.log.components.http.request`                 | Log HTTP requests.                                                                                                                                                                                                                                                                              | `false`                        |
| `server.log.components.http.response`                | Log HTTP responses.                                                                                                                                                                                                                                                                             | `false`                        |
| `server.log.components.rbac`                         | Log RBAC related events and actions.                                                                                                                                                                                                                                                            | `false`                        |
| `server.log.components.locale`                       | Log locale related events and actions.                                                                                                                                                                                                                                                          | `false`                        |
| `server.log.components.auth`                         | Enable extra logging for authentication flows                                                                                                                                                                                                                                                   | `false`                        |
| `server.log.components.actionLog.enabled`            | Enable action log.                                                                                                                                                                                                                                                                              | `false`                        |
| `server.log.components.actionLog.debug`              | Enable debug logging for action log.                                                                                                                                                                                                                                                            | `false`                        |
| `server.log.components.actionLog.workflowFunctions`  | Enable logging workflow functions.                                                                                                                                                                                                                                                              | `false`                        |
| `server.log.components.apiGateway.enabled`           | Enable extra logging API Gateway related events and actions.                                                                                                                                                                                                                                    | `false`                        |
| `server.log.components.apiGateway.requestBody`       | Enable incoming request body output in logs.                                                                                                                                                                                                                                                    | `false`                        |
| `server.log.components.apiGateway.proxy.debug`       | Enable full debug log on requests / responses - warning, includes sensitive data.                                                                                                                                                                                                               | `false`                        |
| `server.persistence.enabled`                         | Enable persistent storage for the intalled Corteza instance.                                                                                                                                                                                                                                    | `true`                         |
| `server.persistence.storageClass`                    | The storage class for the persistent volume.                                                                                                                                                                                                                                                    | `""`                           |
| `server.persistence.accessModes`                     | The access modes for the persistent volume.                                                                                                                                                                                                                                                     | `["ReadWriteOnce"]`            |
| `server.persistence.size`                            | The size of the persistent volume.                                                                                                                                                                                                                                                              | `5Gi`                          |
| `server.autoscaling.enabled`                         | Enable autoscaling for the installed Corteza deployment.                                                                                                                                                                                                                                        | `false`                        |
| `server.autoscaling.minReplicas`                     | The minimum number of replicas for the installed Corteza deployment.                                                                                                                                                                                                                            | `1`                            |
| `server.autoscaling.maxReplicas`                     | The maximum number of replicas for the installed Corteza deployment.                                                                                                                                                                                                                            | `100`                          |
| `server.autoscaling.targetCPUUtilizationPercentage`  | The target CPU utilization percentage for autoscaling.                                                                                                                                                                                                                                          | `80`                           |
| `server.replicaCount`                                | The required number of replicas for the installed Corteza deployment. replicaCount is only used when autoscaling is not enabled.                                                                                                                                                                | `1`                            |
| `server.extraEnv`                                    | An array to add extra env vars.                                                                                                                                                                                                                                                                 | `{}`                           |
| `server.initContainers`                              | Add additional init containers to the Corteza server pods.                                                                                                                                                                                                                                      | `[]`                           |
| `server.imagePullSecrets`                            | Specify docker-registry secret names as an array. The specified secrets MUST be in the same namespace.                                                                                                                                                                                          | `[]`                           |
| `server.podAnnotations`                              | Annotations for the Corteza pods.                                                                                                                                                                                                                                                               | `{}`                           |
| `server.podSecurityContext`                          | Security context for the Corteza pods.                                                                                                                                                                                                                                                          | `{}`                           |
| `server.securityContext`                             | Security context for the Corteza container.                                                                                                                                                                                                                                                     | `{}`                           |
| `server.resources`                                   | Resource limits and requests for the Corteza server pods.                                                                                                                                                                                                                                       | `{}`                           |
| `server.nodeSelector`                                | Node labels for pod assignment.                                                                                                                                                                                                                                                                 | `{}`                           |
| `server.tolerations`                                 | Tolerations for pod assignment.                                                                                                                                                                                                                                                                 | `[]`                           |
| `server.affinity`                                    | Affinity settings for pod assignment.                                                                                                                                                                                                                                                           | `{}`                           |

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
| `postgresql.auth.enablePostgresUser`                    | Enable creating a PostgreSQL user.              | `true`       |
| `postgresql.auth.username`                              | Username of the PostgreSQL user.                | `corteza`    |
| `postgresql.auth.password`                              | Password of the PostgreSQL user.                | `corteza`    |
| `postgresql.auth.database`                              | Database name to use.                           | `corteza`    |
| `postgresql.architecture`                               | TODO                                            | `standalone` |
| `postgresql.global.postgresql.service.ports.postgresql` | Port to listen on for PostgreSQL server.        | `5432`       |

### External database

Overrides postgresql configuration.

| Name                                         | Description                                                                            | Value   |
| -------------------------------------------- | -------------------------------------------------------------------------------------- | ------- |
| `externalDatabase.enabled`                   | Enable using an external PostgresSQL database.                                         | `false` |
| `externalDatabase.existingSecret`            | Name of the Kubernetes secret containing the external PostgreSQL database credentials. | `""`    |
| `externalDatabase.existingSecretPasswordKey` | Key in the Kubernetes secret containing the external PostgreSQL database password.     | `""`    |
