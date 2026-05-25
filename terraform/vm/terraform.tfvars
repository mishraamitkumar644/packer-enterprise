subscription_id     = "e397652c-2118-4f8c-918d-90f1bdb9bc73"

resource_group_name = "rg-canada-prod"

gallery_name        = "canadaProdSIG"

location            = "canadacentral"

vm_name             = "prod-nginx-vm"

image_name          = "ubuntu-nginx"

# image_version is intentionally left out here.
# The pipeline injects it via: -var="image_version=1.0.YYYYMMDDHHMMSS"
# For a manual apply outside CI, set it explicitly or leave as "latest".
