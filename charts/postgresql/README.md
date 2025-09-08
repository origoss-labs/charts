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

## Example Minimal Configuration

```yaml
image:
  repository: ghcr.io/zalando/spilo-16
  tag: "3.2-p3"
instances: 1
teamId: postgres
volume:
  size: 1Gi
users:
  db-owner:
    - createdb
databases:
  my-database: db-owner
version: "16"
```

## Backup and Restore

### Backup

Backups are performed using a Kubernetes CronJob. You can configure the schedule, backup directory, and storage options in `values.yaml`.
> **IMPORTANT**
>
> The chart currently does not support backing up specific databases, it picks the first in the list of databases defined in the `values.yaml` file. Consequently, we recommend defining each database as a separate PostgreSQL chart deployment.

#### Example backup configuration

```yaml
backup:
  enabled: true
  mountPath: /backups
  schedule: "0 * * * *" # Run every day at midnight.
  size: 1Gi
```

### Restore

To restore from a backup, enable the restore job and specify the backup Persistent Volume Claim to use. By default, the job restores the latest backup created.

#### Example restore configuration

```yaml
restore:
  enabled: true
  dataSource:
    claimName: "postgresql-backup"
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
| `image.repository`    | PostgreSQL container image repository              | `ghcr.io/zalando/spilo-16` |
| `image.tag`           | PostgreSQL image tag                               | `3.2-p3`                   |
| `image.pullPolicy`    | Image pull policy. Applies to backup and restore containers| `IfNotPresent`     |
| `volume.size`         | Storage size of the db's PVC                       | `8Gi`                      |
| `volume.storageClass` | Storage class of the db's PVC                      | `""`                       |
| `instances`           | Number of pods for the db's StatefulSet            | `1`                        |
| `version`             | Major PostgreSQL version                           | `"16"`                     |
| `teamId`              | Team ID for the PostgreSQL custom resource         | `postgres`                 |
| `users`               | Database users and their roles                     | `dbowner:[createdb]`       |
| `databases`           | Database names and their owners                    | `my-database: dbowner`     |
| `extraEnv`            | Environment variables for the db's container       | `[]`                       |
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
| `backup.mountPath`        | Path where the container mounts the PVC           | `/backups`     |
| `backup.schedule`         | Cron schedule of the backup                       | `"0 0 * * *"`  |
| `backup.accessMode`       | Access mode for the backup PVC                    | `ReadWriteOnce`|
| `backup.size`             | Size of the backup PVC's storage                  | `8Gi`          |
| `backup.storageClass`     | Storage Class of the backup's PVC                 | `""`           |
| `backup.extraEnv`         | Environment variables for the backup container    | `[]`           |

### Restore configuration

| Name                          | Description                                     | Default        |
|-------------------------------|-------------------------------------------------|----------------|
| `restore.enabled`             | Enable restore Job                              | `false`        |
| `restore.dataSource.claimName`| Backup PVC to restore from                      | `""`           |
| `restore.extraEnv`            | Environment variables for the restore container | `[]`           |

## Templates

- `templates/postgresql.yaml` - Main PostgreSQL manifest
- `templates/backup-cronjob.yaml` - Backup CronJob
- `templates/restore-job.yaml` - Restore Job
- `templates/backup-pvc.yaml` - Persistent Volume Claim for backups
