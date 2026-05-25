resource "azurerm_shared_image" "ubuntu_nginx" {

  name                = "ubuntu-nginx"

  gallery_name        = var.gallery_name

  resource_group_name = var.resource_group_name

  location            = var.location

  os_type             = "Linux"

  hyper_v_generation  = "V2"

  identifier {

    publisher = "mycompany"

    offer     = "ubuntu"

    sku       = "nginx"
  }
}

# -----------------------------------------------------------------
# HOW TO ADD A NEW IMAGE DEFINITION
#
#   1. Add a new "azurerm_shared_image" resource block in this
#      file (or create a separate .tf file in this folder).
#
#   2. Create a matching packer folder:
#        packer/<image-name>/
#          <image-name>_pkr.hcl
#          build_auto.pkrvars.hcl
#          scripts/install.sh
#
#   3. Push to main — the pipeline will automatically detect that
#      only packer/<image-name>/ changed and build only that image.
# -----------------------------------------------------------------
