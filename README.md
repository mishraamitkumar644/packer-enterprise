# Enterprise Platform Pipeline

## Folder Structure

```
.
├── .github/
│   └── workflows/
│       └── main.yml                      <- Pipeline (do not modify)
│
├── terraform/
│   ├── backend/                          <- Run ONCE manually before anything else
│   │   ├── provider.tf                   <- Local state only (bootstrap module)
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── main.tf                       <- Storage account + RBAC + versioning + soft delete
│   │   └── outputs.tf
│   │
│   ├── foundation/                       <- Resource Group + Shared Image Gallery
│   │   ├── provider.tf                   <- Remote backend (tfstate-foundation) + OIDC
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── rg.tf
│   │   └── sig.tf
│   │
│   ├── image-definition/                 <- SIG image definitions
│   │   ├── provider.tf                   <- Remote backend (tfstate-image-definition) + OIDC
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── ubuntu-nginx.tf               <- One .tf file per image
│   │
│   └── vm/                               <- VM deployment + backup
│       ├── provider.tf                   <- Remote backend (tfstate-vm) + OIDC
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── network.tf
│       ├── vm.tf                         <- VM pinned to exact image version
│       └── backup.tf                     <- Recovery Vault + policy + protected VM
│
└── packer/
    └── ubuntu-nginx/                     <- One folder per image
        ├── ubuntu-nginx_pkr.hcl
        ├── build_auto.pkrvars.hcl
        └── scripts/
            └── install.sh
```

---

## Pipeline Flow

```
foundation -> image-definition -> detect-images -> packer-build -> vm
 (RG + SIG)   (SIG definitions)   (version +        (parallel,    (deploy pinned
                                   what changed?)    versioned)     image version)
```

**On push:** Only the packer folders that changed in the commit are built.

**On workflow_dispatch (manual run):** All packer folders are built.

---

## Terraform State Management

### Why this setup

Every Terraform module stores its state remotely in Azure Blob Storage. Without
this, state lives only on the machine that ran `terraform apply` — if that machine
is gone, the state is gone, and Terraform loses track of what it created.

### What the backend module creates

| What | Detail |
|------|--------|
| Dedicated resource group `rg-tfstate` | Fully isolated from application resource groups. A `terraform destroy` on any app stack cannot reach this group. |
| Storage account with AD-only auth | `shared_access_key_enabled = false` — storage account keys are never generated. All access goes through Azure AD. |
| Blob versioning enabled | Every state write (apply, state mv, import, etc.) keeps the previous version. Any prior state can be restored from the Azure Portal or via `az storage blob restore`. |
| Soft delete — 30 days | If a state blob is deleted — accidentally or maliciously — it is recoverable for 30 days before permanent removal. |
| `prevent_destroy = true` | Terraform will refuse to destroy the storage account even on an explicit `terraform destroy`. |
| RBAC assignment | The pipeline managed identity is granted `Storage Blob Data Contributor` on the storage account. No keys, no secrets. |

### State locking

Terraform's `azurerm` backend uses **Azure Blob Storage native leases** for state
locking. When a `terraform apply` starts, it acquires an exclusive lease on the
state blob. Any concurrent apply against the same state file is blocked immediately
with an error. The lease is released automatically when the operation completes or
times out. No additional infrastructure is required for locking.

### Authentication from the pipeline

All three module backends are configured with:

```hcl
use_oidc         = true   # authenticate using the GitHub Actions OIDC token
use_azuread_auth = true   # access the blob using Azure AD, not storage keys
```

This means no storage account keys or client secrets are ever stored in GitHub
secrets or passed through the pipeline.

---

## Image Versioning

### Version format

```
1.YYYYMMDD.run_number    e.g.  1.20250525.42
```

| Segment | Value | Reason |
|---------|-------|--------|
| Major | `1` | Fixed. Increment manually only for a breaking image change. |
| Minor | `YYYYMMDD` | Build date. Max value `99991231` — well within the Azure SIG 32-bit integer limit of `2,147,483,647`. |
| Patch | `github.run_number` | Auto-incrementing integer starting at `1`. Guaranteed unique per workflow. Never overflows. |

**Why not use a timestamp for all three parts?**
Azure SIG enforces that each part of `Major.Minor.Patch` is a 32-bit unsigned
integer. A full timestamp (`YYYYMMDDHHmmss` = `20250525143022`) exceeds the
`2,147,483,647` limit and Azure rejects it with a validation error.

### How the version flows through the pipeline

```
detect-images job
  VERSION = "1.$(date +'%Y%m%d').${{ github.run_number }}"
  e.g.    = "1.20250525.42"
       |
       +---> packer-build job
       |       packer build -var="image_version=1.20250525.42" .
       |       -> SIG image version  1.20250525.42  created
       |
       +---> vm job
               terraform apply -var="image_version=1.20250525.42"
               -> VM pinned to exact SIG version  1.20250525.42
```

The version is generated once and flows to both Packer and Terraform. The VM is
never deployed against an unknown `latest` — it always uses the exact version built
in that pipeline run.

---

## First-Time Setup (Run Once Manually)

Before the pipeline can run, bootstrap the remote state storage:

```bash
cd terraform/backend
terraform init
terraform apply
```

This creates the storage account, all three blob containers, and the RBAC
assignment for the pipeline identity. After this, all pipeline runs use remote
state automatically.

---

## How to Add a New Image

### Step 1 — Add a Terraform image definition

Create a new file in `terraform/image-definition/`, for example `ubuntu-apache.tf`:

```hcl
resource "azurerm_shared_image" "ubuntu_apache" {
  name                = "ubuntu-apache"
  gallery_name        = var.gallery_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  hyper_v_generation  = "V2"
  identifier {
    publisher = "mycompany"
    offer     = "ubuntu"
    sku       = "apache"
  }
}
```

### Step 2 — Create a Packer folder

```
packer/ubuntu-apache/
├── ubuntu-apache_pkr.hcl        <- Copy ubuntu-nginx_pkr.hcl
├── build_auto.pkrvars.hcl       <- Same credentials file
└── scripts/
    └── install.sh               <- Your install script
```

Change only this line in the copied `.hcl` file:

```hcl
image_name = "ubuntu-apache"     # inside shared_image_gallery_destination
```

The `image_version` variable requires no change — the pipeline injects it automatically.

### Step 3 — Commit and push

```bash
git add packer/ubuntu-apache/ terraform/image-definition/ubuntu-apache.tf
git commit -m "feat: add ubuntu-apache image"
git push origin main
```

The pipeline detects only `packer/ubuntu-apache/` changed and builds only that image.
All existing images are untouched.

---

## GitHub Secrets Required

| Secret                  | Description                                    |
|-------------------------|------------------------------------------------|
| `AZURE_CLIENT_ID`       | Managed Identity / Service Principal client ID |
| `AZURE_TENANT_ID`       | Azure Tenant ID                                |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID                          |
