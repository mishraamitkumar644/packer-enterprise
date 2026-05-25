# -----------------------------------------------------------------
# Image version lookup
# The pipeline passes the exact version string built by Packer
# (e.g. 1.0.20250525143022) via -var="image_version=...".
# Using a pinned version means every pipeline run is reproducible —
# re-running the vm job always uses the same image that was just
# built, not whatever happens to be "latest" at that moment.
# -----------------------------------------------------------------

data "azurerm_shared_image_version" "image" {

  name                = var.image_version

  image_name          = var.image_name

  gallery_name        = var.gallery_name

  resource_group_name = var.resource_group_name
}

# -----------------------------------------------------------------
# Virtual Machine
# -----------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "vm" {

  name                = var.vm_name

  resource_group_name = var.resource_group_name

  location            = var.location

  size                = "Standard_D2s_v5"

  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {

    username   = "azureuser"

    public_key = file("~/.ssh/id_rsa.pub")
  }

  # Pinned to the exact version built in this pipeline run
  source_image_id = data.azurerm_shared_image_version.image.id

  os_disk {

    caching              = "ReadWrite"

    storage_account_type = "Standard_LRS"
  }
}
