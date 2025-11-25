# Scripts Prontos para Usar - Copy & Paste

## 1. Arquivo: `cluster-template.json`

**Localização:** `/root/cluster-template.json` ou `/tmp/cluster-template.json`

```json
{
  "blueprint": "default",
  "default_password": "AmbariPassword123!",
  "host_groups": [
    {
      "name": "host_group_1",
      "hosts": [
        {"fqdn": "master.cdp"},
        {"fqdn": "node1.cdp"},
        {"fqdn": "node2.cdp"},
        {"fqdn": "node3.cdp"}
      ]
    }
  ]
}
```

**Como usar:**
```bash
# Copiar no Master
cat > /root/cluster-template.json << 'EOF'
# Cole o conteúdo do arquivo acima aqui
EOF

chmod 644 /root/cluster-template.json
```

---

## 2. Script: `register-hosts.sh`

**Localização:** `/root/register-hosts.sh`

```bash
#!/bin/bash

###############################################################################
# Script: Register Hosts with Ambari
# Objetivo: Aguardar e verificar registro de hosts no Ambari
# Uso: bash register-hosts.sh
###############################################################################

set -e

AMBARI_HOST="localhost"
AMBARI_PORT="8080"
AMBARI_USER="admin"
AMBARI_PASSWORD="admin"
MAX_WAIT=120  # segundos

echo "======================================"
echo "Registering Hosts with Ambari"
echo "======================================"
echo ""

# Esperar por hosts registrarem
echo "Waiting for 4 hosts to register..."
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
  HOST_COUNT=$(curl -s -u ${AMBARI_USER}:${AMBARI_PASSWORD} \
    http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/hosts 2>/dev/null | jq '.items | length' 2>/dev/null || echo "0")
  
  echo "[$(date '+%H:%M:%S')] Hosts registered: $HOST_COUNT/4"
  
  if [ "$HOST_COUNT" = "4" ]; then
    echo ""
    echo "✓ All 4 hosts registered successfully!"
    
    # Listar hosts
    echo ""
    echo "Registered hosts:"
    curl -s -u ${AMBARI_USER}:${AMBARI_PASSWORD} \
      http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/hosts | \
      jq '.items[] | .Hosts.host_name' | tr -d '"' | sed 's/^/  - /'
    
    exit 0
  fi
  
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

echo ""
echo "✗ Only $HOST_COUNT hosts registered after $MAX_WAIT seconds"
echo "Troubleshooting:"
echo "1. Check Ambari Server: sudo systemctl status ambari-server"
echo "2. Check Ambari Agents: sudo ambari-agent status"
echo "3. Check agent logs: tail -50 /var/log/ambari-agent/ambari-agent.log"
exit 1
```

**Como usar:**
```bash
chmod +x /root/register-hosts.sh
bash /root/register-hosts.sh
```

---

## 3. Script: `apply-blueprint.sh`

**Localização:** `/root/apply-blueprint.sh`

```bash
#!/bin/bash

###############################################################################
# Script: Apply Ambari Blueprint
# Objetivo: Registrar blueprint e criar cluster
# Uso: bash apply-blueprint.sh
###############################################################################

set -e

AMBARI_HOST="localhost"
AMBARI_PORT="8080"
AMBARI_USER="admin"
AMBARI_PASSWORD="admin"
BLUEPRINT_FILE="${1:-/root/blueprint.json}"
TEMPLATE_FILE="${2:-/root/cluster-template.json}"
CLUSTER_NAME="${3:-cdp-cluster}"
BLUEPRINT_NAME="default"

echo "======================================"
echo "Applying Ambari Blueprint"
echo "======================================"
echo "Blueprint File: $BLUEPRINT_FILE"
echo "Template File: $TEMPLATE_FILE"
echo "Cluster Name: $CLUSTER_NAME"
echo ""

# Validar arquivos
if [ ! -f "$BLUEPRINT_FILE" ]; then
  echo "✗ Blueprint file not found: $BLUEPRINT_FILE"
  exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "✗ Template file not found: $TEMPLATE_FILE"
  exit 1
fi

# Step 1: Upload Blueprint
echo "[1/2] Uploading Blueprint..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -u ${AMBARI_USER}:${AMBARI_PASSWORD} \
  -d @${BLUEPRINT_FILE} \
  http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/blueprints/${BLUEPRINT_NAME})

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "✓ Blueprint uploaded successfully (HTTP $HTTP_CODE)"
else
  echo "✗ Failed to upload blueprint (HTTP $HTTP_CODE)"
  echo "Response: $BODY"
  exit 1
fi

# Step 2: Create Cluster
echo ""
echo "[2/2] Creating Cluster..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Content-Type: application/json" \
  -u ${AMBARI_USER}:${AMBARI_PASSWORD} \
  -d @${TEMPLATE_FILE} \
  http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME})

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "202" ]; then
  echo "✓ Cluster creation initiated (HTTP $HTTP_CODE)"
  REQUEST_ID=$(echo "$BODY" | jq -r '.Requests.id')
  echo "✓ Request ID: $REQUEST_ID"
else
  echo "✗ Failed to create cluster (HTTP $HTTP_CODE)"
  echo "Response: $BODY"
  exit 1
fi

echo ""
echo "======================================"
echo "Cluster deployment started!"
echo "======================================"
echo ""
echo "Dashboard: http://${AMBARI_HOST}:${AMBARI_PORT}"
echo "Username: ${AMBARI_USER}"
echo "Password: ${AMBARI_PASSWORD}"
echo ""
echo "To monitor progress, run:"
echo "  bash /root/monitor-deployment.sh"
echo ""
```

