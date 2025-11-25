# Guia Completo: Automação de Instalação de Cluster Ambari com Blueprint

## 📋 Índice
1. [Status Atual](#status-atual)
2. [Requisitos](#requisitos)
3. [Procedimento de Instalação](#procedimento-de-instalação)
4. [Scripts Necessários](#scripts-necessários)
5. [Próximos Passos](#próximos-passos)

---

## Status Atual

### ✅ O que você JÁ tem implementado

```
Infrastructure (Terraform + OCI)
├── Master node: master.cdp (10.0.0.2)
├── Worker 1: node1.cdp (10.0.0.3)
├── Worker 2: node2.cdp (10.0.0.4)
└── Worker 3: node3.cdp (10.0.0.5)

Sistema Operacional & Componentes (via Scripts Bash)
├── Oracle Linux 9 (atualizado)
├── Java 1.8.0 OpenJDK
├── Ambari Server (no Master)
├── Ambari Agents (em todos os nós)
├── PostgreSQL (no Master)
└── SSH configurado

Stack
└── Open Source Data Platform (ODP) 1.2.2.0-128
    ├── HDP services (Hadoop, Hive, Spark, etc)
    ├── Zookeeper, Kafka
    ├── NiFi, Ranger
    └── Livy, Atlas
```

### 📊 Progresso Atual: 70%

**Estado das máquinas após terraform apply:**
- ✅ VMs provisionadas na OCI
- ✅ Sistema operacional atualizado
- ✅ Ambari Server rodando (Master porta 8080)
- ✅ Ambari Agents instalados e inicializados
- ✅ Conectividade SSH entre nós
- ✅ PostgreSQL servidor rodando
- ❌ **Hosts NÃO registrados no Ambari**
- ❌ **Blueprint NÃO aplicada**
- ❌ **Serviços NÃO instalados**
- ❌ **Cluster NÃO inicializado**

---

## Requisitos

### Pré-requisitos Verificados ✅

```bash
# No Master (ambari-server)
✅ Java 1.8.0 instalado
✅ Ambari Server version 2.7.9.0.0-61
✅ PostgreSQL server rodando
✅ Portas abertas (8080, 8443, 50070, etc)
✅ /etc/hosts com DNS local

# Em todos os nós
✅ Java 1.8.0 instalado
✅ Ambari Agent versão 2.7.9.0.0-61
✅ Conectividade SSH (chave adicionada a authorized_keys)
✅ Chronyd sincronizado
✅ Firewall desabilitado
✅ SELinux em modo permissivo
✅ ODP 1.2.2.0-128 repos configurados
✅ odp-select instalado
```

### Arquivos Já Disponíveis

```
📦 Você HÁ TEM:
├── blueprint.json (441KB) - Configuração completa dos serviços
├── ODP-VDF.xml (2.6KB) - Version Definition File do ODP
├── InstallMaster.sh - Preparação do master
├── InstallWorker.sh - Preparação dos workers
└── Terraform IaC - Infraestrutura
```

### Arquivos que FALTAM

```
📦 VOCÊ PRECISA CRIAR:
├── cluster-register-hosts.sh
├── validate-cluster-prerequisites.sh
├── create-cluster-template.json
├── apply-blueprint.sh
├── wait-cluster-deployment.sh
├── post-install-configuration.sh
└── cleanup-on-failure.sh
```

---

## Procedimento de Instalação

### Fase 1: Verificação de Pré-requisitos (5-10 min)

**Objetivo:** Garantir que o ambiente está pronto antes de aplicar a blueprint

#### 1.1 Verificar Conectividade SSH e Ambari Agents

```bash
# No Master (10.0.0.2)
ssh -i sua_chave.key opc@10.0.0.2

# Verificar status dos agents
sudo ambari-agent status
# Esperado: "Agent PID at: /var/run/ambari-agent/ambari-agent.pid"

# Verificar conectividade com workers
ping -c 1 10.0.0.3  # node1
ping -c 1 10.0.0.4  # node2
ping -c 1 10.0.0.5  # node3

# Verificar SSH sem senha de cada worker
ssh node1.cdp "echo OK"
ssh node2.cdp "echo OK"
ssh node3.cdp "echo OK"
```

#### 1.2 Validar Ambari Server

```bash
# Verificar status do server
sudo systemctl status ambari-server
# Esperado: "active (running)"

# Verificar logs
sudo tail -100 /var/log/ambari-server/ambari-server.log

# Testar acesso via curl
curl -s -u admin:admin http://localhost:8080/api/v1/clusters/ | jq '.'
# Esperado: resposta JSON sem clusters (ainda vazio)
```

#### 1.3 Validar PostgreSQL

```bash
# Verificar se PostgreSQL está rodando
sudo systemctl status postgresql
# Esperado: "active (running)"

# Testar conexão
sudo -u postgres psql -l
# Verificar se database 'ambari' existe

# Testar usuario ambari
sudo -u postgres psql -U ambari -d ambari -c "SELECT 1;"
# Esperado: retorna "1"
```

#### 1.4 Verificar Ambari Agents em Todos os Nós

```bash
# Em cada worker (node1, node2, node3)
ssh node1.cdp
sudo ambari-agent status
sudo ambari-agent stop
sudo ambari-agent start
sudo tail -20 /var/log/ambari-agent/ambari-agent.log

# Repetir para node2 e node3
```

---

### Fase 2: Descoberta e Registro de Hosts (5 min)

**Objetivo:** Ambari descobrir e registrar os hosts agents conectados

#### 2.1 Aguardar Descoberta Automática

```bash
# Os agents se registram automaticamente
# Verificar via API do Ambari (esperar até 1-2 minutos)

for i in {1..12}; do
  echo "Tentativa $i ($(($i * 5))s)..."
  curl -s -u admin:admin http://localhost:8080/api/v1/hosts | jq '.items[].Hosts.host_name'
  [ $(curl -s -u admin:admin http://localhost:8080/api/v1/hosts | jq '.items | length') -eq 4 ] && break
  sleep 5
done

# Esperado: 4 hosts listados
# master.cdp
# node1.cdp
# node2.cdp
# node3.cdp
```

#### 2.2 Verificar via UI (Alternativa)

```
Acessar: http://<MASTER_IP>:8080
Usuário: admin
Senha: admin

Menu > Hosts
- Você deverá ver 4 hosts listados
- Status: "Up to Date" em verde
```

#### 2.3 Monitorar Logs se Hosts NÃO Aparecerem

```bash
# No Master
tail -f /var/log/ambari-server/ambari-server.log | grep -i "agent"

# No Worker (ex: node1)
tail -f /var/log/ambari-agent/ambari-agent.log | grep -i "error"

# Troubleshoot comum:
# - Verificar arquivo: /etc/ambari-agent/conf/ambari-agent.ini
#   Deve conter: hostname=master.cdp
sudo cat /etc/ambari-agent/conf/ambari-agent.ini
```

---

### Fase 3: Preparação da Blueprint (5 min)

**Objetivo:** Customizar blueprint e criar template de cluster

#### 3.1 Analisar Blueprint Atual

Seu `blueprint.json` já está bem estruturado com:
- ✅ Zookeeper, HBase, HDFS, YARN
- ✅ Hive, Spark3, Kafka
- ✅ NiFi, Ranger, Livy
- ✅ Atlas, Ambari components

Estrutura esperada:
```json
{
  "Blueprints": {
    "blueprint_name": "default"
  },
  "host_groups": [
    {
      "name": "host_group_1",
      "components": [...]
    },
    {
      "name": "host_group_2",
      "components": [...]
    }
  ],
  "configurations": [...]
}
```

#### 3.2 Criar Template JSON (Host Mapping)

Crie arquivo: `/tmp/cluster-template.json`

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
    },
    {
      "name": "host_group_2",
      "hosts": [
        {"fqdn": "node1.cdp"},
        {"fqdn": "node2.cdp"},
        {"fqdn": "node3.cdp"}
      ]
    }
  ]
}
```

**NOTA IMPORTANTE:** Analise o seu `blueprint.json` para identificar:
- Quantos `host_groups` existem?
- Quais componentes vão em cada group?

```bash
# Verificar host groups no blueprint
jq '.host_groups[].name' blueprint.json

# Verificar componentes por grupo
jq '.host_groups[] | {name: .name, components: .components[].component_name}' blueprint.json
```

---

### Fase 4: Registro da Blueprint no Ambari (2 min)

**Objetivo:** Enviar blueprint para Ambari via API

#### 4.1 Upload da Blueprint

```bash
# Copiar blueprint para /tmp no Master
scp blueprint.json opc@10.0.0.2:/tmp/

# No Master, registrar blueprint
BLUEPRINT_NAME="default"  # Ou o nome que você escolheu

curl -X POST \
  -H "Content-Type: application/json" \
  -u admin:admin \
  -d @/tmp/blueprint.json \
  http://localhost:8080/api/v1/blueprints/$BLUEPRINT_NAME

# Esperado: HTTP 201 Created
```

#### 4.2 Verificar Registro

```bash
# Listar blueprints
curl -s -u admin:admin http://localhost:8080/api/v1/blueprints | jq '.items[].Blueprints.blueprint_name'

# Obter detalhes
curl -s -u admin:admin http://localhost:8080/api/v1/blueprints/default | jq '.'
```

---

### Fase 5: Criação do Cluster (10-15 min)

**Objetivo:** Aplicar blueprint e iniciar instalação dos serviços

#### 5.1 Criar Cluster via API

```bash
# Substituir template conforme necessário
curl -X POST \
  -H "Content-Type: application/json" \
  -u admin:admin \
  -d @/tmp/cluster-template.json \
  http://localhost:8080/api/v1/clusters/cdp-cluster

# Esperado: HTTP 202 Accepted
# A instalação começará automaticamente
```

**RESP OSTA ESPERADA:**
```json
{
  "href": "http://master.cdp:8080/api/v1/clusters/cdp-cluster",
  "Requests": {
    "id": 1,
    "href": "http://master.cdp:8080/api/v1/clusters/cdp-cluster/requests/1"
  }
}
```

#### 5.2 Monitorar Progresso de Instalação

```bash
# Verificar status de tasks
CLUSTER_NAME="cdp-cluster"
REQUEST_ID="1"

# Status em tempo real
watch -n 5 'curl -s -u admin:admin http://localhost:8080/api/v1/clusters/'$CLUSTER_NAME'/requests/'$REQUEST_ID | jq ".Requests | {id, status, progress_percent, task_count}"'

# Ou via logs
tail -f /var/log/ambari-server/ambari-server.log | grep -i "task"

# Verificar tasks com erro
curl -s -u admin:admin 'http://localhost:8080/api/v1/clusters/cdp-cluster/requests/1/tasks?fields=Tasks/status' | jq '.items[] | select(.Tasks.status=="FAILED")'
```

#### 5.3 Duração Esperada

- **Tempo total: 20-40 minutos** dependendo de:
  - Tamanho da blueprint
  - Número de serviços
  - Performance das máquinas
  - Velocidade de download de pacotes

**Marcos importantes:**
- 5 min: Hosts reporting OK
- 10 min: HDFS formatado
- 15 min: YARN iniciando
- 25 min: Hive e Spark compilando
- 35 min: Serviços estabilizando
- 40 min: Dashboard mostrando tudo verde

---

### Fase 6: Validação Pós-Instalação (5-10 min)

**Objetivo:** Verificar que todos os serviços estão rodando corretamente

#### 6.1 Via UI Ambari

```
Dashboard > Summary
✅ Esperado: Nenhum serviço em estado CRITICAL ou UNKNOWN
✅ Status: Todos em "STARTED" ou "INSTALLED"
```

#### 6.2 Via CLI

```bash
# Verificar status dos serviços
curl -s -u admin:admin http://localhost:8080/api/v1/clusters/cdp-cluster/services | \
  jq '.items[] | {name: .ServiceInfo.service_name, state: .ServiceInfo.state}'

# Resultado esperado:
# ZOOKEEPER: STARTED
# HDFS: STARTED
# YARN: STARTED
# HIVE: INSTALLED (ou STARTED)
# ... outros serviços
```

#### 6.3 Verificar Componentes Críticos

```bash
# HDFS Health
hdfs dfs -ls /

# YARN ResourceManager
yarn node -list

# HBase (se instalado)
hbase shell
> status
> quit

# Zookeeper
echo ruok | nc localhost 2181

# Hive Metastore (se aplicável)
beeline -u jdbc:hive2://master.cdp:10000
> SHOW TABLES;
```

---

## Scripts Necessários

### 1. `validate-cluster-prerequisites.sh`

```bash
#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "======================================"
echo "Validating Cluster Prerequisites"
echo "======================================"

# Verificar conectividade SSH
echo ""
echo -e "${YELLOW}[1/5] Checking SSH Connectivity...${NC}"
for host in node1.cdp node2.cdp node3.cdp; do
  if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no $host "echo OK" &>/dev/null; then
    echo -e "${GREEN}✓ $host${NC}"
  else
    echo -e "${RED}✗ $host${NC}"
    exit 1
  fi
done

# Verificar Ambari Server
echo ""
echo -e "${YELLOW}[2/5] Checking Ambari Server...${NC}"
if sudo systemctl is-active --quiet ambari-server; then
  echo -e "${GREEN}✓ Ambari Server running${NC}"
else
  echo -e "${RED}✗ Ambari Server not running${NC}"
  exit 1
fi

# Verificar PostgreSQL
echo ""
echo -e "${YELLOW}[3/5] Checking PostgreSQL...${NC}"
if sudo systemctl is-active --quiet postgresql; then
  echo -e "${GREEN}✓ PostgreSQL running${NC}"
else
  echo -e "${RED}✗ PostgreSQL not running${NC}"
  exit 1
fi

# Verificar Agents
echo ""
echo -e "${YELLOW}[4/5] Checking Ambari Agents...${NC}"
for host in node1.cdp node2.cdp node3.cdp; do
  if ssh -o ConnectTimeout=5 $host "sudo systemctl is-active --quiet ambari-agent"; then
    echo -e "${GREEN}✓ Agent at $host${NC}"
  else
    echo -e "${RED}✗ Agent at $host not running${NC}"
    exit 1
  fi
done

# Verificar DNS Resolution
echo ""
echo -e "${YELLOW}[5/5] Checking DNS Resolution...${NC}"
for host in master.cdp node1.cdp node2.cdp node3.cdp; do
  if getent hosts $host >/dev/null; then
    echo -e "${GREEN}✓ $host resolves${NC}"
  else
    echo -e "${RED}✗ $host does not resolve${NC}"
    exit 1
  fi
done

echo ""
echo -e "${GREEN}All prerequisites validated!${NC}"
```

### 2. `apply-blueprint.sh`

```bash
#!/bin/bash

set -e

# Variáveis
AMBARI_HOST="localhost"
AMBARI_PORT="8080"
AMBARI_USER="admin"
AMBARI_PASSWORD="admin"
BLUEPRINT_FILE="${1:-blueprint.json}"
CLUSTER_NAME="${2:-cdp-cluster}"
TEMPLATE_FILE="${3:-cluster-template.json}"

echo "======================================"
echo "Applying Blueprint to Cluster"
echo "======================================"
echo "Cluster Name: $CLUSTER_NAME"
echo "Blueprint File: $BLUEPRINT_FILE"
echo ""

# Step 1: Upload Blueprint
echo "[1/3] Uploading Blueprint..."
BLUEPRINT_NAME=$(jq -r '.Blueprints.blueprint_name' $BLUEPRINT_FILE)

curl -X POST \
  -H "Content-Type: application/json" \
  -u ${AMBARI_USER}:${AMBARI_PASSWORD} \
  -d @${BLUEPRINT_FILE} \
  http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/blueprints/${BLUEPRINT_NAME} \
  || { echo "Failed to upload blueprint"; exit 1; }

echo "✓ Blueprint uploaded: $BLUEPRINT_NAME"

# Step 2: Wait for hosts to register
echo ""
echo "[2/3] Waiting for hosts to register..."
HOST_COUNT=0
MAX_WAIT=60
ELAPSED=0

while [ $HOST_COUNT -lt 4 ] && [ $ELAPSED -lt $MAX_WAIT ]; do
  HOST_COUNT=$(curl -s -u ${AMBARI_USER}:${AMBARI_PASSWORD} \
    http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/hosts | jq '.items | length')
  echo "  Hosts found: $HOST_COUNT/4 (waited ${ELAPSED}s)"
  if [ $HOST_COUNT -lt 4 ]; then
    sleep 5
    ELAPSED=$((ELAPSED + 5))
  fi
done

if [ $HOST_COUNT -lt 4 ]; then
  echo "✗ Only $HOST_COUNT hosts registered (expected 4)"
  exit 1
fi

echo "✓ All 4 hosts registered"

# Step 3: Create Cluster
echo ""
echo "[3/3] Creating Cluster..."

curl -X POST \
  -H "Content-Type: application/json" \
  -u ${AMBARI_USER}:${AMBARI_PASSWORD} \
  -d @${TEMPLATE_FILE} \
  http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME} \
  || { echo "Failed to create cluster"; exit 1; }

echo "✓ Cluster creation initiated"
echo ""
echo "======================================"
echo "Cluster deployment started!"
echo "Access dashboard: http://${AMBARI_HOST}:${AMBARI_PORT}"
echo "To monitor progress:"
echo "  curl -u ${AMBARI_USER}:${AMBARI_PASSWORD} \\"
echo "    http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME}/requests/1"
echo "======================================"
```

### 3. `wait-cluster-deployment.sh`

```bash
#!/bin/bash

set -e

# Variáveis
AMBARI_HOST="localhost"
AMBARI_PORT="8080"
AMBARI_USER="admin"
AMBARI_PASSWORD="admin"
CLUSTER_NAME="${1:-cdp-cluster}"
REQUEST_ID="${2:-1}"
MAX_WAIT=3600  # 1 hora em segundos

echo "======================================"
echo "Waiting for Cluster Deployment"
echo "======================================"
echo "Cluster: $CLUSTER_NAME"
echo "Request ID: $REQUEST_ID"
echo "Max Wait: $((MAX_WAIT/60)) minutes"
echo ""

ELAPSED=0
LAST_PROGRESS=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
  RESPONSE=$(curl -s -u ${AMBARI_USER}:${AMBARI_PASSWORD} \
    http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME}/requests/${REQUEST_ID})
  
  STATUS=$(echo $RESPONSE | jq -r '.Requests.request_status')
  PROGRESS=$(echo $RESPONSE | jq -r '.Requests.progress_percent')
  
  if [ "$PROGRESS" != "$LAST_PROGRESS" ]; then
    echo "[$(date '+%H:%M:%S')] Progress: ${PROGRESS}% - Status: $STATUS"
    LAST_PROGRESS=$PROGRESS
  fi
  
  if [ "$STATUS" == "COMPLETED" ]; then
    echo ""
    echo "✓ Cluster deployment COMPLETED"
    exit 0
  elif [ "$STATUS" == "FAILED" ]; then
    echo ""
    echo "✗ Cluster deployment FAILED"
    exit 1
  fi
  
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

