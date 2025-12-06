# Guia do Desenvolvedor

Este documento contém informações técnicas para manutenção, debug e monitoramento do processo de deploy automatizado.

## 🔍 Monitoramento e Logs

Durante o processo de deploy, diferentes camadas de software são executadas sequencialmente. Abaixo estão os comandos para acompanhar os logs em tempo real em cada etapa.

**Nota:** Todos os comandos devem ser executados no nó **Master** (`master.cdp`), acessado via SSH com o usuário `opc` e elevando para `root` (`sudo -i`).

### 1. Inicialização da VM (Cloud-Init)
Logo após a criar a máquina, o Cloud-Init executa os scripts de bootstrap (instalação de pacotes, configuração de rede).
*   **O que ver:** Progresso da instalação do Ansible e setup inicial.
*   **Comando:**
    ```bash
    tail -f /var/log/cloud-init-output.log
    ```

### 2. Execução do Ansible (Provisionamento)
O Cloud-Init dispara o script `/root/run-ansible.sh`. Este script, por sua vez, executa os playbooks e redireciona a saída para um arquivo de log dedicado.
*   **O que ver:** Execução das tasks do Ansible (preparação do SO, instalação do Java, Ambari, etc).
*   **Comando:**
    ```bash
    tail -f /var/log/ansible/ansible.log
    ```

### 3. Ambari Server (Gerenciamento do Cluster)
Uma vez que o Ansible instala e inicia o Ambari Server, ele começa a orquestrar os serviços nos agentes.
*   **O que ver:** Erros de inicialização do servidor, problemas de conexão com agentes, status do deploy do blueprint.
*   **Comando:**
    ```bash
    tail -f /var/log/ambari-server/ambari-server.log
    ```

### 4. Ambari Agents (Nos nós executores)
Se houver falha na instalação de um serviço específico em um nó (ex: DataNode falhando no Node1), verifique o log do agente **na máquina respectiva** (Master ou Workers).
*   **O que ver:** Execução de comandos recebidos do servidor (install, start, stop).
*   **Comando:**
    ```bash
    tail -f /var/log/ambari-agent/ambari-agent.log
    ```

---

## 🛠 Resumo do Fluxo de Debug

1.  **Deploy travado no início?**
    Verifique `cloud-init-output.log`. Pode ser erro de sintaxe no YAML ou falha no `yum install`.

2.  **Ansible falhou?**
    Verifique `/var/log/ansible/ansible.log`. Procure por tarefas marcadas como `FAILED`. O erro geralmente indica se foi falha de SSH, pacote não encontrado ou timeout.

3.  **Deploy do Cluster (Blueprint) falhou?**
    Se o Ansible completou a etapa de `site.yml` mas falhou no `cluster_deploy.yml`, ou se o Ansible finalizou mas o cluster não subiu:
    *   Verifique o `ambari-server.log`.
    *   Acesse a UI do Ambari (Porta 8080) se possível para ver o status visual.

---

## 📁 Verificação dos Assets

Para garantir que o Terraform realizou o upload e movimentação correta dos arquivos de configuração, acesse o nó **Master** e liste os arquivos no diretório `/root`.

**Comando:**
```bash
sudo ls -l /root/
```

**Saída Esperada:**
Você deve ver os seguintes arquivos listados (além de scripts padrões como `run-ansible.sh`):
*   `blueprint.json`
*   `cluster-template.json`
*   `cluster_deploy.yml`
*   `ODP-VDF.xml`
*   `site.yml`

Se algum deles estiver faltando, o script `run-ansible.sh` ficará aguardando indefinidamente (loop de verificação). Nesse caso, verifique o log do Terraform para erros na etapa `provisioner "file"` ou `provisioner "remote-exec"`.
