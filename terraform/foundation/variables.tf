variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for RG + SIG + image definitions"
}

variable "gallery_name" {
  type        = string
  description = "Shared Image Gallery name"
}

variable "location" {
  type        = string
  description = "Azure region"
}