echo ""
echo "✗ Deployment timeout after $((MAX_WAIT/60)) minutes"
exit 1
```

### 4. `post-install-configuration.sh`

```bash
#!/bin/bash

set -e

AMBARI_HOST="localhost"
AMBARI_PORT="8080"
AMBARI_USER="admin"
AMBARI_PASSWORD="admin"
CLUSTER_NAME="${1:-cdp-cluster}"

echo "======================================"
echo "Post-Install Configuration"
echo "======================================"

# 1. Configure Hive Database
echo "[1/4] Configuring Hive Database..."
ssh master.cdp << 'EOF'
  sudo -u postgres psql -c "CREATE DATABASE hive;" 2>/dev/null || true
  sudo -u postgres psql -c "CREATE USER hive WITH PASSWORD 'hive';" 2>/dev/null || true
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE hive TO hive;" 2>/dev/null || true
  echo "✓ Hive database configured"
EOF

# 2. Initialize HDFS (Format)
echo "[2/4] Initializing HDFS..."
ssh master.cdp << 'EOF'
  hdfs dfs -ls / >/dev/null 2>&1 && echo "✓ HDFS initialized" || echo "⚠ HDFS not ready yet"
EOF

# 3. Create warehouse directories
echo "[3/4] Creating warehouse directories..."
ssh master.cdp << 'EOF'
  sudo -u hdfs hdfs dfs -mkdir -p /warehouse/tablespace/external/hive
  sudo -u hdfs hdfs dfs -chmod -R 777 /warehouse/tablespace/external/hive
  sudo -u hdfs hdfs dfs -mkdir -p /user/hive
  sudo -u hdfs hdfs dfs -chown hive:hive /user/hive
  echo "✓ Warehouse directories created"
