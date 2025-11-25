#!/usr/bin/env bash

###############################################################################
# 00-validate-prereqs.sh
# Objetivo: Validar pré-requisitos antes de aplicar a Blueprint
# - Verifica Ambari API
# - Garante dependências (curl, jq)
# - Aguarda registro de hosts (padrão: 4)
# - Valida resolução básica de nomes no /etc/hosts
# Log: /var/log/cdp-ambari-bootstrap.log
###############################################################################

set -Eeuo pipefail

LOG_FILE="/var/log/cdp-ambari-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

AMBARI_HOST="${AMBARI_HOST:-localhost}"
AMBARI_PORT="${AMBARI_PORT:-8080}"
AMBARI_USER="${AMBARI_USER:-admin}"
AMBARI_PASSWORD="${AMBARI_PASSWORD:-admin}"
EXPECTED_HOSTS="${EXPECTED_HOSTS:-4}"
HOSTNAMES=("master.cdp" "node1.cdp" "node2.cdp" "node3.cdp")

log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${2:-}"; }
info()  { log INFO  "$1"; }
warn()  { log WARN  "$1"; }
error() { log ERROR "$1"; }

ensure_dependencies() {
  info "Verificando dependências (curl, jq)..."
  if ! command -v curl >/dev/null 2>&1; then
    warn "curl não encontrado. Instalando..."
    (yum -y install curl || dnf -y install curl) >/dev/null 2>&1 || true
  fi
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq não encontrado. Instalando..."
    (yum -y install jq || dnf -y install jq) >/dev/null 2>&1 || true
  fi
  command -v curl >/dev/null 2>&1 || { error "curl não disponível"; exit 1; }
  command -v jq   >/dev/null 2>&1 || { error "jq não disponível"; exit 1; }
}

check_ambari_api() {
  info "Verificando Ambari em http://${AMBARI_HOST}:${AMBARI_PORT} ..."
  if curl -fsS -u "${AMBARI_USER}:${AMBARI_PASSWORD}" \
      "http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters" >/dev/null; then
    info "Ambari API acessível."
  else
    error "Ambari API não acessível. Verifique ambari-server (porta ${AMBARI_PORT})."
    exit 1
  fi
}

check_hosts_file() {
  info "Validando /etc/hosts para FQDNs esperados..."
  local missing=0
  for hn in "${HOSTNAMES[@]}"; do
    if ! getent hosts "$hn" >/dev/null; then
      warn "Hostname não resolve: $hn (adicionar em /etc/hosts)"
      missing=$((missing+1))
    fi
  done
  if [[ $missing -gt 0 ]]; then
    warn "Alguns hostnames não resolvem. Prosseguindo, mas isso pode causar falhas."
  else
    info "Hostnames resolvendo corretamente."
  fi
}

wait_for_hosts() {
  local max_wait="${MAX_WAIT:-300}" # 5 min
  local elapsed=0
  info "Aguardando registro de ${EXPECTED_HOSTS} hosts no Ambari (até ${max_wait}s)..."
  while (( elapsed < max_wait )); do
    local count
    count=$(curl -s -u "${AMBARI_USER}:${AMBARI_PASSWORD}" \
      "http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/hosts" | jq -r '.items | length // 0') || count=0
    info "Hosts registrados: ${count}/${EXPECTED_HOSTS}"
    if [[ "$count" == "$EXPECTED_HOSTS" ]]; then
      info "Todos os hosts registrados."
      curl -s -u "${AMBARI_USER}:${AMBARI_PASSWORD}" \
        "http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/hosts" | jq -r '.items[].Hosts.host_name' | sed 's/^/ - /'
      return 0
    fi
    sleep 5; elapsed=$((elapsed+5))
  done
  error "Timeout aguardando registro de hosts."
  return 1
}

main() {
  info "==== 00-validate-prereqs.sh: INÍCIO ===="
  ensure_dependencies
  check_ambari_api
  check_hosts_file
  wait_for_hosts
  info "==== 00-validate-prereqs.sh: OK ===="
}

main "$@"
