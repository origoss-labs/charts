#!/usr/bin/env bash

set -euo pipefail

DIRNAME=$(dirname "$(readlink -f "$0")")

echo "Setting up Helm repositories..."
helm repo add corteza https://origoss-labs.github.io/charts
helm repo add jetstack https://charts.jetstack.io
helm repo add bitnami https://charts.bitnami.com/bitnami

echo "Updating Helm repositories..."
helm repo update

echo "Installing nginx-ingress controller..."
helm upgrade --install nginx-ingress bitnami/nginx-ingress-controller \
    --namespace ingress-nginx \
    --create-namespace \
    --version 11.6.26 \
    -f "$DIRNAME"/values/nginx-values.yaml

echo "Installing cert-manager..."
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version 1.18.2 \
    -f "$DIRNAME"/values/cert-manager-values.yaml \
    --wait

echo "Installing Let's Encrypt ClusterIssuer..."
helm upgrade --install letsencrypt-issuer corteza/letsencrypt-issuer \
    --version 0.1.0 \
    -f "$DIRNAME"/values/letsencrypt-issuer-values.yaml

echo "Fetching ClusterIssuer name..."
CLUSTER_ISSUER_NAME=$(kubectl get clusterissuer | grep letsencrypt | awk '{print $1}')

echo "Installing Corteza..."
helm upgrade --install corteza corteza/corteza \
    --namespace corteza \
    --create-namespace \
    --version 1.0.8 \
    -f "$DIRNAME"/values/corteza-values.yaml \
    --set server.ingress.annotations."cert-manager\.io/cluster-issuer"="$CLUSTER_ISSUER_NAME"
