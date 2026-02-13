#!/usr/bin/env bash
# Load TechInsight config (environment) into Consul KV.
# Usage: CONSUL_HTTP_ADDR=http://localhost:8500 ./load-config-into-consul.sh
# Or: kubectl exec -it -n consul deploy/consul-server -- consul kv put ...
set -e
cd "$(dirname "$0")"

CONSUL_ADDR="${CONSUL_HTTP_ADDR:-http://localhost:8500}"
export CONSUL_HTTP_ADDR="$CONSUL_ADDR"

put_file() {
  local key="$1"
  local file="$2"
  if [ ! -f "$file" ]; then
    echo "Missing $file"
    return 1
  fi
  consul kv put "$key" @"$file"
  echo "Loaded $key from $file"
}

put_file "techinsight/config/be-api-service" "config-be-api-service.yml"
put_file "techinsight/config/be-worker-service" "config-be-worker-service.yml"
put_file "techinsight/config/be-auth-service" "config-be-auth-service.yml"

echo "Done. List: consul kv get -recurse techinsight/config/"
