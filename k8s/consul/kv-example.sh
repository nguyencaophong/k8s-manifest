#!/usr/bin/env bash
# Example: populate Consul KV with TechInsight variables (run when Consul is up)
set -e
CONSUL_ADDR="${CONSUL_HTTP_ADDR:-http://127.0.0.1:8500}"

put() { consul kv put "$1" "$2"; }

put "techinsight/config/app/environment" "production"
put "techinsight/config/app/port" "8080"
put "techinsight/config/database/mongodb_uri" "mongodb://mongo1:27017/techinsight?replicaSet=rs0"
put "techinsight/config/cache/redis_addr" "redis:6379"
put "techinsight/config/kafka/brokers" '["broker:29092"]'
put "techinsight/config/auth/grpc_addr" "be-auth-service:50051"
put "techinsight/config/elasticsearch/url" "http://elasticsearch:9200"
put "techinsight/config/features/analytics" "true"

echo "Done. List: consul kv get -recurse techinsight/"
