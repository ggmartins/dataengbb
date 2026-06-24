variable "resource_group_name" {
  description = "Azure Resource Group name."
  type        = string
  default     = "rg-win11-us-lowcost"
}

variable "location" {
  description = "Azure region where the Windows 11 VM will run. US examples: eastus, eastus2, centralus, southcentralus, westus3."
  type        = string
  default     = "eastus"
}

variable "vm_size" {
  description = "Low-cost VM size. Standard_B2s is a practical minimum for Windows 11."
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Local Windows admin username."
  type        = string
  default     = "adminuser1"
}

variable "admin_password" {
  description = "Local Windows admin password. Must satisfy Azure Windows password complexity requirements."
  type        = string
  sensitive   = true
}

variable "allowed_rdp_ip" {
  description = "Your Brazilian public IP address in CIDR format. Example: 189.10.20.30/32"
  type        = string
}

variable "windows_11_sku" {
  description = "Windows 11 Marketplace image SKU. If unavailable, list SKUs with Azure CLI."
  type        = string
  default     = "win11-24h2-pro"
}

variable "vnet_address_space" {
  description = "Virtual network CIDR."
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_address_prefix" {
  description = "Subnet CIDR."
  type        = string
  default     = "10.20.1.0/24"
}

variable "os_disk_storage_account_type" {
  description = "OS disk type. Standard_LRS is cheaper than Premium_LRS."
  type        = string
  default     = "Standard_LRS"
}

variable "tags" {
  description = "Common Azure tags."
  type        = map(string)
  default = {
    environment = "dev"
    managed_by  = "terraform"
  }
}
