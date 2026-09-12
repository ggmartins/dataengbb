terraform {
  required_version = ">= 1.6.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.32.0"
    }
  }
}

# Authentication is read from ~/.oci/config.
provider "oci" {
  config_file_profile = var.oci_config_profile
}

variable "oci_config_profile" {
  description = "Profile name in ~/.oci/config."
  type        = string
  default     = "DEFAULT"
}

variable "compartment_ocid" {
  description = "OCID of the target compartment. The tenancy OCID can be used for the root compartment."
  type        = string
}

variable "ssh_public_key_path" {
  description = "Absolute path to the SSH public key, such as /Users/name/.ssh/oci_free.pub."
  type        = string
}

variable "admin_cidr" {
  description = "Public IPv4 address allowed to use SSH, including /32, such as 203.0.113.10/32."
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && endswith(var.admin_cidr, "/32")
    error_message = "admin_cidr must be a valid single-host IPv4 CIDR ending in /32."
  }
}

variable "availability_domain_index" {
  description = "Zero-based availability-domain index. Change this if OCI reports insufficient capacity."
  type        = number
  default     = 0

  validation {
    condition     = var.availability_domain_index >= 0 && floor(var.availability_domain_index) == var.availability_domain_index
    error_message = "availability_domain_index must be a non-negative integer."
  }
}

variable "shape" {
  description = "Documented OCI Always Free compute shape. A1 is ARM64; E2 Micro is x86-64."
  type        = string
  default     = "VM.Standard.A1.Flex"

  validation {
    condition = contains([
      "VM.Standard.A1.Flex",
      "VM.Standard.E2.1.Micro"
    ], var.shape)
    error_message = "shape must be VM.Standard.A1.Flex or VM.Standard.E2.1.Micro."
  }
}

variable "a1_ocpus" {
  description = "OCPUs assigned to A1. The documented Always Free tenancy-wide ceiling is 2."
  type        = number
  default     = 2

  validation {
    condition     = var.a1_ocpus >= 1 && var.a1_ocpus <= 2
    error_message = "a1_ocpus must be between 1 and 2."
  }
}

variable "a1_memory_gb" {
  description = "Memory assigned to A1. The documented Always Free tenancy-wide ceiling is 12 GB."
  type        = number
  default     = 12

  validation {
    condition     = var.a1_memory_gb >= 1 && var.a1_memory_gb <= 12
    error_message = "a1_memory_gb must be between 1 and 12."
  }
}

data "oci_identity_availability_domains" "available" {
  compartment_id = var.compartment_ocid
}

locals {
  availability_domain = data.oci_identity_availability_domains.available.availability_domains[var.availability_domain_index].name
}

# Find a current Ubuntu platform image compatible with the selected CPU architecture.
data "oci_core_images" "ubuntu" {
  compartment_id   = var.compartment_ocid
  operating_system = "Canonical Ubuntu"
  shape            = var.shape
  sort_by          = "TIMECREATED"
  sort_order       = "DESC"
}

# Confirm that the selected shape is offered in the selected availability domain.
data "oci_core_shapes" "selected" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  shape               = var.shape
}

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  display_name   = "always-free-vcn"
  dns_label      = "freevcn"
  cidr_blocks    = ["10.0.0.0/16"]
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "always-free-internet-gateway"
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "always-free-public-routes"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  display_name               = "always-free-public-subnet"
  dns_label                  = "public"
  cidr_block                 = "10.0.1.0/24"
  route_table_id             = oci_core_route_table.public.id
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_network_security_group" "instance" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "always-free-instance-nsg"
}

resource "oci_core_network_security_group_security_rule" "ssh" {
  network_security_group_id = oci_core_network_security_group.instance.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.admin_cidr
  source_type               = "CIDR_BLOCK"
  description               = "SSH from the administrator IP only"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress" {
  network_security_group_id = oci_core_network_security_group.instance.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Allow outbound IPv4 traffic"
}

resource "oci_core_instance" "always_free" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  display_name        = "terraform-always-free"
  shape               = var.shape

  dynamic "shape_config" {
    for_each = var.shape == "VM.Standard.A1.Flex" ? [1] : []

    content {
      ocpus         = var.a1_ocpus
      memory_in_gbs = var.a1_memory_gb
    }
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    hostname_label   = "freevm"
    nsg_ids          = [oci_core_network_security_group.instance.id]
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = 50
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }

  lifecycle {
    precondition {
      condition     = length(data.oci_core_shapes.selected.shapes) > 0
      error_message = "The selected shape is not offered in this availability domain. Try a different availability_domain_index."
    }

    precondition {
      condition     = length(data.oci_core_images.ubuntu.images) > 0
      error_message = "No compatible Canonical Ubuntu image was found for the selected shape."
    }
  }
}

output "availability_domain" {
  description = "Availability domain used for the instance."
  value       = local.availability_domain
}

output "shape" {
  description = "Compute shape used for the instance."
  value       = oci_core_instance.always_free.shape
}

output "subnet_ocid" {
  description = "OCID of the public subnet created by Terraform."
  value       = oci_core_subnet.public.id
}

output "public_ip" {
  description = "Public IPv4 address of the compute instance."
  value       = oci_core_instance.always_free.public_ip
}

output "ssh_command" {
  description = "Example SSH command. Ubuntu platform images use the ubuntu account."
  value       = "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} ubuntu@${oci_core_instance.always_free.public_ip}"
}
