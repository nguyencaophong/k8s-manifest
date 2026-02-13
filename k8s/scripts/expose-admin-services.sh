#!/usr/bin/env bash
# Expose Argo CD, Vault, Consul qua NodePort để truy cập bằng IP (vd: http(s)://76.13.182.234:PORT).
# Chạy: ./expose-admin-services.sh
# Hoặc: ADMIN_IP=192.168.1.1 ./expose-admin-services.sh
set -e

ADMIN_IP="${ADMIN_IP:-76.13.182.234}"
# NodePorts (trong dải 30000-32767)
ARGOCD_NP="${ARGOCD_NODEPORT:-30443}"
VAULT_NP="${VAULT_NODEPORT:-30820}"
CONSUL_NP="${CONSUL_NODEPORT:-30850}"

echo "Exposing admin services (NodePort). IP for URLs: $ADMIN_IP"
echo ""

# Argo CD
if kubectl get svc argocd-server -n argocd &>/dev/null; then
  kubectl patch svc argocd-server -n argocd --type merge -p "{\"spec\":{\"type\":\"NodePort\",\"ports\":[{\"port\":443,\"nodePort\":$ARGOCD_NP}]}}"
  echo "  Argo CD:  https://${ADMIN_IP}:${ARGOCD_NP}"
else
  echo "  Argo CD:  (service argocd-server not found in namespace argocd)"
fi

# Vault (tên service có thể là vault hoặc vault-active)
if kubectl get svc vault -n vault &>/dev/null; then
  kubectl patch svc vault -n vault --type merge -p "{\"spec\":{\"type\":\"NodePort\",\"ports\":[{\"port\":8200,\"nodePort\":$VAULT_NP}]}}"
  echo "  Vault:    http://${ADMIN_IP}:${VAULT_NP}"
elif kubectl get svc vault-active -n vault &>/dev/null; then
  kubectl patch svc vault-active -n vault --type merge -p "{\"spec\":{\"type\":\"NodePort\",\"ports\":[{\"port\":8200,\"nodePort\":$VAULT_NP}]}}"
  echo "  Vault:    http://${ADMIN_IP}:${VAULT_NP}"
else
  echo "  Vault:    (no service vault/vault-active in namespace vault)"
fi

# Consul (UI thường trên consul-server:8500)
if kubectl get svc consul-server -n consul &>/dev/null; then
  kubectl patch svc consul-server -n consul --type merge -p "{\"spec\":{\"type\":\"NodePort\",\"ports\":[{\"name\":\"http\",\"port\":8500,\"nodePort\":$CONSUL_NP}]}}"
  echo "  Consul:   http://${ADMIN_IP}:${CONSUL_NP}"
else
  echo "  Consul:   (service consul-server not found in namespace consul)"
fi

echo ""
echo "Mở firewall nếu cần: ufw allow ${ARGOCD_NP}/tcp && ufw allow ${VAULT_NP}/tcp && ufw allow ${CONSUL_NP}/tcp && ufw reload"
echo "Chi tiết: k8s/EXPOSE-ADMIN-SERVICES.md"
