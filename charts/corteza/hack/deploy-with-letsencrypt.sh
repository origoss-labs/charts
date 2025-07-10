#!/usr/bin/env bash

set -euo pipefail

DIRNAME=$(dirname "$(readlink -f "$0")")

echo "Determining which components to install..."
CORTEZA_ENABLED=$(grep corteza "$DIRNAME"/values/components.yaml | awk '{print $2}')
CERT_MANAGER_ENABLED=$(grep cert-manager "$DIRNAME"/values/components.yaml | awk '{print $2}')
NGINX_INGRESS_ENABLED=$(grep nginx-ingress-controller "$DIRNAME"/values/components.yaml | awk '{print $2}')
LETSENCRYPT_ENABLED=$(grep letsencrypt "$DIRNAME"/values/components.yaml | awk '{print $2}')

if [[ "$NGINX_INGRESS_ENABLED" == "true" ]]; then
    echo "Installing nginx-ingress controller..."
    helm upgrade --install nginx-ingress nginx-ingress-controller \
        --namespace ingress-nginx \
        --create-namespace \
        --version 11.6.26 \
        -f "$DIRNAME"/values/nginx-values.yaml \
        --repo https://charts.bitnami.com/bitnami \
        --wait
else
    echo "Skipping nginx-ingress-controller installation."
    echo "When using other ingress controllers, ensure you correctly specify the ingress class in the Corteza values file."
fi

if [[ "$CERT_MANAGER_ENABLED" == "true" ]]; then
    echo "Installing cert-manager..."
    helm upgrade --install cert-manager cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --version 1.18.2 \
        -f "$DIRNAME"/values/cert-manager-values.yaml \
        --repo https://charts.jetstack.io \
        --wait
else
    echo "Skipping cert-manager installation."
    echo "Let's Encrypt will not work without cert-manager, as it creates a custom resource defined by cert-manager. Ensure you have cert-manager installed before proceeding."
fi

if [[ "$LETSENCRYPT_ENABLED" == "true" ]]; then
    echo "Installing Let's Encrypt ClusterIssuer..."
    helm upgrade --install letsencrypt-issuer letsencrypt-issuer \
        --version 0.1.0 \
        -f "$DIRNAME"/values/letsencrypt-issuer-values.yaml \
        --repo https://origoss-labs.github.io/charts \
        --wait

    echo "Fetching ClusterIssuer name..."
    CLUSTER_ISSUER_NAME=$(kubectl get clusterissuer -l app.kubernetes.io/instance=letsencrypt-issuer -o jsonpath='{.items[0].metadata.name}')
else
    echo "Skipping Let's Encrypt installation."
    echo "WARNING: You must manually create a ClusterIssuer for Corteza to work with Let's Encrypt."
    echo "After creating the ClusterIssuer, run the following command to install corteza:"
    echo -e "helm upgrade --install corteza corteza \\
    --namespace corteza \\
    --create-namespace \\
    --version 1.0.8 \\
    -f $DIRNAME/values/corteza-values.yaml \\
    --repo https://origoss-labs.github.io/charts \\
    --set server.ingress.annotations.'cert-manager.io/cluster-issuer'='<CLUSTER_ISSUER_NAME>'"
    exit 0
fi

if [[ "$CORTEZA_ENABLED" == "true" ]]; then
    echo "Installing Corteza..."
    helm upgrade --install corteza corteza \
        --namespace corteza \
        --create-namespace \
        --version 1.0.8 \
        -f "$DIRNAME"/values/corteza-values.yaml \
        --repo https://origoss-labs.github.io/charts \
        --wait \
        --set server.ingress.annotations."cert-manager\.io/cluster-issuer"="$CLUSTER_ISSUER_NAME"
else
    echo "Skipping Corteza installation."
fi
