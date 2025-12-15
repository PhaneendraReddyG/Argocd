#!/bin/bash
# Create ArgoCD Applications for an app
# Usage: ./create-apps.sh --app APP

set -e

app="first-app"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --app) app="$2"; shift 2;;
        *) echo >&2 "Unknown option: $1"; exit 1;;
    esac
done

manifests_app="${app}-manifests"

echo "Creating ArgoCD Applications for $app..."

argocd app create "$manifests_app" \
  --repo https://github.com/PhaneendraReddyG/Argocd.git \
  --path "applications/$app/manifests" \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace "$app" \
  --sync-policy automated \
  --self-heal \
  --prune || echo "App $manifests_app may already exist"

argocd app create "$app" \
  --repo https://github.com/PhaneendraReddyG/Argocd.git \
  --path "applications/$app" \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace "$app" \
  --helm-values values.yaml \
  --sync-policy automated \
  --self-heal \
  --prune || echo "App $app may already exist"

echo "Applications created."