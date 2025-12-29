# ============================================================================
# Password Generation for CDP Cluster
# ============================================================================
# Requirements (Apache Ranger):
# - Minimum 8 characters
# - At least 1 alphabetic character
# - At least 1 numeric character
# - Forbidden: " ' \ `
# ============================================================================

resource "random_password" "ambari_db" {
  length      = 16
  special     = false # Apenas letras + números (evita chars proibidos)
  upper       = true
  lower       = true
  numeric     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 2 # Garantir pelo menos 2 números
}

resource "random_password" "hive_db" {
  length      = 16
  special     = false
  upper       = true
  lower       = true
  numeric     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 2
}

resource "random_password" "ranger_db" {
  length      = 16
  special     = false
  upper       = true
  lower       = true
  numeric     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 2
}

resource "random_password" "postgres_superuser" {
  length      = 16
  special     = false
  upper       = true
  lower       = true
  numeric     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 2
}

resource "random_password" "hive_legacy" {
  length      = 16
  special     = false
  upper       = true
  lower       = true
  numeric     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 2
}

resource "random_password" "nifi_sensitive_key" {
  length      = 16
  special     = false
  upper       = true
  lower       = true
  numeric     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 2
}

resource "random_password" "console_user" {
  length      = 16
  special     = false
  upper       = true
  lower       = true
  numeric     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 2
}

# ============================================================================
# Outputs para o usuário final
# ============================================================================

output "PASSWORDS_GENERATED" {
  description = "⚠️ IMPORTANTE: Senhas geradas para o cluster CDP - Salve em local seguro!"
  sensitive   = true
  value       = <<-EOT
  
  ╔══════════════════════════════════════════════════════════════════════╗
  ║          SENHAS DO CLUSTER CDP - SALVE EM LOCAL SEGURO!            ║
  ╚══════════════════════════════════════════════════════════════════════╝
  
  🔐 PostgreSQL Database Passwords:
     • Ambari DB User:        ${random_password.ambari_db.result}
     • Hive DB User:          ${random_password.hive_db.result}
     • Ranger DB User:        ${random_password.ranger_db.result}
     • PostgreSQL Superuser:  ${random_password.postgres_superuser.result}
     • Hive Legacy User:      ${random_password.hive_legacy.result}
  
  🔐 Application Passwords:
     • NiFi Sensitive Key:    ${random_password.nifi_sensitive_key.result}
     • Console User:          ${random_password.console_user.result}
  
  🔐 Ambari Admin (Padrão - NÃO ALTERADO):
     • Username: admin
     • Password: admin
  
  📋 INSTRUÇÕES:
     1. Copie estas senhas para um gerenciador de senhas seguro
     2. Estas senhas foram aplicadas automaticamente ao cluster
     3. Use a senha do Ambari Admin (admin/admin) para acessar:
        http://<MASTER_IP>:8080
  
  ⚠️  IMPORTANTE: Mantenha estas senhas em segurança!
  
  EOT
}

output "cluster_passwords_json" {
  description = "Senhas em formato JSON (para scripts/automação)"
  sensitive   = true
  value = {
    # Senhas randomizadas (conforme Ranger requirements)
    ambari_db_password          = random_password.ambari_db.result
    hive_db_password            = random_password.hive_db.result
    ranger_db_password          = random_password.ranger_db.result
    postgres_superuser_password = random_password.postgres_superuser.result
    hive_legacy_password        = random_password.hive_legacy.result
    nifi_sensitive_key          = random_password.nifi_sensitive_key.result
    console_password            = random_password.console_user.result

    # Senha padrão mantida (não modificar)
    ambari_api_password = "admin"
  }
}
