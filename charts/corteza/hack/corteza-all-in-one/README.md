# Overview

This Bash script automates the deployment of several Kubernetes components using Helm, with support for selectively enabling:

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

The script parses the flags and sets environmental variables to later determine which chart to install.

Alternatively, the user has the option to set these environmental variables themselves, either before running the script, or in-line.

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
Beforehand: (The values persist in the host's environment)
``` bash
export CORTEZA="enabled"
export CERT_MANAGER="enabled"
./deploy-corteza-all-in-one.sh
```
In-line:
``` bash
CORTEZA="enabled" CERT_MANAGER="enabled" ./deploy-corteza-all-in-one.sh
```

# Notes
- The **Let's Encrypt Issuer** chart deploys a custom resource defined by the **cert-manager** helm chart. If `--letsencrypt` is enabled but `--cert-manager` is not, the script will check whether **cert-manager** is already deployed. If not, it exits with an error.
- The script dynamically sets the `cert-manager.io/cluster-issuer` annotation on Corteza's Ingress based on the deployed **Let's Encrypt Issuer**. If the user deploys their own Issuer, they should annotate the corteza server's Ingress with the following:
`cert-manager.io/cluster-issuer: <issuer-name>`
