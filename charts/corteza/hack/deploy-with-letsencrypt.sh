#!/usr/bin/env bash

set -euo pipefail

DIRNAME=$(dirname "$(readlink -f "$0")")

# This block sets up the helm commands to install the components.
HELM_COMMAND="helm upgrade --install"
COMMON_ARGS="--create-namespace --wait"

# NGINX Ingress Controller command
NGINX_HELM_ARGS="$COMMON_ARGS \
--namespace nginx-ingress \
--version 11.6.26 \
-f $DIRNAME/values/nginx-values.yaml \
--repo https://charts.bitnami.com/bitnami"

NGINX_HELM_COMMAND="$HELM_COMMAND nginx-ingress nginx-ingress-controller $NGINX_HELM_ARGS"

# Cert-Manager command
CERT_MANAGER_HELM_ARGS="$COMMON_ARGS \
--namespace cert-manager \
--version 1.18.2 \
-f $DIRNAME/values/cert-manager-values.yaml \
--repo https://charts.jetstack.io"

CERT_MANAGER_HELM_COMMAND="$HELM_COMMAND cert-manager cert-manager $CERT_MANAGER_HELM_ARGS"

# Let's Encrypt ClusterIssuer command
LETSENCRYPT_HELM_ARGS="$COMMON_ARGS \
--version 0.1.0 \
-f $DIRNAME/values/letsencrypt-issuer-values.yaml \
--repo https://origoss-labs.github.io/charts"

LETSENCRYPT_HELM_COMMAND="$HELM_COMMAND letsencrypt-issuer letsencrypt-issuer $LETSENCRYPT_HELM_ARGS"

# Corteza command
CORTEZA_HELM_ARGS="$COMMON_ARGS \
--namespace corteza \
--version 1.0.8 \
-f $DIRNAME/values/corteza-values.yaml \
--repo https://origoss-labs.github.io/charts"

CORTEZA_HELM_COMMAND="$HELM_COMMAND corteza corteza $CORTEZA_HELM_ARGS"

echo "The following components will be installed:"
for component in CORTEZA NGINX_INGRESS_CONTROLLER CERT_MANAGER LETSENCRYPT; do
    if [[ "${!component:-}" != "" ]]; then
        echo "- $component"
    fi
done

if [[ -n "${NGINX_INGRESS_CONTROLLER:-}" ]]; then
    echo "Installing nginx-ingress controller..."
    $NGINX_HELM_COMMAND
fi

if [[ -n "${CERT_MANAGER:-}" ]]; then
    echo "Installing cert-manager..."
    $CERT_MANAGER_HELM_COMMAND
fi

if [[ -n "${LETSENCRYPT:-}" ]]; then
    if [[ -z "${CERT_MANAGER:-}" ]]; then
        if kubectl get deployment -l app=cert-manager -A -o jsonpath='{.items[0]}' >/dev/null 2>&1; then
            echo "Cert-manager is already installed, proceeding with Let's Encrypt installation."
        else
            echo "Error: Let's Encrypt requires cert-manager to be installed first. Install cert-manager or enable it and re-run this script."
            exit 1
        fi
    fi

    echo "Installing Let's Encrypt ClusterIssuer..."
    $LETSENCRYPT_HELM_COMMAND

    echo "Fetching ClusterIssuer name..."
    CLUSTER_ISSUER_NAME=$(kubectl get clusterissuer -l app.kubernetes.io/instance=letsencrypt-issuer -o jsonpath='{.items[0].metadata.name}')

    CORTEZA_HELM_COMMAND="$CORTEZA_HELM_COMMAND --set-string server.ingress.annotations.cert-manager\\.io/cluster-issuer=$CLUSTER_ISSUER_NAME"
fi

if [[ -n "${CORTEZA:-}" ]]; then
    echo "Installing Corteza..."
    $CORTEZA_HELM_COMMAND
fi
