#!/usr/bin/env bash

###############################################################################
# 04-create-cluster.sh
# Objetivo: Criar o cluster a partir do template (INSTALL_ONLY) e monitorar
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
TEMPLATE_PATH="${TEMPLATE_PATH:-/root/cluster-template.json}"

log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${2:-}"; }
info()  { log INFO  "$1"; }
warn()  { log WARN  "$1"; }
error() { log ERROR "$1"; }

cluster_exists() {
  curl -sf -u "${AMBARI_USER}:${AMBARI_PASSWORD}" \
    "http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME}" >/dev/null
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

create_cluster() {
  info "Criando cluster '${CLUSTER_NAME}' via template ${TEMPLATE_PATH} (INSTALL_ONLY)..."
  local resp req_id
  resp=$(curl -sS -u "${AMBARI_USER}:${AMBARI_PASSWORD}" -H "X-Requested-By: ambari" \
    -H "Content-Type: application/json" -X POST \
    -d @"${TEMPLATE_PATH}" \
    "http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME}")
  echo "$resp" | jq '.' || true
  req_id=$(echo "$resp" | jq -r '.Requests.id // empty')
  if [[ -z "$req_id" || "$req_id" == "null" ]]; then
    warn "Não foi possível obter request id. Pode já existir uma execução ou cluster criado."
    return 0
  fi
  wait_request "$req_id"
}

main() {
  info "==== 04-create-cluster.sh: INÍCIO ===="
  [[ -f "$TEMPLATE_PATH" ]] || { error "Template não encontrado em $TEMPLATE_PATH"; exit 1; }
  if cluster_exists; then
    info "Cluster '${CLUSTER_NAME}' já existe. Pulando criação."
  else
    create_cluster
  fi
  info "==== 04-create-cluster.sh: OK ===="
}

main "$@"
