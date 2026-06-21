variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "japaneast"
}

variable "name_prefix" {
  description = "Prefix used for resource names. Use lowercase letters, numbers, and hyphens."
  type        = string
  default     = "az-km"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.name_prefix))
    error_message = "name_prefix must be 3-24 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "admin_username" {
  description = "Admin username for the Linux VM."
  type        = string
  default     = "haru256"
}

variable "ssh_public_key_path" {
  description = "Path to an existing SSH public key file, such as ~/.ssh/id_ed25519.pub."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vm_size" {
  description = "Azure VM size for the learning VM."
  type        = string
  default     = "Standard_B1s"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "vm_subnet_address_prefixes" {
  description = "Address prefixes for the VM subnet."
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "bastion_subnet_address_prefixes" {
  description = "Address prefixes for AzureBastionSubnet. Azure Bastion requires /26 or larger."
  type        = list(string)
  default     = ["10.0.2.0/26"]
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default = {
    chapter = "ch02"
    purpose = "azure-bastion-learning"
  }
}