EOF

# 4. Verify Services
echo "[4/4] Verifying Services..."
SERVICES=$(curl -s -u ${AMBARI_USER}:${AMBARI_PASSWORD} \
  http://${AMBARI_HOST}:${AMBARI_PORT}/api/v1/clusters/${CLUSTER_NAME}/services | \
  jq '.items[].ServiceInfo.service_name' | tr -d '"')

echo "Installed Services:"
echo "$SERVICES" | while read service; do
  echo "  - $service"
done

echo ""
echo "======================================"
echo "Post-install configuration completed!"
echo "======================================"
```

---

## Próximos Passos

### Execução Manual (Passo a Passo)

```bash
# 1. Conectar no Master
ssh -i sua_chave.key opc@<MASTER_PUBLIC_IP>

# 2. Validar pré-requisitos
bash validate-cluster-prerequisites.sh

# 3. Preparar arquivos
cp blueprint.json /tmp/
cp cluster-template.json /tmp/

# 4. Aplicar blueprint
bash apply-blueprint.sh /tmp/blueprint.json cdp-cluster /tmp/cluster-template.json

# 5. Monitorar progresso
bash wait-cluster-deployment.sh cdp-cluster 1

# 6. Configurações pós-instalação
bash post-install-configuration.sh cdp-cluster

