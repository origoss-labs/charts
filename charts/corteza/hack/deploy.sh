set -eou pipefail

helm upgrade --install corteza-dev . --namespace corteza-dev --create-namespace --debug
