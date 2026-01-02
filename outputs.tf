####################################
# Password Notification
####################################

# Cria um arquivo JSON local com informações sobre a senha
resource "local_file" "password_info" {
  filename = "${path.module}/password-info.json"
  
  content = jsonencode({
    timestamp          = timestamp()
    cluster_name       = "CDP Cluster"
    vault_secret_id    = oci_vault_secret.cluster_password.id
    vault_secret_name  = oci_vault_secret.cluster_password.secret_name
    notification_email = var.notification_email
    
    password_usage = {
      ambari = {
        description     = "Ambari Web UI - Login padrão"
        url             = "http://<master-ip>:8080"
        username        = "admin"
        password        = local.cluster_password
      }
      
      ranger = {
        description = "Ranger Admin Web UI"
        url         = "http://<master-ip>:6080"
        username    = "admin"
        password    = local.cluster_password
        users = [
          "admin",
          "rangerusersync",
          "rangertagsync",
          "keyadmin"
        ]
      }
      
      postgresql = {
        description = "PostgreSQL Database - Usuários do sistema"
        host        = "master.cdp"
        port        = 5432
        password    = local.cluster_password
        users = [
          "ambari",
          "hive",
          "rangeradmin",
          "postgres"
        ]
      }
      
      nifi = {
        description        = "Apache NiFi - Chave de propriedades sensíveis"
        url                = "http://<node1-ip>:8080/nifi"
        sensitive_props_key = local.nifi_password
      }
    }
    
    instructions = {
      retrieve_from_vault = "Use OCI Console: Identity & Security > Vault > Secrets > ${oci_vault_secret.cluster_password.secret_name}"
      security_warning    = "IMPORTANTE: Esta senha é compartilhada entre todos os componentes. Proteja este arquivo adequadamente."
      on_new_apply        = "A cada terraform apply, uma nova senha será gerada. Atualize suas credenciais salvas."
    }
  })

  # Permissões restritas apenas para o proprietário
  file_permission = "0600"
}

# Output com instruções para o usuário
output "password_info_location" {
  description = "Localização do arquivo com informações sobre senhas"
  value       = local_file.password_info.filename
}

output "vault_secret_id" {
  description = "OCID do secret no OCI Vault contendo a senha do cluster"
  value       = oci_vault_secret.cluster_password.id
}

output "password_retrieval_instructions" {
  description = "Instruções para recuperar a senha"
  value = <<-EOT
    
    ╔════════════════════════════════════════════════════════════════╗
    ║          SENHA DO CLUSTER CDP GERADA COM SUCESSO              ║
    ╚════════════════════════════════════════════════════════════════╝
    
    📁 Arquivo com informações: ${local_file.password_info.filename}
    
    🔐 OCI Vault Secret:
       Nome: ${oci_vault_secret.cluster_password.secret_name}
       OCID: ${oci_vault_secret.cluster_password.id}
    
    📧 Notificação enviada para: ${var.notification_email != "" ? var.notification_email : "Nenhum e-mail configurado"}
    
    ⚙️ Componentes usando esta senha:
       - Ambari Admin (admin)
       - Ranger Admin (admin)
       - PostgreSQL (ambari, hive, rangeradmin, postgres)
       - NiFi (sensitive properties key)
    
    💡 Para recuperar a senha:
       1. Abra o arquivo: ${local_file.password_info.filename}
       2. OU acesse OCI Console > Identity & Security > Vault > Secrets
       3. Localize o secret: ${oci_vault_secret.cluster_password.secret_name}
    
    ⚠️  IMPORTANTE: Proteja este arquivo adequadamente!
    
  EOT
}
