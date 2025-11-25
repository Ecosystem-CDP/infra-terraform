#!/usr/bin/env bash

###############################################################################
# 01-register-vdf.sh
# Objetivo: Registrar a Version Definition (VDF) ODP no Ambari
# - Copia ODP-VDF.xml para /root (se existir localmente)
# - Registra via Ambari API (idempotente)
# Log: /var/log/cdp-ambari-bootstrap.log
###############################################################################

set -Eeuo pipefail

LOG_FILE="/var/log/cdp-ambari-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

AMBARI_HOST="${AMBARI_HOST:-localhost}"
AMBARI_PORT="${AMBARI_PORT:-8080}"
AMBARI_USER="${AMBARI_USER:-admin}"
AMBARI_PASSWORD="${AMBARI_PASSWORD:-admin}"
VDF_LOCAL_PATH="${VDF_LOCAL_PATH:-/root/ODP-VDF.xml}"
VDF_REPO_FALLBACK="$(cd "$(dirname "$0")" && pwd)/../../assets/ODP-VDF.xml"

log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${2:-}"; }
info()  { log INFO  "$1"; }
warn()  { log WARN  "$1"; }
error() { log ERROR "$1"; }

ensure_vdf_file() {
  if [[ -f "$VDF_LOCAL_PATH" ]]; then
    info "VDF encontrado em $VDF_LOCAL_PATH"
    return 0
  fi
  if [[ -f "$VDF_REPO_FALLBACK" ]]; then
    info "Copiando VDF do repositório para $VDF_LOCAL_PATH"
    cp -f "$VDF_REPO_FALLBACK" "$VDF_LOCAL_PATH"
    return 0
  fi
  error "VDF não encontrado. Coloque o arquivo ODP-VDF.xml em $VDF_LOCAL_PATH"
  exit 1
}

already_registered() {
  curl -s -u "${AMBARI_USER}:${AMBARI_PASSWORD}" \
    "http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/version_definitions" | \
    jq -e '.items[]? | select(.VersionDefinition.display=="ODP-1.2.2.0")' >/dev/null
}

register_vdf() {
  info "Registrando VDF no Ambari..."
  local payload='{"VersionDefinition":{"version_url":"file:'"$VDF_LOCAL_PATH"'"}}'
  local resp
  set +e
  resp=$(curl -sS -u "${AMBARI_USER}:${AMBARI_PASSWORD}" -H "X-Requested-By: ambari" \
    -H "Content-Type: application/json" -X POST \
    -d "$payload" "http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/version_definitions")
  local rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    error "Falha ao registrar VDF (curl rc=$rc)"
    echo "$resp"
    exit 1
  fi
  echo "$resp" | jq '.' || true
  info "VDF registrado (ou já existente)."
}

main() {
  info "==== 01-register-vdf.sh: INÍCIO ===="
  ensure_vdf_file
  if already_registered; then
    info "VDF ODP-1.2.2.0 já registrado. Pulando."
  else
    register_vdf
  fi
  info "==== 01-register-vdf.sh: OK ===="
}

main "$@"