**Como usar:**
```bash
chmod +x /root/apply-blueprint.sh
bash /root/apply-blueprint.sh
```

---

## 4. Script: `monitor-deployment.sh`

**Localização:** `/root/monitor-deployment.sh`

```bash
#!/bin/bash

###############################################################################
# Script: Monitor Cluster Deployment
# Objetivo: Monitorar progresso da instalação do cluster
# Uso: bash monitor-deployment.sh
###############################################################################

AMBARI_HOST="localhost"
AMBARI_PORT="8080"
AMBARI_USER="admin"
AMBARI_PASSWORD="admin"
CLUSTER_NAME="${1:-cdp-cluster}"
REQUEST_ID="${2:-1}"
CHECK_INTERVAL="${3:-10}"  # segundos

echo "======================================"
echo "Monitoring Cluster Deployment"
echo "======================================"
echo "Cluster: $CLUSTER_NAME"
echo "Request ID: $REQUEST_ID"
echo "Update Interval: ${CHECK_INTERVAL}s"
echo ""
echo "Press Ctrl+C to stop monitoring"
echo ""

LAST_PROGRESS="-1"
LAST_STATUS=""

while true; do
  RESPONSE=$(curl -s -u ${AMBARI_USER}:${AMBARI_PASSWORD} \
    http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME}/requests/${REQUEST_ID} 2>/dev/null)
  
  STATUS=$(echo "$RESPONSE" | jq -r '.Requests.request_status' 2>/dev/null)
  PROGRESS=$(echo "$RESPONSE" | jq -r '.Requests.progress_percent' 2>/dev/null)
  TASK_COUNT=$(echo "$RESPONSE" | jq -r '.Requests.task_count' 2>/dev/null)
  COMPLETED=$(echo "$RESPONSE" | jq -r '.Requests.completed_task_count' 2>/dev/null)
  
  # Apenas mostrar se algo mudou
  if [ "$PROGRESS" != "$LAST_PROGRESS" ] || [ "$STATUS" != "$LAST_STATUS" ]; then
    TIMESTAMP=$(date '+%H:%M:%S')
    
    # Criar barra de progresso
    if [ -n "$PROGRESS" ] && [ "$PROGRESS" != "null" ]; then
      PERCENT=$(echo "$PROGRESS" | cut -d'.' -f1)
      FILLED=$((PERCENT / 5))
      EMPTY=$((20 - FILLED))
      BAR="["
      for ((i=0; i<FILLED; i++)); do BAR+="="; done
      for ((i=0; i<EMPTY; i++)); do BAR+="-"; done
      BAR+="]"
      
      echo "[$TIMESTAMP] $BAR ${PERCENT}% - $STATUS ($COMPLETED/$TASK_COUNT tasks)"
    else
      echo "[$TIMESTAMP] Status: $STATUS"
    fi
    
    LAST_PROGRESS=$PROGRESS
    LAST_STATUS=$STATUS
  fi
  
  # Verificar se completou ou falhou
  if [ "$STATUS" = "COMPLETED" ]; then
    echo ""
    echo "✓ Deployment COMPLETED successfully!"
    exit 0
  elif [ "$STATUS" = "FAILED" ]; then
    echo ""
    echo "✗ Deployment FAILED!"
    echo ""
    echo "Failed tasks:"
    curl -s -u ${AMBARI_USER}:${AMBARI_PASSWORD} \
      http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME}/requests/${REQUEST_ID}/tasks | \
      jq '.items[] | select(.Tasks.status=="FAILED") | {task: .Tasks.command_detail, status: .Tasks.status, error: .Tasks.stderr}' | \
      head -20
    exit 1
  fi
  
  sleep $CHECK_INTERVAL
done
```

