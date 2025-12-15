#!/bin/bash
# Deploy using Skaffold
# Usage: ./deploy.sh --app APP

set -e

app="first-app"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --app) app="$2"; shift 2;;
        *) echo >&2 "Unknown option: $1"; exit 1;;
    esac
done

echo "Deploying $app using Skaffold..."

skaffold run

echo "App deployed."