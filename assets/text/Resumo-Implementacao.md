# Sumário Executivo: Instalação Automatizada de Cluster Ambari

## 🎯 Objetivo
Transformar seu setup manual (que para na interface Ambari) em uma automação completa via Blueprint e APIs, sem necessidade de intervenção manual.

---

## 📊 Status Atual em 4 Pontos

| Aspecto | Status | % Completo |
|---------|--------|-----------|
| **Infraestrutura (Terraform)** | ✅ Completo | 100% |
| **Sistema Operacional** | ✅ Completo | 100% |
| **Ambari Server/Agents** | ✅ Completo | 100% |
| **Aplicação da Blueprint** | ❌ Faltando | 0% |

**Progresso Total: 75% → Faltam apenas os últimos 25%**

---

## 🚀 Os 5 Passos Finais (20-30 minutos)

### PASSO 1: Esperar Hosts Registrarem (5 min)
```bash
# No seu master
watch -n 2 'curl -s -u admin:admin http://localhost:8080/api/v1/hosts | jq ".items | length"'
# Esperado: mudar de 0 → 4 em 1-2 minutos
```

**Requisito:** Já está automatizado no seu InstallMaster.sh + InstallWorker.sh
- ✅ Ambari Server rodando
- ✅ Agents conectando
- Apenas aguardar...

---

### PASSO 2: Enviar Blueprint para Ambari (1 min)
```bash
# Comando simples:
curl -X POST -H "Content-Type: application/json" -u admin:admin \
  -d @blueprint.json \
  http://localhost:8080/api/v1/blueprints/default
```

**Requisito:** Adicionar a seu script de inicialização
- Blueprint JSON: ✅ Já tem
- Ambari API: ✅ Já rodando
- Comando acima: Copiar e executar

---

### PASSO 3: Criar Mapeamento de Hosts (1 min)
Criar arquivo `cluster-template.json` com:
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

**Nota IMPORTANTE:** Verificar seu blueprint.json para número correto de host_groups
- Quantos grupos diferentes existem?
- Qual máquina em cada grupo?

---

### PASSO 4: Criar Cluster (1 min)
```bash
curl -X POST -H "Content-Type: application/json" -u admin:admin \
  -d @cluster-template.json \
  http://localhost:8080/api/v1/clusters/cdp-cluster
```

**Resultado:** Cluster creation iniciado! ✨

---

### PASSO 5: Monitorar até Conclusão (10-20 min)
```bash
# Ver progresso em tempo real
watch -n 5 'curl -s -u admin:admin http://localhost:8080/api/v1/clusters/cdp-cluster/requests/1 | \
  jq "{status: .Requests.request_status, progress: .Requests.progress_percent}"'
```

**Esperado:**
- `progress_percent`: 0% → 100%
- `request_status`: PENDING → IN_PROGRESS → COMPLETED

---

## 📋 Checklist de Implementação

### ANTES (Manual - Como você está agora)
```
terraform apply
  ↓
Máquinas criadas
  ↓
Scripts inicializam SO + Ambari
  ↓
Interface web disponível
  ↓ ❌ PARAR AQUI - precisa clicar na UI
```

### DEPOIS (Automático - Alvo)
```
terraform apply
  ↓
Máquinas criadas
  ↓
Scripts inicializam SO + Ambari
  ↓
Script checa hosts conectados
  ↓
Script envia blueprint
  ↓
Script cria cluster com template
  ↓
Script monitora até completo
  ↓
✅ Cluster pronto para usar!
```

---

## 🔧 Requisitos: O Que Você Precisa Fazer

### 1. **Criar 2 Arquivos Novos**

#### Arquivo 1: `/scripts/cluster-template.json`
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

#### Arquivo 2: `/scripts/apply-blueprint.sh`
Ver no guia completo (Guia-Ambari-Blueprint.md, seção "Scripts Necessários")

---

### 2. **Adicionar ao InstallMaster.sh**

Na linha APÓS `sudo ambari-server start`, adicione:

```bash
# Wait for Ambari to be fully ready
sleep 60

# Upload blueprint (after agents register)
sleep 120

# Apply blueprint
BLUEPRINT_FILE="/path/to/blueprint.json"
TEMPLATE_FILE="/path/to/cluster-template.json"

curl -X POST -H "Content-Type: application/json" -u admin:admin \
  -d @${BLUEPRINT_FILE} \
  http://localhost:8080/api/v1/blueprints/default

# Wait for hosts to register
for i in {1..12}; do
  HOSTS=$(curl -s -u admin:admin http://localhost:8080/api/v1/hosts | jq '.items | length')
  [ "$HOSTS" == "4" ] && break
  sleep 5
done

# Create cluster
curl -X POST -H "Content-Type: application/json" -u admin:admin \
  -d @${TEMPLATE_FILE} \
  http://localhost:8080/api/v1/clusters/cdp-cluster
```

---

### 3. **Verificar seu blueprint.json**

⚠️ **IMPORTANTE:** Seu blueprint.json é grande (441KB) e tem múltiplas configurações

Execute para entender sua estrutura:
```bash
# Ver quantos host_groups
jq '.host_groups | length' blueprint.json

# Ver nomes dos grupos
jq '.host_groups[].name' blueprint.json

# Ver componentes em cada grupo
jq '.host_groups[] | {name: .name, num_components: (.components | length)}' blueprint.json
```

**RESULTADO ESPERADO:**
```
Provavelmente terá 2-4 grupos diferentes
- host_group_1: Master + workers (HDFS, YARN, etc)
- host_group_2: Workers apenas (data nodes)
- host_group_3 (opcional): Específicos (Zookeeper)
```

---

## 🛠️ Passos de Implementação Detalhados

### Fase 1: Análise (5 min)

