#!/bin/bash

# Automated deployment script for first-app via ArgoCD
# This script applies the ArgoCD Applications and monitors the deployment.

set -e  # Exit on any error

echo "Applying ArgoCD Applications for first-app..."
kubectl apply -k applications/first-app/install

echo "Waiting for Applications to be created..."
kubectl wait --for=condition=available --timeout=300s application/first-app-manifests -n argocd
kubectl wait --for=condition=available --timeout=300s application/first-app -n argocd

echo "Checking sync status..."
argocd app get first-app-manifests --hard-refresh
argocd app get first-app --hard-refresh

echo "Deployment complete. Access ArgoCD UI at http://localhost:8080 (run 'kubectl port-forward svc/argocd-server -n argocd 8080:443' in another terminal)."
echo "Check app status: kubectl get pods -n first-app"