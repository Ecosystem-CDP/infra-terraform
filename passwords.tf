####################################
# Random Password Generation
####################################

resource "random_password" "cluster_password" {
  length  = 16
  special = false # Ranger não aceita caracteres especiais
  upper   = true
  lower   = true
  numeric = true

  # Manter a senha estável entre applies
  # Remover este bloco se quiser regenerar a senha a cada apply
  lifecycle {
    ignore_changes = [
      length,
      special,
      upper,
      lower,
      numeric
    ]
  }
}

# Para NiFi, usamos a mesma senha por simplicidade
# mas podemos criar uma diferente se necessário
locals {
  cluster_password = random_password.cluster_password.result
  nifi_password    = random_password.cluster_password.result
}
