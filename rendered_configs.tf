####################################
# Rendered Configuration Templates
####################################

# Render cluster-template.json from template
resource "local_file" "cluster_template" {
  filename = "${path.module}/.rendered/cluster-template.json"
  content = templatefile("${path.module}/assets/cluster-template.json.tftpl", {
    cluster_password = local.cluster_password
  })
  file_permission = "0644"
}

# Render site.yml from template
resource "local_file" "site_yml" {
  filename = "${path.module}/.rendered/site.yml"
  content = templatefile("${path.module}/assets/site.yml.tftpl", {
    cluster_password = local.cluster_password
  })
  file_permission = "0644"
}

# Render manual_service_init.sh from template
resource "local_file" "manual_service_init" {
  filename = "${path.module}/.rendered/manual_service_init.sh"
  content = templatefile("${path.module}/assets/manual_service_init.sh.tftpl", {
    nifi_password = local.nifi_password
  })
  file_permission = "0755"
}

# Render blueprint.json from template
resource "local_file" "blueprint" {
  filename = "${path.module}/.rendered/blueprint.json"
  content = templatefile("${path.module}/assets/blueprint.json.tftpl", {
    cluster_password = local.cluster_password
    nifi_password    = local.nifi_password
  })
  file_permission = "0644"
}
