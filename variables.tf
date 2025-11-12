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