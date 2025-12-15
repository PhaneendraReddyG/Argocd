#!/bin/bash
# Wrapper script to create apps and sync/wait
# Usage: ./deploy.sh --app APP --timeout SECS

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

./create-apps.sh --app "$app"
./sync-wait.sh --app "$app" --timeout "$timeout"