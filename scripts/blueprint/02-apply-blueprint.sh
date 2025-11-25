#!/usr/bin/env bash

###############################################################################
# 02-apply-blueprint.sh
# Objetivo: Registrar a blueprint no Ambari (idempotente)
# - Usa /root/blueprint.json ou copia de assets/blueprint.json
# Log: /var/log/cdp-ambari-bootstrap.log
###############################################################################

set -Eeuo pipefail

LOG_FILE="/var/log/cdp-ambari-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

AMBARI_HOST="${AMBARI_HOST:-localhost}"
AMBARI_PORT="${AMBARI_PORT:-8080}"
AMBARI_USER="${AMBARI_USER:-admin}"
AMBARI_PASSWORD="${AMBARI_PASSWORD:-admin}"
BLUEPRINT_NAME="${BLUEPRINT_NAME:-default}"
BLUEPRINT_LOCAL_PATH="${BLUEPRINT_LOCAL_PATH:-/root/blueprint.json}"
BP_REPO_FALLBACK="$(cd "$(dirname "$0")" && pwd)/../../assets/blueprint.json"

log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${2:-}"; }
info()  { log INFO  "$1"; }
warn()  { log WARN  "$1"; }
error() { log ERROR "$1"; }

ensure_blueprint_file() {
  if [[ -f "$BLUEPRINT_LOCAL_PATH" ]]; then
    info "Blueprint encontrada em $BLUEPRINT_LOCAL_PATH"
    return 0
  fi
  if [[ -f "$BP_REPO_FALLBACK" ]]; then
    info "Copiando blueprint do repositório para $BLUEPRINT_LOCAL_PATH"
    cp -f "$BP_REPO_FALLBACK" "$BLUEPRINT_LOCAL_PATH"
    return 0
  fi
  error "Blueprint não encontrada. Coloque o arquivo em $BLUEPRINT_LOCAL_PATH"
  exit 1
}

exists_in_ambari() {
  curl -sf -u "${AMBARI_USER}:${AMBARI_PASSWORD}" \
    "http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/blueprints/${BLUEPRINT_NAME}" >/dev/null
}

apply_blueprint() {
  info "Aplicando blueprint '${BLUEPRINT_NAME}'..."
  local resp
  set +e
  resp=$(curl -sS -u "${AMBARI_USER}:${AMBARI_PASSWORD}" -H "X-Requested-By: ambari" \
    -H "Content-Type: application/json" -X POST \
    -d @"${BLUEPRINT_LOCAL_PATH}" \
    "http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/blueprints/${BLUEPRINT_NAME}")
  local rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    error "Falha ao aplicar blueprint (curl rc=$rc)"
    echo "$resp"
    exit 1
  fi
  echo "$resp" | jq '.' || true
  info "Blueprint aplicada."
}

main() {
  info "==== 02-apply-blueprint.sh: INÍCIO ===="
  ensure_blueprint_file
  if exists_in_ambari; then
    info "Blueprint '${BLUEPRINT_NAME}' já existe no Ambari. Pulando."
  else
    apply_blueprint
  fi
  info "==== 02-apply-blueprint.sh: OK ===="
}

main "$@"
