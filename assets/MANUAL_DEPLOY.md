# Processo Manual de Deploy do Cluster (Debug)

Este guia fornece os comandos manuais equivalentes ao playbook `cluster_deploy.yml` do Ansible. Use-os no nó **Master** (como `root`) para executar o deploy passo-a-passo e visualizar as respostas da API do Ambari em detalhes.

## Pré-requisitos
Acesse o nó Master e torne-se root:
```bash
sudo -i
```

Assegure que o Ambari Server está rodando:
```bash
ambari-server status
# Se não estiver rodando:
ambari-server start
```

## 1. Verificar registro dos Hosts
O Ansible falhou nesta etapa. Vamos checar o que a API retorna.
Execute repetidamente até ver 4 itens na lista ("master.cdp", "node1.cdp", "node2.cdp", "node3.cdp").

```bash
curl -i -u admin:admin -H "X-Requested-By: ambari" http://localhost:8080/api/v1/hosts
```

**Diagnóstico de Falha:**
*   **Erro de conexão (Connection refused):** O Ambari Server ainda não subiu completamente. Aguarde e tente novamente.
*   **Erro 502/503:** O servidor está sobrecarregado ou iniciando. Verifique `/var/log/ambari-server/ambari-server.log`.
*   **Retorno vazio ou incompleto:** Os agentes não estão conseguindo conectar. Verifique `/var/log/ambari-agent/ambari-agent.log`.

## 2. Registrar Definição de Versão (VDF)
Registra a versão do HDP/ODP a ser instalada.

```bash
curl -i -u admin:admin -H "X-Requested-By: ambari" -X POST -d '{"VersionDefinition": {"version_url": "file:///root/ODP-VDF.xml"}}' http://localhost:8080/api/v1/version_definitions
```
*Sucesso esperado: HTTP 201 Created ou 409 Conflict (se já existir).*


## 3. Registrar Blueprint
Envia o modelo do cluster.

**Correção Necessária (Erro: MYSQL_SERVER available but hive using existing db):**
Execute estes comandos para ajustar o `blueprint.json` no servidor (trocar Postgres por MySQL gerenciado):
```bash
sed -i 's/"hive_database": "Existing PostgreSQL Database"/"hive_database": "New MySQL Database"/' /root/blueprint.json
sed -i 's/"hive_database_type": "postgres"/"hive_database_type": "mysql"/' /root/blueprint.json
sed -i '/"javax.jdo.option.ConnectionURL"/d' /root/blueprint.json
```

Agora registre o blueprint:
```bash
curl -i -u admin:admin -H "X-Requested-By: ambari" -X POST -d @/root/blueprint.json http://localhost:8080/api/v1/blueprints/odp-blueprint
```
*Sucesso esperado: HTTP 201 Created ou 409 Conflict.*

## 4. Criar o Cluster
Inicia o processo de instalação e configuração dos serviços.

```bash
curl -i -u admin:admin -H "X-Requested-By: ambari" -X POST -d @/root/cluster-template.json http://localhost:8080/api/v1/clusters/odp-cluster
```
*Sucesso esperado: HTTP 202 Accepted.*

## 5. Monitorar e Debugar (Troubleshooting)

### Consultar Status Geral
O comando anterior retornou um JSON. Verifique o campo `request_status` ("IN_PROGRESS", "COMPLETED" ou "FAILED") e `progress_percent`.

```bash
# Substitua o ID na URL (ex: requests/4)
curl -i -u admin:admin -H "X-Requested-By: ambari" http://localhost:8080/api/v1/clusters/odp-cluster/requests/4
```

### Como encontrar o erro se falhar?
Se o status for **FAILED** ou **ABORTED**, você precisa descobrir qual tarefa falhou.

1. **Liste as tarefas que falharam:**
```bash
curl -u admin:admin -H "X-Requested-By: ambari" "http://localhost:8080/api/v1/clusters/odp-cluster/requests/4/tasks?fields=Tasks/status,Tasks/command_detail&Tasks/status.in(FAILED,ABORTED,TIMEDOUT)"
```
Isso listará apenas as tarefas com erro, mostrando o `id` da tarefa (ex: `10023`).

2. **Veja o log da tarefa específica:**
Pegue o `id` da tarefa falhada (ex: `10023`) e consulte o log de erro (`stderr`) e de saída (`stdout`):

```bash
# Exemplo para a tarefa 10023
curl -u admin:admin -H "X-Requested-By: ambari" "http://localhost:8080/api/v1/clusters/odp-cluster/requests/4/tasks/10023?fields=Tasks/stderr,Tasks/stdout"
```
O campo `Tasks/stderr` mostrará a mensagem de erro detalhada (ex: erro de pacote, falha de conexão DB, etc).

### Logs no Sistema
Além da API, você pode ver os logs diretamente nos arquivos:
*   **Ambari Server:** `/var/log/ambari-server/ambari-server.log`
*   **Ambari Agent (nos nós):** `/var/log/ambari-agent/ambari-agent.log`

