packer {

  required_plugins {

    azure = {

      source  = "github.com/hashicorp/azure"

      version = ">= 2.0.0"
    }
  }
}

# ------------------------------------------------------------------
# Variables
#
# subscription_id  — from build_auto.pkrvars.hcl
# tenant_id        — from build_auto.pkrvars.hcl
# image_version    — injected by the pipeline at build time:
#                    packer build -var="image_version=1.20250525.42" .
#
#                    Format: Major.Minor.Patch
#                      Major = 1
#                      Minor = YYYYMMDD  (build date)
#                      Patch = GitHub run_number
#
#                    Azure SIG requires each part to be a 32-bit
#                    unsigned integer. This format satisfies that
#                    constraint and sorts chronologically.
#
#                    Never hardcode this variable — always let the
#                    pipeline inject it.
# ------------------------------------------------------------------

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "image_version" {
  type        = string
  description = "SIG image version in Major.Minor.Patch format. Injected by the pipeline."
}

# ------------------------------------------------------------------
# Source
# ------------------------------------------------------------------

source "azure-arm" "ubuntu" {

  use_azure_cli_auth = true

  subscription_id    = var.subscription_id

  tenant_id          = var.tenant_id

  os_type            = "Linux"

  image_publisher    = "Canonical"

  image_offer        = "0001-com-ubuntu-server-jammy"

  image_sku          = "22_04-lts-gen2"

  image_version      = "latest"

  location           = "canadacentral"

  vm_size            = ""Standard_B1s""

  communicator       = "ssh"

  ssh_username       = "azureuser"

  shared_image_gallery_destination {

    subscription   = var.subscription_id

    resource_group = "rg-canada-prod"

    gallery_name   = "canadaProdSIG"

    image_name     = "ubuntu-nginx"

    image_version  = var.image_version

    replication_regions = [
      "canadacentral"
    ]
  }
}

# ------------------------------------------------------------------
# Build
# ------------------------------------------------------------------

build {

  sources = [
    "source.azure-arm.ubuntu"
  ]

  provisioner "shell" {

    script = "${path.root}/scripts/install.sh"
  }
}
