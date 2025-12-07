output "generated_private_key_pem" {
  sensitive = true
  value = var.generate_public_ssh_key ? tls_private_key.compute_ssh_key.private_key_pem : "No Keys Auto Generated"
}

output "comments" {
  value = "The instalation of ambari will be finishied in about 10 minutes, and then there will be the instalation of the cluster. The URL for ambari is ${oci_core_instance.Master.public_ip}:8080. Try ssh to Master in case application does not load."
}
