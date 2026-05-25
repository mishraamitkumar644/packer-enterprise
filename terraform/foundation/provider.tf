terraform {

  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # No backend block — state is intentionally discarded after every run.
  # These resources (RG, SIG, image definitions) are idempotent in Azure:
  # if they already exist, azurerm silently does nothing.
  # Pipeline runs terraform apply -state=/dev/null so no state file is
  # written or read anywhere.
}

provider "azurerm" {
  features     {}
  use_oidc        = true
  subscription_id = var.subscription_id
}
