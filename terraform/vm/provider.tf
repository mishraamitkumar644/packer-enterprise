terraform {

  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # No backend — state discarded via -state=/dev/null in the pipeline.
  # VM job only runs when the VM does not already exist (checked via
  # Azure CLI before Terraform is invoked), so there is no risk of
  # Terraform trying to recreate existing resources.
}

provider "azurerm" {
  features     {}
  use_oidc        = true
  subscription_id = var.subscription_id
}