```bash
# 1. Analisar blueprint
jq '.host_groups[] | {name, components: [.components[].component_name]}' blueprint.json

# 2. Contar componentes por host
jq '.host_groups[].components | length' blueprint.json

# 3. Verificar configurações
jq '.configurations | length' blueprint.json  # Deve ter muitas
```

**Saída esperada:**
- host_group_1 com ~20-40 componentes
- host_group_2 com ~10-15 componentes
- Muitas configurações (200+)

---

### Fase 2: Preparação (10 min)

```bash
# 1. Copiar blueprint para diretório de scripts
cp blueprint.json ./scripts/
cp ODP-VDF.xml ./scripts/

# 2. Criar cluster-template.json (ver arquivo acima)
cat > ./scripts/cluster-template.json << 'EOF'
{
  "blueprint": "default",
  "default_password": "AmbariPassword123!",
  "host_groups": [
    {"name": "host_group_1", "hosts": [...]},
    {"name": "host_group_2", "hosts": [...]}
  ]
}
EOF

# 3. Criar scripts (copiar do guia)
cat > ./scripts/apply-blueprint.sh << 'EOF'
# ... (script completo)
EOF

chmod +x ./scripts/*.sh
```

---

### Fase 3: Integração Terraform (5 min)

Modificar `compute.tf`:

```hcl
# Na seção do Master, adicionar após ambari-server start:

resource "oci_core_instance" "Master" {
  # ... existing config ...
  
  metadata = {
    ssh_authorized_keys = var.generate_public_ssh_key ? ... : var.public_ssh_key
    user_data = var.installAmbari ? base64encode(templatefile("scripts/InstallMaster.sh", {
      public_ssh_key = tls_private_key.compute_ssh_key.public_key_openssh
      # ADICIONAR:
      apply_blueprint = "true"  # Flag para aplicar blueprint
    })) : ""
  }
}
```

Modificar `InstallMaster.sh`:

```bash
#!/bin/bash

# ... existing code até ambari-server start ...

sudo ambari-server start
sudo ambari-agent start

# NOVO CÓDIGO:
if [ "${apply_blueprint}" = "true" ]; then
  echo "Waiting for Ambari to stabilize..."
  sleep 120
  
  # Upload blueprint
  curl -s -X POST -H "Content-Type: application/json" -u admin:admin \
    -d @/path/to/blueprint.json \
    http://localhost:8080/api/v1/blueprints/default
  
  # Wait for hosts
  for i in {1..12}; do
    HOSTS=$(curl -s -u admin:admin http://localhost:8080/api/v1/hosts | jq '.items | length' 2>/dev/null)
    [ "$HOSTS" = "4" ] && break
    sleep 5
  done
  
  # Create cluster
  curl -s -X POST -H "Content-Type: application/json" -u admin:admin \
    -d @/path/to/cluster-template.json \
    http://localhost:8080/api/v1/clusters/cdp-cluster
  
  echo "Cluster deployment started!"
fi
```

---

## 📈 Resultado Final

```
terraform apply
    ↓ (2 min: criar VMs)
    ↓
terraform output ambari_url
    ↓ 
Ambari Dashboard: http://<IP>:8080
    ↓ (2 min: OS + Ambari)
    ↓
terraform apply completa
    ↓
Esperar 2 minutos (hosts registrarem)
    ↓
✅ Cluster INSTALADO E RODANDO
    ↓
Todos os serviços: STARTED/INSTALLED ✅
```

**Tempo Total: 35-45 minutos (completamente automático!)**

---

## 🎯 Próximas Ações

### Hoje (Imediato)
- [ ] Criar arquivo `cluster-template.json`
- [ ] Analisar estrutura do `blueprint.json` (host_groups)
- [ ] Copiar scripts do guia completo
- [ ] Modificar `InstallMaster.sh`

### Esta Semana
- [ ] Testar em desenvolvimento
- [ ] Validar blueprint application
- [ ] Verificar status dos serviços
- [ ] Documentar customizações

### Mês Próximo
- [ ] Implementar Terraform Remote State (backend)
- [ ] Setup de CI/CD (GitHub Actions)
- [ ] Monitoramento contínuo
- [ ] Plano de backup/recovery

---

## 📞 Perguntas Críticas a Responder

**Antes de começar, você precisa saber:**

1. **Quantos host_groups seu blueprint tem?**
   ```bash
   jq '.host_groups | length' blueprint.json
   ```

2. **Qual a senha padrão para Ambari?**
   - Atual nos scripts: `admin`/`admin`
   - Manter ou mudar?

3. **Todos os 4 nós devem ter todos os serviços?**
   - Ou cada um tem role específico?
   - (Ver definição dos host_groups)

4. **Onde armazenar os scripts?**
   - No repositório Terraform?
   - Em S3 (OCI Object Storage)?
   - Embutidos no user_data?

5. **Precisa de pós-configuração especial?**
   - Ranger setup?
   - Hive metastore?
   - Atlas integration?

---

## 📚 Documentos de Referência

| Arquivo | Tamanho | Uso |
|---------|---------|-----|
| `Guia-Ambari-Blueprint.md` | Completo | Procedimento detalhado |
| `blueprint.json` | 441KB | ✅ Já tem |
| `ODP-VDF.xml` | 2.6KB | ✅ Já tem |
| `cluster-template.json` | 📝 Para criar | Host mapping |
| `apply-blueprint.sh` | 📝 Para criar | API calls |

---

**Status Geral:** 🟢 Pronto para implementação
**Esforço Estimado:** 2-4 horas
**Risco:** Baixo (mudanças apenas no InitMaster.sh + 2 novos arquivos)

Qualquer dúvida sobre implementação, revise o Guia-Ambari-Blueprint.md!