# 7. Acessar Ambari
# Abra browser: http://<MASTER_IP>:8080
# Usuário: admin
# Senha: admin
```

### Integração com Terraform

Para automatizar tudo via Terraform, adicione ao seu `InstallMaster.sh`:

```bash
#!/bin/bash
# ... existing setup code ...

# Wait for Ambari Server to be ready
echo "Waiting for Ambari Server to stabilize..."
sleep 30

# Apply blueprint after 2 minutes
sleep 120

# Execute blueprint application
cat > /tmp/apply-blueprint.sh << 'SCRIPT'
#!/bin/bash
set -e

# ... (copiar os scripts acima aqui)

# Executar em sequência
bash validate-cluster-prerequisites.sh
bash apply-blueprint.sh /tmp/blueprint.json cdp-cluster /tmp/cluster-template.json
bash wait-cluster-deployment.sh cdp-cluster 1
bash post-install-configuration.sh cdp-cluster

echo "✅ Cluster installation complete!"
SCRIPT

chmod +x /tmp/apply-blueprint.sh
bash /tmp/apply-blueprint.sh
```

### Integração com Terraform Output

Adicione ao seu `output.tf`:

```hcl
output "ambari_url" {
  value       = "http://${oci_core_instance.Master.public_ip}:8080"
  description = "Ambari Dashboard URL"
}

