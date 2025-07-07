## Overview

This section contains the KUTTL tests, responsible for testing the successful deployment of the corteza-all-in-one Helm chart. As the chart is an umbrella chart, the separate subcharts each have their own test suite, designed to test the components of them.

## Usage

These tests were designed to be used as part of a GitHub Actions Workflow, but can also be ran locally, which requires some provisioning.

### Prerequisites
- A local Kubernetes cluster ([minikube](https://minikube.sigs.k8s.io/docs/), [k3s](https://k3s.io/), [kind](https://kind.sigs.k8s.io/))
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) CLI tool
    - [KUTTL plugin](https://kuttl.dev/) (either through Krew, brew or natively using its binary)
- [Helm](https://helm.sh)

### Guide
1. Enter the chart's directory.
``` bash
cd charts/corteza-all-in-one
```
2. Add the subcharts' repositories to Helm.
``` bash
helm repo add corteza https://origoss-labs.github.io/charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add jetstack https://charts.jetstack.io
helm repo update
```
3. Build chart dependencies.
``` bash
helm dependency build
```
4. Run a test.
``` bash
# The binary could differ based on your KUTTL installation method
# When running into trouble, try 'kubectl kuttl' or 'kuttl'
kubectl-kuttl test --config tests/smoke/.../kuttl-test.yaml
```