**Como usar:**
```bash
chmod +x /root/monitor-deployment.sh
bash /root/monitor-deployment.sh cdp-cluster 1
```

---

## 5. Script: `validate-prerequisites.sh`

**Localização:** `/root/validate-prerequisites.sh`

```bash
#!/bin/bash

###############################################################################
# Script: Validate Cluster Prerequisites
# Objetivo: Validar que tudo está pronto antes de aplicar blueprint
# Uso: bash validate-prerequisites.sh
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo "======================================"
echo "Validating Cluster Prerequisites"
echo "======================================"
echo ""

# 1. Ambari Server
echo -n "1. Ambari Server Status... "
if sudo systemctl is-active --quiet ambari-server; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  ERRORS=$((ERRORS + 1))
fi

# 2. PostgreSQL
echo -n "2. PostgreSQL Server... "
if sudo systemctl is-active --quiet postgresql; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  ERRORS=$((ERRORS + 1))
fi

# 3. SSH Connectivity
echo -n "3. SSH to node1.cdp... "
if timeout 5 ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no node1.cdp "echo OK" &>/dev/null; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  ERRORS=$((ERRORS + 1))
fi

echo -n "4. SSH to node2.cdp... "
if timeout 5 ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no node2.cdp "echo OK" &>/dev/null; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  ERRORS=$((ERRORS + 1))
fi

echo -n "5. SSH to node3.cdp... "
if timeout 5 ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no node3.cdp "echo OK" &>/dev/null; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  ERRORS=$((ERRORS + 1))
fi

# 4. File Validation
echo -n "6. blueprint.json exists... "
if [ -f "/root/blueprint.json" ]; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  ERRORS=$((ERRORS + 1))
fi

echo -n "7. cluster-template.json exists... "
if [ -f "/root/cluster-template.json" ]; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  ERRORS=$((ERRORS + 1))
fi

# 5. Ambari API
echo -n "8. Ambari API Accessible... "
if curl -s -u admin:admin http://localhost:8080/api/v1/clusters/ &>/dev/null; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  ERRORS=$((ERRORS + 1))
fi

# 6. DNS Resolution
echo -n "9. DNS Resolution... "
if getent hosts master.cdp node1.cdp node2.cdp node3.cdp &>/dev/null; then
  echo -e "${GREEN}✓${NC}"
else
  echo -e "${RED}✗${NC}"
  ERRORS=$((ERRORS + 1))
fi

# Summary
echo ""
echo "======================================"
if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}All prerequisites validated!${NC}"
  echo "You can proceed with: bash /root/apply-blueprint.sh"
  exit 0
else
  echo -e "${RED}$ERRORS errors found!${NC}"
  echo "Please fix the issues above before proceeding."
  exit 1
fi
```

**Como usar:**
```bash
chmod +x /root/validate-prerequisites.sh
bash /root/validate-prerequisites.sh
```

---

## 6. Script: `quick-deploy.sh` (Tudo em Um)

**Localização:** `/root/quick-deploy.sh`

