#!/usr/bin/env bash

###############################################################################
# 07-wait-and-verify.sh
# Objetivo: Verificar que todos os serviços estão STARTED e sanity checks
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

ODP_VERSION="${ODP_VERSION:-1.2.2.0-128}"
HDFS_BIN="/usr/odp/${ODP_VERSION}/hadoop/bin/hdfs"

log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${2:-}"; }
info()  { log INFO  "$1"; }
warn()  { log WARN  "$1"; }
error() { log ERROR "$1"; }

all_services_started() {
  local states
  states=$(curl -s -u "${AMBARI_USER}:${AMBARI_PASSWORD}" \
    "http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME}/services" | \
    jq -r '.items[].ServiceInfo | "\(.service_name)=\(.state)"')
  echo "$states" | sed 's/^/ - /'
  if echo "$states" | grep -v '=STARTED' >/dev/null; then
    return 1
  fi
  return 0
}

hdfs_cmd() {
  if [[ -x "$HDFS_BIN" ]]; then
    sudo -u hdfs "$HDFS_BIN" dfs "$@"
  else
    sudo -u hdfs hdfs dfs "$@"
  fi
}

hdfs_sanity() {
  info "Sanity check HDFS: listagem raiz e safemode..."
  hdfs_cmd -ls / >/dev/null
  sudo -u hdfs hdfs dfsadmin -safemode get || true
}

yarn_sanity() {
  info "Sanity check YARN: consulta RM REST (se disponível)..."
  curl -fsS "http://master.cdp:8088/ws/v1/cluster/info" | jq '.' || true
}

main() {
  info "==== 07-wait-and-verify.sh: INÍCIO ===="
  info "Verificando estados dos serviços..."
  if all_services_started; then
    info "Todos os serviços STARTED."
  else
    warn "Alguns serviços não estão STARTED. Veja lista acima."
  fi
  hdfs_sanity || warn "HDFS sanity check reportou avisos."
  yarn_sanity || warn "YARN sanity check reportou avisos."
  info "==== 07-wait-and-verify.sh: OK ===="
}

main "$@"
