#!/usr/bin/env bash

###############################################################################
# 03-generate-cluster-template.sh
# Objetivo: Gerar /root/cluster-template.json com 4 host_groups mapeados
# Log: /var/log/cdp-ambari-bootstrap.log
###############################################################################

set -Eeuo pipefail

LOG_FILE="/var/log/cdp-ambari-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

BLUEPRINT_NAME="${BLUEPRINT_NAME:-default}"
CLUSTER_NAME="${CLUSTER_NAME:-cdp-cluster}"
OUTPUT_PATH="${OUTPUT_PATH:-/root/cluster-template.json}"

HG1_HOST="${HG1_HOST:-master.cdp}"
HG2_HOST="${HG2_HOST:-node1.cdp}"
HG3_HOST="${HG3_HOST:-node2.cdp}"
HG4_HOST="${HG4_HOST:-node3.cdp}"

log()   { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${2:-}"; }
info()  { log INFO  "$1"; }
warn()  { log WARN  "$1"; }
error() { log ERROR "$1"; }

main() {
  info "==== 03-generate-cluster-template.sh: INÍCIO ===="
  cat > "$OUTPUT_PATH" <<EOF
{
  "blueprint": "${BLUEPRINT_NAME}",
  "default_password": "AmbariPassword123!",
  "provision_action": "INSTALL_ONLY",
  "host_groups": [
    { "name": "host_group_1", "hosts": [{"fqdn": "${HG1_HOST}"}] },
    { "name": "host_group_2", "hosts": [{"fqdn": "${HG2_HOST}"}] },
    { "name": "host_group_3", "hosts": [{"fqdn": "${HG3_HOST}"}] },
    { "name": "host_group_4", "hosts": [{"fqdn": "${HG4_HOST}"}] }
  ]
}
EOF
  chmod 0644 "$OUTPUT_PATH"
  info "Cluster template gerado em: $OUTPUT_PATH"
  info "==== 03-generate-cluster-template.sh: OK ===="
}

main "$@"
