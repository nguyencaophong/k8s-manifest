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

put_file "techinsight/config/be-api-service" "config-be-api-service.yml"
put_file "techinsight/config/be-worker-service" "config-be-worker-service.yml"
put_file "techinsight/config/be-auth-service" "config-be-auth-service.yml"

# Config tĩnh DB (host, port) — template merge lấy key này + secret từ Vault
put_value "techinsight/config/db/host" "${DB_HOST:-mongo1}"
put_value "techinsight/config/db/port" "${DB_PORT:-27017}"

echo "Done. List keys: kubectl exec -n $CONSUL_NS $CONSUL_POD -- consul kv get -recurse techinsight/config/"
