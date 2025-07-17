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
corteza:
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

# Storage

The **Corteza** and **PostgreSQL** charts use Persistent Volumes to store application data, including Backups. The Volumes are dynamically created and can be reached on the host machine in a directory, based on the Container Storage Interface. By default, there are 2 folders related to the charts, each representing a Persistent Volume:
- `corteza-server`
- `data-corteza-postgresql-0`

If backups are configured, a third folder is present, called `corteza-postgresql-pgdumpall`. As the **PostgreSQL** chart does not enable an advanced Backup and Restore management, the *pgdumps* in this directory can be altered, parsed or moved to another storage to better suit the specific need. E.g.: We would like to restore the database, but not to the latest backup's state, rather some earlier version. In this case, moving or removing the *pgdumps* created after the one we need allows us to create a database pointing to the backup's Persistent Volume Claim, which spins the database up using the latest data in the Volume.

Some environments require some setting up, in order to properly bind the host to the cluster.

## Minikube

Minikube makes use of several types of drivers, allowing running the cluster either on a virtual machine, or in a container. Therefore, accessing the cluster's storage differs based on the driver chosen.

Some hypervisors have built-in host folder sharing. Driver mounts are reliable with good performance, but the paths are not predictable across operating systems or hypervisors:
|    Driver    |   OS    | HostFolder |       VM       |
| ------------ | ------- | ---------- | -------------- |
|  Virtualbox  |  Linux  | /home      | /hosthome      |
|  Virtualbox  |  macOS  | /Users     | /Users         |
|  Virtualbox  | Windows | C://Users  | /c/Users       |
|VMWare Fusion |  macOS  | /Users     | /mnt/hgfs/Users|
|     KVM      |  Linux  | Unsupported|       -        |
|  HyperKit    |  macOS  | /home      | See below      |

These mounts can be disabled by passing `--disable-driver-mounts` to `minikube start`.

HyperKit mounts can use the following flags:
- `--nfs-share=[]`: Local folders to share with Guest via NFS mounts
- `--nfs-shares-root='/nfsshares'`: Where to root the NFS Shares, defaults to /nfsshares

### Docker driver

Running minikube with Docker (or podman) as driver runs the cluster in a container, which means the Persistent Volumes only exist inside it. In order to reach the stored files, a path of the host must be mounted to minikube's container. This can be done by running a command:
```sh
minikube mount <path/to/storage>:<minikube/path/to/storage> --uid 1001 --gid 1001
```
Depending on what storage provisioner is used, the container's path to the storage differs. For simplicity's sake, we assume the default `storage-provisioner` is utilized. In this case, the storage can be found inside the container in `/tmp/hostpath-provisioner/corteza/`.
> Note: The `corteza` subpath is created based on the namespace **PostgreSQL** is deployed in. If modified, keep this in mind!

## K3s

[K3s](https://docs.k3s.io/) comes with Rancher's Local Path Provisioner and this enables the ability to create persistent volume claims out of the box using local storage on the respective node. Because the cluster runs on the host system natively, it requires no further configuration, the Persistent Volumes can be reached in:
`/var/lib/rancher/k3s/storage/`. The Volumes are represented as directories here, following the convention of `<pv-name>_<namespace>_<pvc-name>`.

## Kind

[KinD](https://kind.sigs.k8s.io/) runs a light-weight cluster in a Docker container. It comes preconfigured with a Local Path Provisioner, and thus is also able to dynamically provision Persistent Volumes. The default path of the Volumes inside the container is `/var/local-path-provisioner/`, with the Volumes represented as directories, following the same convention as the ones in [K3s](#k3s).

To reach the volumes from the host, extra volumes can be mounted on the cluster. Assuming a `/home/user/corteza-data/` directory on the host is created, here's an example `kind-config.yaml`:
``` yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /home/user/corteza-data/
    containerPath: /var/local-path-provisioner/

```

# Notes
- The **Let's Encrypt Issuer** chart deploys a custom resource defined by the **cert-manager** helm chart. If `--letsencrypt` is enabled but `--cert-manager` is not, the script will check whether **cert-manager** is already deployed. If not, it exits with an error.
- The script dynamically sets the `cert-manager.io/cluster-issuer` annotation on Corteza's Ingress based on the deployed **Let's Encrypt Issuer**. If the user deploys their own Issuer, they should annotate the corteza server's Ingress with the following:
`cert-manager.io/cluster-issuer: <issuer-name>`
