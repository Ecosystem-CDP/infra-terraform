####################################
# OCI Vault Integration
####################################

# Armazena a senha gerada no OCI Vault
resource "oci_vault_secret" "cluster_password" {
  compartment_id = var.compartment_ocid
  secret_name    = "cdp-cluster-password-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  vault_id       = var.vault_id
  key_id         = var.vault_key_id

  secret_content {
    content_type = "BASE64"
    # OCI Vault requer conteúdo em Base64
    content = base64encode(local.cluster_password)
  }

  description = "Senha gerada automaticamente para o cluster CDP. Usada em: Ambari, Ranger, PostgreSQL, NiFi"

  metadata = {
    "generated_at"    = timestamp()
    "terraform_apply" = "true"
    "components"      = "ambari,ranger,postgresql,nifi"
  }

  # Evitar destruição acidental da senha
  lifecycle {
    prevent_destroy = false # Mudar para true em produção
  }
}
