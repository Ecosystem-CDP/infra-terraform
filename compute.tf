# Master
resource "oci_core_instance" "Master" {
  
  display_name = "master.cdp"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id = var.compartment_ocid 
  
  create_vnic_details {
    assign_public_ip = "true"
    display_name = "primaryvnic"
    private_ip = "10.0.0.2"
    subnet_id = oci_core_subnet.data-lake-subnet.id
  }
  
  launch_options {
  boot_volume_type                    = "PARAVIRTUALIZED"
  firmware                            = "UEFI_64"
  is_consistent_volume_naming_enabled = true
  network_type                        = "PARAVIRTUALIZED"
  remote_data_volume_type             = "PARAVIRTUALIZED"
}

  
  shape = var.instance_shape

  metadata = {
    ssh_authorized_keys = var.generate_public_ssh_key ? tls_private_key.compute_ssh_key.public_key_openssh : "${var.public_ssh_key}\n${tls_private_key.compute_ssh_key.public_key_openssh}"
    user_data = var.installAmbari ? base64encode(templatefile("cloud-init/master.yaml",  {
      private_key_pem_b64 = base64encode(tls_private_key.compute_ssh_key.private_key_pem),
      hg1 = "master.cdp",
      hg2 = "node1.cdp",
      hg3 = "node2.cdp",
      hg4 = "node3.cdp"
    })) : ""
  }
  
  shape_config {
    memory_in_gbs             = var.memory_in_gbs_master
    ocpus                     = var.ocpus_master
  }
  
  source_details {
    source_id = lookup(data.oci_core_images.compute_images.images[0], "id")
    source_type = "image"
    boot_volume_size_in_gbs = 50
  }
}

# Worker 1
resource "oci_core_instance" "Node1" {
  
  display_name = "node1.cdp"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id = var.compartment_ocid 
  
  create_vnic_details {
    assign_public_ip = "true"
    display_name = "primaryvnic"
    private_ip = "10.0.0.3"
    subnet_id = oci_core_subnet.data-lake-subnet.id
  }
  
  launch_options {
  boot_volume_type                    = "PARAVIRTUALIZED"
  firmware                            = "UEFI_64"
  is_consistent_volume_naming_enabled = true
  network_type                        = "PARAVIRTUALIZED"
  remote_data_volume_type             = "PARAVIRTUALIZED"
}

  
  shape = var.instance_shape

  metadata = {
    ssh_authorized_keys = var.generate_public_ssh_key ? tls_private_key.compute_ssh_key.public_key_openssh : "${var.public_ssh_key}\n${tls_private_key.compute_ssh_key.public_key_openssh}"
    user_data = var.installAmbari ? base64encode(templatefile("cloud-init/worker.yaml",  {
      hg1 = "master.cdp",
      hg2 = "node1.cdp",
      hg3 = "node2.cdp",
      hg4 = "node3.cdp"
    })) : ""
  }
  
  shape_config {
    memory_in_gbs             = var.memory_in_gbs_worker
    ocpus                     = var.ocpus_worker
  }
  
  source_details {
    source_id = lookup(data.oci_core_images.compute_images.images[0], "id")
    source_type = "image"
    boot_volume_size_in_gbs = 50
  }
}

# Worker 2
resource "oci_core_instance" "Node2" {
  
  display_name = "node2.cdp"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id = var.compartment_ocid 
  
  create_vnic_details {
    assign_public_ip = "true"
    display_name = "primaryvnic"
    private_ip = "10.0.0.4"
    subnet_id = oci_core_subnet.data-lake-subnet.id
  }
  
  launch_options {
  boot_volume_type                    = "PARAVIRTUALIZED"
  firmware                            = "UEFI_64"
  is_consistent_volume_naming_enabled = true
  network_type                        = "PARAVIRTUALIZED"
  remote_data_volume_type             = "PARAVIRTUALIZED"
}

  
  shape = var.instance_shape

  metadata = {
    ssh_authorized_keys = var.generate_public_ssh_key ? tls_private_key.compute_ssh_key.public_key_openssh : "${var.public_ssh_key}\n${tls_private_key.compute_ssh_key.public_key_openssh}"
    user_data = var.installAmbari ? base64encode(templatefile("cloud-init/worker.yaml",  {
      hg1 = "master.cdp",
      hg2 = "node1.cdp",
      hg3 = "node2.cdp",
      hg4 = "node3.cdp"
    })) : ""
  }
  
  shape_config {
    memory_in_gbs             = var.memory_in_gbs_worker
    ocpus                     = var.ocpus_worker
  }
  
  source_details {
    source_id = lookup(data.oci_core_images.compute_images.images[0], "id")
    source_type = "image"
    boot_volume_size_in_gbs = 50
  }
}

# Worker 3
resource "oci_core_instance" "Node3" {
  
  display_name = "node3.cdp"
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id = var.compartment_ocid 
  
  create_vnic_details {
    assign_public_ip = "true"
    display_name = "primaryvnic"
    private_ip = "10.0.0.5"
    subnet_id = oci_core_subnet.data-lake-subnet.id
  }
  
  launch_options {
  boot_volume_type                    = "PARAVIRTUALIZED"
  firmware                            = "UEFI_64"
  is_consistent_volume_naming_enabled = true
  network_type                        = "PARAVIRTUALIZED"
  remote_data_volume_type             = "PARAVIRTUALIZED"
}

  
  shape = var.instance_shape

  metadata = {
    ssh_authorized_keys = var.generate_public_ssh_key ? tls_private_key.compute_ssh_key.public_key_openssh : "${var.public_ssh_key}\n${tls_private_key.compute_ssh_key.public_key_openssh}"
    user_data = var.installAmbari ? base64encode(templatefile("cloud-init/worker.yaml",  {
      hg1 = "master.cdp",
      hg2 = "node1.cdp",
      hg3 = "node2.cdp",
      hg4 = "node3.cdp"
    })) : ""
  }
  
  shape_config {
    memory_in_gbs             = var.memory_in_gbs_worker
    ocpus                     = var.ocpus_worker
  }
  
  source_details {
    source_id = lookup(data.oci_core_images.compute_images.images[0], "id")
    source_type = "image"
    boot_volume_size_in_gbs = 50
  }
}

# Generate ssh keys in Worker to Master have access to Worker Workers
resource "tls_private_key" "compute_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