output "master_ssh" {
  value       = "ssh -i sua_chave.key opc@${oci_core_instance.Master.public_ip}"
  description = "SSH command to access Master"
}

output "cluster_hosts" {
  value = {
    master = oci_core_instance.Master.private_ip
    node1  = oci_core_instance.Node1.private_ip
    node2  = oci_core_instance.Node2.private_ip
    node3  = oci_core_instance.Node3.private_ip
  }
  description = "Internal IP addresses of cluster nodes"
}

output "deployment_status" {
  value = "Cluster deployment initiated. Access dashboard to monitor progress."
}
```

---

## Troubleshooting

### Hosts não aparecem no Ambari

```bash
# No Worker
sudo ambari-agent status
sudo ambari-agent restart

# Verificar arquivo de config
sudo cat /etc/ambari-agent/conf/ambari-agent.ini | grep -i "hostname\|server"
# Deve mostrar: hostname=master.cdp

# Ver logs
sudo tail -50 /var/log/ambari-agent/ambari-agent.log
```

### Blueprint falha na aplicação

```bash
# Verificar erros nos logs
sudo tail -100 /var/log/ambari-server/ambari-server.log | grep -i "error\|failed"

# Validar JSON da blueprint
jq empty blueprint.json

# Validar template
jq empty cluster-template.json
```

### Serviço específico falha na instalação

```bash
# Via API, obter detalhes de tasks falhadas
curl -s -u admin:admin http://localhost:8080/api/v1/clusters/cdp-cluster/requests/1/tasks | \
  jq '.items[] | select(.Tasks.status=="FAILED")'

