# Overview

**[Corteza](https://cortezaproject.org/)** is an open-source low-code platform developed by **Planet Crust**. In a production environment, Corteza co-operates with other services, such as cert-manager and an ingress controller, to handle incoming traffic. This script facilitates the deployment of these components using their Helm charts, enabling an easily managed, idempotent architecture.

The central idea of this infrastructure is to handle TLS/SSL connections using **[Let's Encrypt](https://letsencrypt.org/)**, which is achieved by creating a ClusterIssuer Kubernetes resource, and attaching it to the Corteza server's Ingress resource. This prompts Let's Encrypt's API to validate our ownership of the domain and sign the certificates, enabling secure connections. To avoid manually creating this ClusterIssuer, which depends on cert-manger, as it defines the ClusterIssuer Custom Resource, We developed a simple Helm chart.
> Note: The script deosn't require all components to be enabled, but the Let's Encrypt Issuer chart is dependent on cert-manager. Ensure that cert-manager is already installed, if opting to disabling it in this script, but installing the Let's Encrypt Issuer regardless.

The Bash script automates the deployment of the components, with support for selectively enabling:

- [NGINX Ingress Controller](https://artifacthub.io/packages/helm/bitnami/nginx-ingress-controller)

- [cert-manager](https://artifacthub.io/packages/helm/cert-manager/cert-manager)

- [Let's Encrypt Issuer](https://artifacthub.io/packages/helm/corteza/letsencrypt-issuer)

- [Corteza](https://artifacthub.io/packages/helm/corteza/corteza)

Each component is installed via a helm chart, with optional overrides provided through custom values.yaml files.

# Requirements

- A running Kubernetes cluster.
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) - CLI tool to manage Kubernetes clusters.
- [Helm](https://helm.sh) - Package manager for Kubernetes.
- Clone the script and the values directory with its contents. These `*-values.yaml` files contain the value overrides of the corresponding helm charts, modify them as necessary.
    - The structure and names of files is not mutable, it follows a strict design, with the script and the values folder in the same parent directory.
    - Ensure that even if not using custom values for a component, to still include the `*-values.yaml` file in the `values` directory, even when leaving the file empty.
    - Structure:
    ```md
    .
    ├── deploy-corteza-all-in-one.sh
    └── values/
        ├── nginx-values.yaml
        ├── cert-manager-values.yaml
        ├── letsencrypt-issuer-values.yaml
        └── corteza-values.yaml
    ```

# Usage
``` bash
./deploy-corteza-all-in-one.sh [OPTIONS]
```
Available Options:

|           **Flag**         |          **Description**         |       **Environmental Variable**      |
| -------------------------- | -------------------------------- | ------------------------------------- |
| --nginx-ingress-controller | Install NGINX Ingress Controller | **NGINX_INGRESS_CONTROLLER**          |
| --cert-manager             | Install cert-manager             | **CERT_MANAGER**                      |
| --letsencrypt              | Install Let's Encrypt Issuer     | **LETSENCRYPT**                       |
| --corteza                  | Install Corteza                  | **CORTEZA**                           |
| -h, --help                 | Show help message                | -                                     |

The script parses the flags and sets environmental variables to later determine which chart to install. Alternatively, the user has the option to override these environmental variables themselves.

## Example
Install all components:
``` bash
./deploy-corteza-all-in-one.sh \
    --nginx-ingress-controller \
    --cert-manager \
    --letsencrypt \
    --corteza
```
Install only cert-manager and Corteza (manually managed TLS):
``` bash
./deploy-corteza-all-in-one.sh \
    --cert-manager \
    --corteza
```
### Setting environmental variables
``` bash
CORTEZA="enabled" CERT_MANAGER="enabled" ./deploy-corteza-all-in-one.sh
```

## PostgreSQL
The **Corteza** chart includes the **[PostgreSQL](https://artifacthub.io/packages/helm/bitnami/postgresql)** chart as a subchart. The user has the option to use an external database for their application, by setting the `externalDatabase.enabled` value to true in the `values/corteza-values.yaml` file. If so, a Secret should be created with the external database's credentials, and the values file should be configured like this:
``` yaml
externalDatabase:
  enabled: true
  existingSecret: <secret-name>
  existingSecretPasswordKey: <key-of-secret-to-password>

```

### Backup and Restore
#### Backup

The **PostgreSQL** subchart allows creating scheduled backups using Cronjobs. The Cronjob creates a Job at the scheduled time, which saves the dumped data to a Persistent Volume. To schedule a backup, see the example below.
``` yaml
corteza:
  postgresql:
    backup:
      enabled: true
      cronjob:
        # The schedule parameter can be configured using standard cronjob syntax, or macros. For further information, see https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#schedule-syntax.
        schedule: "@daily"
        command:
          - "/bin/bash"
          - "-c"
          - "PGPASSWORD=\"${PGPASSWORD:-$(< \"$PGPASSFILE\")}\" pg_dumpall --clean --if-exists --load-via-partition-root --quote-all-identifiers --file=\"${PGDUMP_DIR}/pg_dumpall-$(date '+%Y-%m-%d-%H-%M').pgdump\""
        # Extra volume to mount the postgresql password.
        extraVolumeMounts:
          - name: postgres-password
            mountPath: /opt/bitnami/postgresql/secrets/
        extraVolumes:
          - name: postgres-password
            secret:
              secretName: corteza-postgresql
              defaultMode: 420
        storage:
          # Required for Helm to keep the Persistent Volume when uninstalling the chart.
          resourcePolicy: keep

```

#### Restore

To restore a backup from a Persistent Volume, the user can configure the PostgreSQL instance to use the Volume as data source. See the example below:
``` yaml
corteza:
  postgresql:
    primary:
      persistence:
        dataSource:
          name: corteza-postgresql-pgdumpall
          kind: PersistentVolumeClaim

```
> Note: Only a new **PostgreSQL** instance can be configured to use a data source. Restoring a backup to a running database is not possible.

# Notes
- The **Let's Encrypt Issuer** chart deploys a custom resource defined by the **cert-manager** helm chart. If `--letsencrypt` is enabled but `--cert-manager` is not, the script will check whether **cert-manager** is already deployed. If not, it exits with an error.
- The script dynamically sets the `cert-manager.io/cluster-issuer` annotation on Corteza's Ingress based on the deployed **Let's Encrypt Issuer**. If the user deploys their own Issuer, they should annotate the corteza server's Ingress with the following:
`cert-manager.io/cluster-issuer: <issuer-name>`
