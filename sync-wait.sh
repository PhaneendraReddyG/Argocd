#!/bin/bash
# Sync and wait for ArgoCD apps to be healthy
# Usage: ./sync-wait.sh --app APP --timeout SECS

set -e

app="first-app"
timeout=600

while [ "$#" -gt 0 ]; do
    case "$1" in
        --app) app="$2"; shift 2;;
        --timeout) timeout="$2"; shift 2;;
        *) echo >&2 "Unknown option: $1"; exit 1;;
    esac
done

manifests_app="${app}-manifests"

echo "Syncing ArgoCD apps for $app..."

# Workaround for argocd app wait bug
function refresh_app {
    while true; do
        sleep 120
        echo "Refreshing apps..."
        argocd app get "$manifests_app" --hard-refresh > /dev/null
        argocd app get "$app" --hard-refresh > /dev/null
    done
}
refresh_app &
refresh_pid=$!
trap 'kill $refresh_pid' EXIT

argocd app sync "$manifests_app" --async
argocd app sync "$app" --async
argocd app wait "$manifests_app" --timeout="$timeout"
argocd app wait "$app" --timeout="$timeout"

echo "SUCCESS: Apps synced and healthy."
kill $refresh_pid