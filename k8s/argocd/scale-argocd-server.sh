#!/usr/bin/env bash
# Scale Argo CD server lên 3 replicas (HA).
# Argo CD mặc định cài 1 replica; chạy script này để tăng.
# Cần: kubectl trỏ đúng cluster.
set -e
REPLICAS="${1:-3}"
echo "Scaling argocd-server to $REPLICAS replicas..."
kubectl scale deployment argocd-server -n argocd --replicas="$REPLICAS"
kubectl -n argocd get deployment argocd-server
echo "Done. Kiểm tra: kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-server"