# Ver logs locais
ssh node1.cdp "sudo tail -50 /var/log/hadoop/hdfs/*"
```

### PostgreSQL connection denied

```bash
# Verificar pg_hba.conf
sudo cat /var/lib/pgsql/data/pg_hba.conf | head -20

# Permitir conexões locais (se necessário)
sudo sed -i 's/ident$/trust/' /var/lib/pgsql/data/pg_hba.conf
sudo systemctl restart postgresql
```

---

## Próximas Atividades Após Cluster Funcional

1. **Configurar Ranger para segurança** (LDAP/AD integration)
2. **Setup de backup automático** (HDFS snapshots)
3. **Monitoramento avançado** (Ambari Metrics, Grafana)
4. **Performance tuning** (YARN, HBase)
5. **High Availability** (HA para NameNode, ResourceManager)
6. **Disaster Recovery** (replicação, backup cross-site)

---

## Referências

- **Ambari API Docs**: https://ambari.apache.org/docs/latest/administering-ambari/
- **ODP Stacks**: https://www.opensourcedataplatform.com/
- **Hortonworks BP Guide**: https://docs.cloudera.com/HDPDocuments/Ambari-2.7.5.0/
- **Terraform OCI Provider**: https://registry.terraform.io/providers/oracle/oci

---

**Versão**: 1.0  
**Data**: Novembro 2025  
**Status**: Pronto para implementação