```bash
#!/bin/bash

###############################################################################
# Script: Quick Deploy - All in One
# Objetivo: Executar todo o processo de instalação do cluster
# Uso: bash quick-deploy.sh
###############################################################################

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Ambari Cluster Quick Deploy                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Validate
echo "[STEP 1/5] Validating Prerequisites..."
bash /root/validate-prerequisites.sh || exit 1
echo ""

# Step 2: Register Hosts
echo "[STEP 2/5] Registering Hosts..."
bash /root/register-hosts.sh || exit 1
echo ""

# Step 3: Apply Blueprint
echo "[STEP 3/5] Applying Blueprint..."
bash /root/apply-blueprint.sh || exit 1
echo ""

# Step 4: Monitor (com timeout de 2 horas)
echo "[STEP 4/5] Monitoring Deployment (timeout: 120 min)..."
timeout 7200 bash /root/monitor-deployment.sh cdp-cluster 1 || {
  if [ $? -eq 124 ]; then
    echo "⚠ Monitoring timeout - deployment may still be running"
  else
    echo "✗ Deployment failed"
    exit 1
  fi
}
echo ""

# Step 5: Done
echo "[STEP 5/5] Deployment Complete!"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    🎉 SUCCESS! 🎉                              ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║ Ambari Dashboard: http://localhost:8080                       ║"
echo "║ Username: admin                                               ║"
echo "║ Password: admin                                               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "1. Access Ambari Dashboard"
echo "2. Verify all services are running"
echo "3. Configure specific services (Ranger, Hive, etc)"
echo ""
```

**Como usar:**
```bash
chmod +x /root/quick-deploy.sh
bash /root/quick-deploy.sh
```

---

## 📋 Checklist de Implementação

### No seu Master (10.0.0.2)

```bash
# 1. Copiar blueprint
scp blueprint.json opc@<MASTER_IP>:/root/

# 2. Criar cluster-template.json (copiar do documento acima)
ssh opc@<MASTER_IP> "cat > /root/cluster-template.json << 'EOF'
# Cole o conteúdo do arquivo cluster-template.json
EOF"

# 3. Criar todos os scripts (copiar cada um)
ssh opc@<MASTER_IP> "cat > /root/register-hosts.sh << 'EOF'
# Cole o script register-hosts.sh
EOF"

# ... repetir para todos os scripts ...

# 4. Dar permissão de execução
ssh opc@<MASTER_IP> "chmod +x /root/*.sh"

# 5. Executar validação
ssh opc@<MASTER_IP> "bash /root/validate-prerequisites.sh"

# 6. Executar deploy completo
ssh opc@<MASTER_IP> "bash /root/quick-deploy.sh"
```

---

## 🚀 Execução Rápida (Terminal)

### Copiar e Colar - Tudo de Uma Vez

```bash
# 1. SSH para Master
ssh -i sua_chave.key opc@<MASTER_IP>

# 2. Criar todos os arquivos (cole cada bloco abaixo)

# Arquivo 1: cluster-template.json
cat > /root/cluster-template.json << 'EOF'
{
  "blueprint": "default",
  "default_password": "AmbariPassword123!",
  "host_groups": [
    {
      "name": "host_group_1",
      "hosts": [
        {"fqdn": "master.cdp"},
        {"fqdn": "node1.cdp"},
        {"fqdn": "node2.cdp"},
        {"fqdn": "node3.cdp"}
      ]
    }
  ]
}
EOF

# Arquivo 2: blueprint.json (já existe? se não, copiar)
# scp blueprint.json opc@<MASTER_IP>:/root/

# 3. Validar que tudo está pronto
curl -s -u admin:admin http://localhost:8080/api/v1/hosts | jq '.items | length'
# Esperado: 4

# 4. Registrar blueprint
curl -X POST -H "Content-Type: application/json" -u admin:admin \
  -d @/root/blueprint.json \
  http://localhost:8080/api/v1/blueprints/default

# 5. Criar cluster
curl -X POST -H "Content-Type: application/json" -u admin:admin \
  -d @/root/cluster-template.json \
  http://localhost:8080/api/v1/clusters/cdp-cluster

# 6. Monitorar progresso
watch -n 5 'curl -s -u admin:admin http://localhost:8080/api/v1/clusters/cdp-cluster/requests/1 | jq "{status: .Requests.request_status, progress: .Requests.progress_percent}"'
```

---

## ⏱️ Tempo Estimado

| Etapa | Tempo |
|-------|-------|
| Validação | 1-2 min |
| Registro de Hosts | 2-5 min |
| Upload Blueprint | 1 min |
| Criação do Cluster | 1 min |
| **Instalação dos Serviços** | **20-40 min** |
| **TOTAL** | **25-50 min** |

---

**Versão:** 1.0  
**Pronto para usar:** ✅  
**Última atualização:** Novembro 2025