#!/usr/bin/env bash
# Load TechInsight config (environment) into Consul KV.
# Usage 1 (Consul CLI local): CONSUL_HTTP_ADDR=http://localhost:8500 ./load-config-into-consul.sh
# Usage 2 (không cài consul CLI): dùng kubectl exec vào pod Consul trong cluster:
#   ./load-config-into-consul.sh
#   Script tự dùng kubectl exec -n consul deploy/consul-server nếu không tìm thấy lệnh consul.
set -e
cd "$(dirname "$0")"

CONSUL_ADDR="${CONSUL_HTTP_ADDR:-http://localhost:8500}"
export CONSUL_HTTP_ADDR="$CONSUL_ADDR"
CONSUL_NS="${CONSUL_NAMESPACE:-consul}"

# Consul Helm thường tạo StatefulSet consul-server (pod consul-server-0), không phải Deployment
CONSUL_POD="${CONSUL_POD:-consul-server-0}"
use_kubectl() {
  kubectl exec -i -n "$CONSUL_NS" "$CONSUL_POD" -- "$@"
}

put_file() {
  local key="$1"
  local file="$2"
  if [ ! -f "$file" ]; then
    echo "Missing $file"
    return 1
  fi
  if command -v consul &>/dev/null; then
    consul kv put "$key" @"$file"
  else
    cat "$file" | use_kubectl consul kv put "$key" -
  fi
  echo "Loaded $key from $file"
}

put_value() {
  local key="$1"
  local val="$2"
  if command -v consul &>/dev/null; then
    consul kv put "$key" "$val"
  else
    use_kubectl consul kv put "$key" "$val"
  fi
  echo "Loaded $key"
}

put_file "techinsight/templates/core-service" "tpl-core-service.yml"
put_file "techinsight/templates/auth-service" "tpl-auth-service.yml"
put_file "techinsight/templates/be-worker-service" "tpl-be-worker-service.yml"

echo "Done. Templates loaded into Consul KV (consul-template sẽ merge với Vault secrets)."
echo "List keys: kubectl exec -n $CONSUL_NS $CONSUL_POD -c consul -- consul kv get -keys -recurse techinsight/"
