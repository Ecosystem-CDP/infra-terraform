resource "oci_core_security_list" "Security-List-vcn-data-lake" {
  compartment_id = var.compartment_ocid
  display_name = "Security List for vcn-data-lake"
  vcn_id = oci_core_vcn.vcn-data-lake.id
  
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }

  ingress_security_rules {
    source      = "10.0.0.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "true"
    protocol  = "all"
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }

# HDFS
  ingress_security_rules {
    protocol    = "6"  
    source      = "${var.PublicIP}/32"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      min = "50070"
      max = "50070"
    }
  }

# YARN
ingress_security_rules {
    protocol    = "6"  
    source      = "${var.PublicIP}/32"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      min = "8088"
      max = "8088"
    }
  }

# MapReduce
ingress_security_rules {
    protocol    = "6"  
    source      = "${var.PublicIP}/32"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      min = "19888"
      max = "19888"
    }
  }

# Ambari
ingress_security_rules {
    protocol    = "6"  
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      min = "8080"
      max = "8080"
    }
  }

# Spark
ingress_security_rules {
    
    protocol    = "6"  
    source      = "${var.PublicIP}/32"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      min = "18082"
      max = "18082"
    }
  }
 
# HTTP Nifi
ingress_security_rules {
    protocol    = "6"  
    source      = "${var.PublicIP}/32"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      min = "9090"
      max = "9090"
    }
  }
  
# HTTPS Nifi
ingress_security_rules {
    protocol    = "6"  
    source      = "${var.PublicIP}/32"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      min = "9091"
      max = "9091"
    }
  }

# VPN connection (port 500, 4500 UDP)
ingress_security_rules {
    protocol    = "17"
    source      = "${var.PublicIP_vpn}/32"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    udp_options {
      min = "500"
      max = "500"
    }
  }
ingress_security_rules {
    protocol    = "17"  
    source      = "${var.PublicIP_vpn}/32"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    udp_options {
      min = "4500"
      max = "4500"
    }
  }
}