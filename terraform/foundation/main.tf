# -----------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# -----------------------------------------------------------------
# Shared Image Gallery
# -----------------------------------------------------------------

resource "azurerm_shared_image_gallery" "sig" {
  name                = var.gallery_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# -----------------------------------------------------------------
# Image Definitions
#
# HOW TO ADD A NEW IMAGE:
#   1. Add a new azurerm_shared_image block below.
#   2. Create packer/<image-name>/ folder with .pkr.hcl + scripts/.
#   3. Push — pipeline auto-detects the new packer folder and builds it.
# -----------------------------------------------------------------

resource "azurerm_shared_image" "ubuntu_nginx" {
  name                = "ubuntu-nginx"
  gallery_name        = azurerm_shared_image_gallery.sig.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  hyper_v_generation  = "V2"

  identifier {
    publisher = "mycompany"
    offer     = "ubuntu"
    sku       = "nginx"
  }
}
