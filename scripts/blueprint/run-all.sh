#!/usr/bin/env bash

###############################################################################
# run-all.sh
# Orquestra a execução completa da criação do cluster via Ambari Blueprint
# Etapas:
#  00 -> Validar pré-requisitos
#  01 -> Registrar VDF ODP
#  02 -> Aplicar Blueprint
#  03 -> Gerar template do cluster (INSTALL_ONLY)
#  04 -> Criar cluster e aguardar conclusão da instalação
#  05 -> Passo pré-ATS (upload HBase bundle no HDFS)
#  06 -> Iniciar todos os serviços
#  07 -> Verificar estados e sanity checks
# Log: /var/log/cdp-ambari-bootstrap.log
###############################################################################

set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="/var/log/cdp-ambari-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

export AMBARI_HOST="${AMBARI_HOST:-localhost}"
export AMBARI_PORT="${AMBARI_PORT:-8080}"
export AMBARI_USER="${AMBARI_USER:-admin}"
export AMBARI_PASSWORD="${AMBARI_PASSWORD:-admin}"
export BLUEPRINT_NAME="${BLUEPRINT_NAME:-default}"
export CLUSTER_NAME="${CLUSTER_NAME:-cdp-cluster}"
export ODP_VERSION="${ODP_VERSION:-1.2.2.0-128}"

step() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [STEP] $*"; }

main() {
  step "00 - Validando pré-requisitos"
  bash "$BASE_DIR/00-validate-prereqs.sh"

  step "01 - Registrando VDF"
  bash "$BASE_DIR/01-register-vdf.sh"

  step "02 - Aplicando Blueprint"
  bash "$BASE_DIR/02-apply-blueprint.sh"

  step "03 - Gerando cluster-template.json"
  bash "$BASE_DIR/03-generate-cluster-template.sh"

  step "04 - Criando cluster (INSTALL_ONLY)"
  bash "$BASE_DIR/04-create-cluster.sh"

  step "05 - Executando passo pré-ATS (HDFS/HBase bundle)"
  bash "$BASE_DIR/05-pre-ats-hbase.sh"

  step "06 - Iniciando serviços do cluster"
  bash "$BASE_DIR/06-start-services.sh"

  step "07 - Verificando estado dos serviços e sanity checks"
  bash "$BASE_DIR/07-wait-and-verify.sh"

  echo "[DONE] Fluxo concluído. Veja logs em: $LOG_FILE"
}

main "$@"
