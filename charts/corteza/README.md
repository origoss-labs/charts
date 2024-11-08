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
    tag: "2023.9.2"
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

| Name                                                 | Description                                                                                                                                                                                      | Value                          |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------ |
| `server.environment`                                 | The environment to run the server in (development, production, etc.).                                                                                                                            | `development`                  |
| `server.name`                                        | The name of the server service.                                                                                                                                                                  | `server`                       |
| `server.nameOverride`                                | The name to override the default name.                                                                                                                                                           | `""`                           |
| `server.auth.development`                            | When enabled, corteza reloads template before every execution. Enable this for debugging or when developing auth templates.                                                                      | `true`                         |
| `server.webConsole.enabled`                          | Enable web console. When running in dev environment, web console is enabled by default.                                                                                                          | `true`                         |
| `server.apiGateway.profiler.global`                  | When enabled, profiler is enabled for all routes.                                                                                                                                                | `true`                         |
| `server.image.repository`                            | The repository of the image used to deploy the Corteza application.                                                                                                                              | `cortezaproject/corteza`       |
| `server.image.pullPolicy`                            | The pull policy for the image used to deploy the Corteza application.                                                                                                                            | `IfNotPresent`                 |
| `server.image.tag`                                   | The tag of the image used to deploy the Corteza application. Overrides the image tag whose default is the chart appVersion.                                                                      | `2023.9.7`                     |
| `server.service.type`                                | The service type used to expose the Corteza application.                                                                                                                                         | `ClusterIP`                    |
| `server.service.port`                                | The port on which the server service listens.                                                                                                                                                    | `80`                           |
| `server.service.containerPort`                       | The port on which the server container listens.                                                                                                                                                  | `80`                           |
| `server.serviceAccount.create`                       | Whether a service account should be created.                                                                                                                                                     | `true`                         |
| `server.serviceAccount.annotations`                  | The annotations to add to the service account.                                                                                                                                                   | `{}`                           |
| `server.serviceAccount.name`                         | The name of the service account to use. If not set and create is true, a name is generated using the fullname template                                                                           | `""`                           |
| `server.ingress.enabled`                             | Whether to enable ingress.                                                                                                                                                                       | `false`                        |
| `server.ingress.controller`                          | The controller to use for ingress. Value can be either regular or gcp.                                                                                                                           | `regular`                      |
| `server.ingress.className`                           | The class name to use for ingress.                                                                                                                                                               | `""`                           |
| `server.ingress.annotations`                         | Annotations to use for the created ingress. For NGINX add: kubernetes.io/ingress.class: nginx                                                                                                    | `nil`                          |
| `server.ingress.hosts[0].host`                       | The hosts to use for ingress.                                                                                                                                                                    | `""`                           |
| `server.ingress.hosts[0].paths[0].path`              | The paths to use for ingress.                                                                                                                                                                    | `/`                            |
| `server.ingress.hosts[0].paths[0].pathType`          | The path type for the ingress.                                                                                                                                                                   | `ImplementationSpecific`       |
| `server.ingress.tls`                                 | TLS configuration for the ingress.                                                                                                                                                               | `[]`                           |
| `server.ingress.gcp.backendConfig`                   | The backend configuration for Google Cloud Ingress.                                                                                                                                              | `{}`                           |
| `server.ingress.gcp.frontendConfig`                  | The frontend configuration for Google Cloud Ingress.                                                                                                                                             | `{}`                           |
| `server.ingress.gcp.managedCertificate.create`       | When enabled Google Cloud's managed certificate service will be used for the domain.                                                                                                             | `true`                         |
| `server.ingress.gcp.managedCertificate.extraDomains` | List with the domains that should be handled by Google.                                                                                                                                          | `[]`                           |
| `server.assets.path`                                 | Corteza will directly serve these assets (static files). When empty path is set (default value), embedded files are used.                                                                        | `""`                           |
| `server.assets.auth.path`                            | Path to js, css, images and template source files. When corteza starts, if path exists it tries to load template files from it. When empty path is set (default value), embedded files are used. | `""`                           |
| `server.locale.enabled`                              | When enabled locale languages configuration will take place.                                                                                                                                     | `false`                        |
| `server.locale.languages`                            | List of comma delimited languages (language tags) to enable. In case when an enabled language can not be loaded, error is logged.                                                                | `""`                           |
| `server.locale.enableDevelopmentMode`                | When enabled, Corteza reloads language files on every request Enable this for debugging or developing.                                                                                           | `true`                         |
| `server.locale.path`                                 | Path to locale files.                                                                                                                                                                            | `/mnt/corteza/corteza-locale/` |
