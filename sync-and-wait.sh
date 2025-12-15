#!/bin/bash
# Trigger sync using ArgoCD CLI for first-app
# and wait until the ArgoCD application becomes Healthy + Synced + Succeeded
#
# Assumes ArgoCD CLI is installed and configured (e.g., logged in to localhost:8080).
# For local ArgoCD, port-forward first: kubectl port-forward svc/argocd-server -n argocd 8080:443
#
# Usage:
#   ./sync-and-wait.sh --app first-app --timeout 600

set -eu -o pipefail

# Default values
application="first-app"
timeout=600  # 10 minutes

# Options must be passed with spaces, like `--app value`
while [ "$#" -gt 0 ]; do
    case "$1" in
        --app) application="$2"; shift 2;;
        --timeout) timeout="$2"; shift 2;;
        *) echo >&2 "Unknown option: $1"; exit 1;;
    esac
done

ARGOCD_NS="argocd"

# Ask ArgoCD to start syncing the app
echo "Triggering sync for ArgoCD app: $application"
argocd app sync "$application" --async

# Wait for app to become healthy
echo "Waiting for ArgoCD Application to report Healthy + Synced + Succeeded..."

start_time=$(date +%s)

while true; do
    health=$(kubectl -n "$ARGOCD_NS" get app "$application" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "")
    sync=$(kubectl -n "$ARGOCD_NS" get app "$application" -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "")
    phase=$(kubectl -n "$ARGOCD_NS" get app "$application" -o jsonpath='{.status.operationState.phase}' 2>/dev/null || echo "")

    echo "Health=$health | Sync=$sync | Phase=$phase"

    if [[ "$health" == "Healthy" && "$sync" == "Synced" && "$phase" == "Succeeded" ]]; then
        echo "SUCCESS: ArgoCD application '$application' is fully rolled out."
        exit 0
    fi

    now=$(date +%s)
    elapsed=$((now - start_time))
    if (( elapsed > timeout )); then
        echo "ERROR: Timeout waiting for ArgoCD app to become healthy"
        exit 1
    fi

    sleep 10
done