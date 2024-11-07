# The Home of the Origoss Helm Charts

Helm Charts built, tested and released by [Origoss](https://origoss.com/) are hosted in this repository.

## Before you begin

## Prerequisites

* Kubernetes 1.xx +
* Helm 3.x +

### Install Helm

Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources.

To install Helm, refer to the [Helm install guide](https://github.com/helm/helm#install) and ensure that the `helm` binary is in the `PATH` of your shell.

### Using Helm

Once you have installed the Helm client, you can deploy an Origoss Helm Chart into a Kubernetes cluster.

Please refer to the [Quick Start guide](https://helm.sh/docs/intro/quickstart/) if you wish to get running in just a few commands, otherwise, the [Using Helm Guide](https://helm.sh/docs/intro/using_helm/) provides detailed instructions on how to use the Helm client to manage packages on your Kubernetes cluster.

Useful Helm Client Commands:

* Adding the repository: `helm repo add origoss-labs https://origoss-labs.github.io/charts/`
* Install a chart: `helm install my-release origoss-labs/<chart>`
* Upgrade your application: `helm upgrade my-release origoss-labs/<chart>`

## License

Apache License - see [LICENSE](LICENSE) for full text.
