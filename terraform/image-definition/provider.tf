terraform {

  required_version = ">= 1.5.0"

  required_providers {

    azurerm = {

      source  = "hashicorp/azurerm"

      version = "~> 4.0"
    }
  }

  # ------------------------------------------------------------------
  # Remote backend
  #
  # State is stored in the Azure Blob Storage account created by
  # terraform/backend/. Run that module once manually before using
  # this module.
  #
  # use_oidc = true         — authenticate via GitHub Actions OIDC
  #                           token instead of a client secret
  # use_azuread_auth = true — read/write the state blob using Azure AD
  #                           instead of storage account keys
  # State locking           — handled automatically via Azure Blob
  #                           Storage native lease mechanism; no extra
  #                           resource needed
  # ------------------------------------------------------------------

  backend "azurerm" {

    resource_group_name  = "rg-tfstate"

    storage_account_name = "tfstatecanadaprod"

    container_name       = "tfstate-image-definition"

    key                  = "image-definition.terraform.tfstate"

    use_oidc             = true

    use_azuread_auth     = true
  }
}

provider "azurerm" {

  features {}

  use_oidc        = true

  subscription_id = var.subscription_id
}
