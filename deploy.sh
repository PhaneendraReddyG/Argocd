#!/bin/bash
# Automated deployment script for an ArgoCD app via ArgoCD CLI
# This script creates the ArgoCD Applications, syncs them, and waits for success.
# Assumes structure: applications/{app}/ (with Chart.yaml, values.yaml, manifests/, install/)

set -e  # Exit on any error

# Default values
app="first-app"
timeout=600  # 10 minutes

# Options
while [ "$#" -gt 0 ]; do
    case "$1" in
        --app) app="$2"; shift 2;;
        --timeout) timeout="$2"; shift 2;;
        *) echo >&2 "Unknown option: $1"; exit 1;;
    esac
done

ARGOCD_NS="argocd"
manifests_app="${app}-manifests"

echo "Creating ArgoCD Applications for $app..."

# Create the manifests Application
argocd app create "$manifests_app" \
  --repo https://github.com/PhaneendraReddyG/Argocd.git \
  --path "applications/$app/manifests" \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace "$app" \
  --sync-policy automated \
  --self-heal \
  --prune || echo "App $manifests_app may already exist"

# Create the Helm Application
argocd app create "$app" \
  --repo https://github.com/PhaneendraReddyG/Argocd.git \
  --path "applications/$app" \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace "$app" \
  --helm-values values.yaml \
  --sync-policy automated \
  --self-heal \
  --prune || echo "App $app may already exist"

echo "Triggering sync for ArgoCD apps..."
argocd app sync "$manifests_app" --async
argocd app sync "$app" --async

# Wait for apps to become healthy
echo "Waiting for ArgoCD Applications to report Healthy + Synced + Succeeded..."

start_time=$(date +%s)

while true; do
    health_manifests=$(kubectl -n "$ARGOCD_NS" get app "$manifests_app" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "")
    sync_manifests=$(kubectl -n "$ARGOCD_NS" get app "$manifests_app" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
    phase_manifests=$(kubectl -n "$ARGOCD_NS" get app "$manifests_app" -o jsonpath='{.status.operationState.phase}' 2>/dev/null || echo "")

    health_app=$(kubectl -n "$ARGOCD_NS" get app "$app" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "")
    sync_app=$(kubectl -n "$ARGOCD_NS" get app "$app" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
    phase_app=$(kubectl -n "$ARGOCD_NS" get app "$app" -o jsonpath='{.status.operationState.phase}' 2>/dev/null || echo "")

    echo "Manifests ($manifests_app): Health=$health_manifests | Sync=$sync_manifests | Phase=$phase_manifests"
    echo "App ($app): Health=$health_app | Sync=$sync_app | Phase=$phase_app"

    if [[ "$health_manifests" == "Healthy" && "$sync_manifests" == "Synced" && "$phase_manifests" == "Succeeded" && \
          "$health_app" == "Healthy" && "$sync_app" == "Synced" && "$phase_app" == "Succeeded" ]]; then
        echo "SUCCESS: ArgoCD applications for $app are fully rolled out."
        exit 0
    fi

    now=$(date +%s)
    elapsed=$((now - start_time))
    if (( elapsed > timeout )); then
        echo "ERROR: Timeout waiting for ArgoCD apps to become healthy"
        exit 1
    fi

    sleep 10
done