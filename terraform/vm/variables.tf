variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where the VM will be deployed"
}

variable "gallery_name" {
  type        = string
  description = "Shared Image Gallery name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "image_name" {
  type        = string
  description = "SIG image definition name to deploy (e.g. ubuntu-nginx)"
}

variable "image_version" {
  type        = string
  description = <<-EOT
    Exact SIG image version to deploy (e.g. 1.0.20250525143022).
    Passed in by the pipeline after Packer builds the image.
    Use 'latest' only for manual one-off applies outside the pipeline.
  EOT
  default     = "latest"
}
