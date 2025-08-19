#!/usr/bin/env bash

set -euo pipefail

DIRNAME=$(dirname "$(readlink -f "$0")")

# Default values for flags
# These can be overridden by environment variables or command line flags
NGINX_INGRESS_CONTROLLER=${NGINX_INGRESS_CONTROLLER:-""}
CERT_MANAGER=${CERT_MANAGER:-""}
LETSENCRYPT=${LETSENCRYPT:-""}
CORTEZA=${CORTEZA:-""}

# Parsing command line flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --nginx-ingress-controller)
            NGINX_INGRESS_CONTROLLER="enabled"
            shift
            ;;
        --cert-manager)
            CERT_MANAGER="enabled"
            shift
            ;;
        --letsencrypt)
            LETSENCRYPT="enabled"
            shift
            ;;
        --corteza)
            CORTEZA="enabled"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--nginx-ingress-controller] [--cert-manager] [--letsencrypt] [--corteza]"
            echo "Options:"
            echo "  --nginx-ingress-controller   Install NGINX Ingress Controller"
            echo "  --cert-manager               Install cert-manager"
            echo "  --letsencrypt                Install Let's Encrypt ClusterIssuer"
            echo "  --corteza                    Install Corteza"
            echo "  -h, --help                   Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--nginx-ingress-controller] [--cert-manager] [--letsencrypt] [--corteza]"
            echo "Use --help for more information."
            exit 1
            ;;
    esac
done

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
--version 2.0.0 \
-f $DIRNAME/values/corteza-values.yaml \
--repo https://origoss-labs.github.io/charts"

CORTEZA_HELM_COMMAND="$HELM_COMMAND corteza corteza $CORTEZA_HELM_ARGS"

# Determine which components to install
echo "The following components will be installed:"
for component in CORTEZA NGINX_INGRESS_CONTROLLER CERT_MANAGER LETSENCRYPT; do
    if [[ "${!component:-}" != "" ]]; then
        echo "- $component"
    fi
done

# Install components
if [[ -n "${NGINX_INGRESS_CONTROLLER:-}" ]]; then
    echo "Installing nginx-ingress controller..."
    $NGINX_HELM_COMMAND
fi

if [[ -n "${CERT_MANAGER:-}" ]]; then
    echo "Installing cert-manager..."
    $CERT_MANAGER_HELM_COMMAND
fi

if [[ -n "${LETSENCRYPT:-}" ]]; then
    # Check if cert-manager is installed before installing Let's Encrypt
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

    # Fetch the ClusterIssuer name and set it in the Corteza Helm command
    echo "Fetching ClusterIssuer name..."
    CLUSTER_ISSUER_NAME=$(kubectl get clusterissuer -l app.kubernetes.io/instance=letsencrypt-issuer -o jsonpath='{.items[0].metadata.name}')

    CORTEZA_HELM_COMMAND="$CORTEZA_HELM_COMMAND --set-string server.ingress.annotations.cert-manager\\.io/cluster-issuer=$CLUSTER_ISSUER_NAME"
fi

if [[ -n "${CORTEZA:-}" ]]; then
    echo "Checking for CRDs..."
    if ! kubectl get crd | grep -q 'postgresqls'; then
        echo "Installing Corteza with PostgreSQL disabled..."
        $CORTEZA_HELM_COMMAND --set postgresql.enabled=false
    fi
    echo "Components and CRDs installed successfully."
    echo "Deploying PostgreSQL instance..."
    $CORTEZA_HELM_COMMAND
fi
