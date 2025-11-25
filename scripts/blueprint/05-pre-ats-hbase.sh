#!/usr/bin/env bash

###############################################################################
# 05-pre-ats-hbase.sh
# Objetivo: Executar passo manual pré-ATS (upload do bundle HBase no HDFS)
# - Inicia HDFS (apenas) via Ambari
# - Cria diretório HDFS e faz upload do hbase.tar.gz
# - Ajusta permissões e ownership
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

# Versão ODP para caminhos
ODP_VERSION="${ODP_VERSION:-1.2.2.0-128}"
HDFS_BIN="/usr/odp/${ODP_VERSION}/hadoop/bin/hdfs"
SRC_TAR="/var/lib/ambari-agent/tmp/yarn-ats/${ODP_VERSION}/hbase.tar.gz"
DEST_DIR="/odp/apps/${ODP_VERSION}/hbase"
DEST_TAR="${DEST_DIR}/hbase.tar.gz"

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
      *) sleep 8;;
    esac
  done
}

start_hdfs_only() {
  info "Iniciando apenas HDFS via Ambari..."
  local resp req_id url
  url="http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME}/services/HDFS"
  resp=$(api_put "$url" '{"RequestInfo":{"context":"Start HDFS"},"ServiceInfo":{"state":"STARTED"}}')
  echo "$resp" | jq '.' || true
  req_id=$(echo "$resp" | jq -r '.Requests.id // empty')
  if [[ -n "$req_id" && "$req_id" != "null" ]]; then
    wait_request "$req_id"
  else
    warn "Sem request id ao iniciar HDFS (talvez já esteja STARTED)."
  fi
}

hdfs_cmd() {
  if [[ -x "$HDFS_BIN" ]]; then
    sudo -u hdfs "$HDFS_BIN" dfs "$@"
  else
    sudo -u hdfs hdfs dfs "$@"
  fi
}

ensure_hdfs_ready() {
  info "Verificando acesso ao HDFS..."
  hdfs_cmd -ls / >/dev/null 2>&1 || { error "HDFS não acessível. Verifique serviços HDFS."; exit 1; }
}

upload_ats_bundle() {
  info "Executando preparo do bundle HBase para ATS no HDFS..."

  if hdfs_cmd -test -e "$DEST_TAR"; then
    info "Arquivo já existe em $DEST_TAR. Validando permissões..."
  else
    info "Criando diretório de destino: $DEST_DIR"
    hdfs_cmd -mkdir -p "$DEST_DIR" || true

    if [[ -f "$SRC_TAR" ]]; then
      info "Enviando pacote: $SRC_TAR -> $DEST_DIR/"
      hdfs_cmd -put -f "$SRC_TAR" "$DEST_DIR/"
    else
      warn "Pacote fonte não encontrado: $SRC_TAR"
      warn "Verifique instalação do YARN ATS; você pode prosseguir e iniciar serviços, mas ATS pode falhar."
      return 0
    fi
  fi

  info "Ajustando permissões (444) e ownership (hdfs:hdfs)"
  hdfs_cmd -chmod 444 "$DEST_TAR" || true
  hdfs_cmd -chown hdfs:hdfs "$DEST_DIR" || true

  info "Listando destino: $DEST_DIR"
  hdfs_cmd -ls -h "$DEST_DIR" || true
}

main() {
  info "==== 05-pre-ats-hbase.sh: INÍCIO ===="
  start_hdfs_only
  ensure_hdfs_ready
  upload_ats_bundle
  info "==== 05-pre-ats-hbase.sh: OK ===="
}

main "$@"
