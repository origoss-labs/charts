# PostgreSQL Helm Chart

A Helm chart for deploying PostgreSQL in Kubernetes clusters, with optional automated backup and restore functionality. This chart is dependent on [Zalando's Postgres Operator](https://github.com/zalando/postgres-operator).

The chart is community maintained, driven by [Origoss](https://origoss.com/).

## Features

- Deploys a PostgreSQL custom resource, prompting the Operator to spin up a PostgreSQL StatefulSet
- Configurable storage, resources, and RBAC
- Automated backups via CronJob
- Restore job for disaster recovery

## Installation

Add the repository and install the chart:

```sh
helm repo add origoss-labs https://origoss-labs.github.io/charts
helm install postgresql origoss-labs/postgresql -f values.yaml
```

## Backup and Restore

### Backup

Backups are performed using a Kubernetes CronJob. You can configure the schedule, backup directory, and storage options in `values.yaml`.

### Restore

To restore from a backup, enable the restore job and specify the backup Persistent Volume Claim to use. By default, the job restores the latest backup created.

## Example Minimal Configuration

```yaml
postgresql:
  enabled: true
  image:
    repository: ghcr.io/zalando/spilo-17
    tag: "4.0-p2"
  instances: 1
  size: 1Gi
  users:
    db-owner:
      - createdb
  databases:
    my-database: db-owner
  version: "17"
```

## Parameters

### Chart configuration

| Name                          | Description                                   | Default        |
|-------------------------------|-----------------------------------------------|----------------|
| `nameOverride`                | Provide a different name for the chart        | `""`           |
| `fullnameOverride`            | Provide a different full name for the chart   | `""`           |

### PostgreSQL configuration

| Name                  | Description                                        | Default                    |
|-----------------------|----------------------------------------------------|----------------------------|
| `image.repository`    | PostgreSQL container image repository              | `ghcr.io/zalando/spilo-17` |
| `image.tag`           | PostgreSQL image tag                               | `4.0-p2`                   |
| `volume.size`         | Storage size of the db's PVC                       | `8Gi`                      |
| `volume.storageClass` | Storage class of the db's PVC                      | `""`                       |
| `instances`           | Number of pods for the db's StatefulSet            | `1`                        |
| `version`             | Major PostgreSQL version                           | `"17"`                     |
| `users`               | Database users and their roles                     | `dbowner:[createdb]`       |
| `databases`           | Database names and their owners                    | `my-database: dbowner`     |
| `resources`           | Resource requests and limits for the db's container| `{}`                       |
| `volumeMounts`        | Additional volume mounts for the db's container    | `[]`                       |
| `annotations`         | Annotations for the postgresql custom resource     | `{}`                       |
| `podAnnotations`      | Annotations for the postgresql pods                | `{}`                       |
| `serviceAnnotations`  | Annotations for the postgresql service             | `{}`                       |
| `tolerations`         | Tolerations for the postgresql pods                | `[]`                       |
| `affinity`            | Affinity for the postgresql pods                   | `{}`                       |


### Backup configuration

| Name                      | Description                                       | Default        |
|---------------------------|---------------------------------------------------|----------------|
| `backup.enabled`          | Enable backup CronJob                             | `true`         |
| `backup.image.repository` | Repository of the backup container's image        | `postgres`     |
| `backup.image.tag`        | Tag of the backup container's image               | `"17.6-alpine"`|
| `backup.image.pullPolicy` | Image pull policy of the backup container's image | `IfNotPresent` |
| `backup.mountPath`        | Path where the container mounts the PVC           | `/backups`     |
| `backup.schedule`         | Cron schedule of the backup                       | `"0 0 * * *"`  |
| `backup.size`             | Size of the backup PVC's storage                  | `8Gi`          |
| `backup.storageClass`     | Storage Class of the backup's PVC                 | `""`           |

### Restore configuration

| Name                          | Description                                   | Default        |
|-------------------------------|-----------------------------------------------|----------------|
| `restore.enabled`             | Enable restore Job                            | `false`        |
| `restore.dataSource.claimName`| Backup PVC to restore from                    | `""`           |

## Templates

- `templates/postgresql.yaml` - Main PostgreSQL manifest
- `templates/backup-cronjob.yaml` - Backup CronJob
- `templates/restore-job.yaml` - Restore Job
- `templates/backup-pvc.yaml` - Persistent Volume Claim for backups
