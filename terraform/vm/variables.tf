variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where VM lives"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "gallery_name" {
  type        = string
  description = "Shared Image Gallery name"
}

variable "image_name" {
  type        = string
  description = "SIG image definition name (e.g. ubuntu-nginx)"
}

variable "image_version" {
  type        = string
  description = "Exact SIG image version to deploy — injected by the pipeline (e.g. 1.20250525.42)"
}

variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "vm_size" {
  type        = string
  description = "Azure VM size"
  default     = "Standard_D2s_v5"
}

variable "admin_username" {
  type        = string
  description = "Admin SSH username"
  default     = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key string — injected from GitHub Secret"
}
