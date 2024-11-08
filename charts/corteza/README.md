# Corteza Helm Chart

A Helm chart for Corteza, a low-code platform that lets you build and iterate CRM, business process and other structured data apps fast, create intelligent business process workflows and connect with almost any data source.

* The Corteza platform is maintained by [Planet Crust](https://www.planetcrust.com/), its founder.
* The chart is community maintained, driven by [Origoss](https://origoss.com/).

The default installation comes with two example applications (CRM and Case Management) provided by Planet Crust; otherwise, it only includes the building blocks needed to create your own application.

## Ingress configuration

### Prerequisites

You need an Ingress controlled installed in your Kubernetes cluster. Preferably, Nginx Ingress Controller.

### Google Cloud (GCP) configuration

This configuration is tailored for clusters running on Google Cloud Platform (GCP) and uses the Google Cloud Ingress controller. Select this setup if your cluster is hosted on GCP.

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

This configuration is designed for use across multiple cloud providers and is compatible with the NGINX Ingress controller.

```yaml
global:
  domain: &domain "yourdomain.com"

server:
  replicaCount: 1
  name: server
  ingress:
    enabled: false
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

Persistance is a key element of Corteza. It uses PostgreSQL to store data. To manage your own database in the cluster use the below configuration. The field `externalDatabase.enabled` must be disabled in order to use this configuration.

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
