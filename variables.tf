variable "tenancy_ocid" {}
variable "region" {}
variable "compartment_ocid" {}
variable "private_key_path" {
  default = ""
}

variable "user_ocid" {
  default = ""
}

variable "fingerprint" {
  default = ""
}

variable "public_ssh_key" {
  default = ""
}

variable "memory_in_gbs_master" {
  default = 6
}

variable "ocpus_master" {
  default = 1
}

variable "generate_public_ssh_key" {
  default = false
}

variable "instance_shape" {
  default = "VM.Standard.A1.Flex"
}

variable "image_operating_system" {
  default = "Oracle Linux"
}

variable "image_operating_system_version" {
  default = "9"
}

variable "instance_visibility_master" {
  default = "Public"
}

variable "is_pv_encryption_in_transit_enabled" {
  default = false
}

# Compute Worker

variable "memory_in_gbs_worker" {
  default = 6
}

variable "ocpus_worker" {
  default = 1
}

variable "instance_visibility_worker" {
  default = "Public"
}

variable "installAmbari" {
  default = true
}

variable "PublicIP" {
  default = "10.0.0.2"
}

variable "PublicIP_vpn" {
  default = "10.0.0.2"
}

variable "StaticRoute" {
  default = "192.168.0.0/24"
}

variable "PrivateIP" {
  default = "192.168.0.3"
}

variable "IKEversion" {
  default = "V2"
}

# IP público do cliente que acessa as UIs via navegador
# IMPORTANTE: Este é o IP do SEU notebook/computador, não da máquina OCI
# Obtenha seu IP em: https://api.ipify.org ou https://whatismyip.com
variable "my_client_ip" {
  description = "IP público da sua máquina (notebook/desktop) que acessará as interfaces web. Obtenha em https://api.ipify.org"
  type        = string
  # SEM default - força usuário a fornecer o IP ao criar a Stack
}

# Security - OCI Vault Integration
variable "vault_id" {
  description = "OCID do OCI Vault para armazenar senhas do cluster. Crie um vault em: Identity & Security > Vault"
  type        = string
}

variable "vault_key_id" {
  description = "OCID da chave de criptografia do Vault (deve ser SYMMETRIC). Obtenha em: Vault > Master Encryption Keys"
  type        = string
}

variable "notification_email" {
  description = "E-mail para receber notificação com as senhas geradas do cluster"
  type        = string
  default     = ""
}