#!/usr/bin/env bash

###############################################################################
# 06-start-services.sh
# Objetivo: Iniciar todos os serviços do cluster via Ambari e monitorar
# Log: /var/log/cdp-ambari-bootstrap.log
###############################################################################

set -Eeuo pipefail

LOG_FILE="/var/log/cdp-ambari-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

AMBARI_HOST="${AMBARI_HOST:-localhost}"
AMBARI_PORT="${AMBARI_PORT:-8080}"
AMBARI_USER="${AMBARI_USER:-admin}"
AMBARI_PASSWORD="${AMBARI_PASSWORD:-admin}"
CLUSTER_NAME="${CLUSTER_NAME:-cdp-cluster}"

log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${2:-}"; }
info()  { log INFO  "$1"; }
warn()  { log WARN  "$1"; }
error() { log ERROR "$1"; }

api_put() {
  local url="$1"; shift
  curl -sS -u "${AMBARI_USER}:${AMBARI_PASSWORD}" -H "X-Requested-By: ambari" \
    -H "Content-Type: application/json" -X PUT -d "$*" "$url"
}

wait_request() {
  local req_id="$1"
  local url="http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME}/requests/${req_id}"
  info "Monitorando request ${req_id}..."
  while true; do
    local status progress
    status=$(curl -s -u "${AMBARI_USER}:${AMBARI_PASSWORD}" "$url" | jq -r '.Requests.request_status')
    progress=$(curl -s -u "${AMBARI_USER}:${AMBARI_PASSWORD}" "$url" | jq -r '.Requests.progress_percent')
    info "Status: ${status} | Progresso: ${progress}%"
    case "$status" in
      COMPLETED) info "Request ${req_id} COMPLETED."; return 0;;
      FAILED|ABORTED|TIMEDOUT) error "Request ${req_id} falhou (${status})."; return 1;;
      *) sleep 10;;
    esac
  done
}

start_all() {
  info "Iniciando todos os serviços do cluster..."
  local url resp req_id
  url="http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME}/services"
  resp=$(api_put "$url" '{"RequestInfo":{"context":"Start All Services"},"Body":{"ServiceInfo":{"state":"STARTED"}}}')
  echo "$resp" | jq '.' || true
  req_id=$(echo "$resp" | jq -r '.Requests.id // empty')
  if [[ -n "$req_id" && "$req_id" != "null" ]]; then
    wait_request "$req_id"
  else
    warn "Sem request id ao iniciar serviços (talvez já estejam STARTED)."
  fi
}

main() {
  info "==== 06-start-services.sh: INÍCIO ===="
  start_all
  info "==== 06-start-services.sh: OK ===="
}

main "$@"
