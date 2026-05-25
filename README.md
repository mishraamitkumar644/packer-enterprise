# Azure Image Pipeline

Builds VM images with Packer, stores versions in a Shared Image Gallery,
then deploys a VM using pure Azure CLI — no Terraform state for the VM.

## Directory structure

```
project/
├── .github/workflows/main.yml       # Pipeline definition
├── packer/
│   └── ubuntu-nginx/                # One folder per image
│       ├── ubuntu-nginx_pkr.hcl
│       ├── build_auto.pkrvars.hcl
│       └── scripts/install.sh
└── terraform/
    ├── backend/                     # Run ONCE manually to create tfstate storage
    ├── foundation/                  # Resource Group + Shared Image Gallery
    └── image-definition/            # SIG image definitions
```

## How the pipeline works

```
push to main
     │
     ├── terraform/foundation/**  changed? ──► foundation job   (terraform apply)
     ├── terraform/image-definition/** changed? ► image-definition job (terraform apply)
     │
     └── packer/** changed?
              │
              ▼
         detect-images
         Finds changed packer/* folders + builds version: 1.YYYYMMDD.RUNNUMBER
              │
              ▼
         packer-build  (parallel — one job per changed folder)
         Builds image → stores in SIG under the exact version
              │
              ▼
         deploy-vm  (Azure CLI, no tfstate)
         Delete old VM → create new VM from exact image version
```

`foundation` and `image-definition` **only** run when their own files change.
They do not block or gate packer builds.

## Image versioning

Every pipeline run produces a version string: `1.YYYYMMDD.RUNNUMBER`

- `Major` = 1 (bump manually for breaking image changes)
- `Minor` = build date e.g. `20250525`
- `Patch` = `github.run_number` — auto-incrementing, unique per workflow

Azure SIG requires each segment to be a 32-bit unsigned integer. This scheme
satisfies that, sorts chronologically, and is globally unique per run.

## VM deployment (stateless)

The `deploy-vm` job uses Azure CLI only:

1. Networking (VNet, subnet, NSG, public IP, NIC) is created once and reused.
2. If a VM with the same name already exists it is deleted (along with its OS
   disk) before re-creation. This keeps the deployment fully idempotent without
   any state file.
3. The VM is created from the exact SIG image version built in the same run.

## Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | Service principal / managed identity client ID |
| `AZURE_TENANT_ID` | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_VM_SSH_PUBLIC_KEY` | SSH public key string for the VM admin user |

OIDC federated credentials must be configured on the app registration so
GitHub Actions can exchange tokens without a stored client secret.

## One-time bootstrap

Run the backend module **once** from your local machine before using the pipeline:

```bash
cd terraform/backend
terraform init
terraform apply
```

This creates the storage account and containers used by `foundation` and
`image-definition` for their remote state.

## Adding a new image

1. Create `packer/<image-name>/` with a `.pkr.hcl`, `build_auto.pkrvars.hcl`,
   and `scripts/install.sh`.

2. Add an `azurerm_shared_image` block to
   `terraform/image-definition/ubuntu-nginx.tf` (or a new `.tf` file there).

3. Push to main — the pipeline automatically detects only `packer/<image-name>/`
   changed and builds only that image.

## Adding a new VM

Add a new `deploy-vm`-style job to the workflow that references a different
`IMAGE_DEFINITION` and `VM_NAME`. All networking steps follow the same
pattern — check-then-create for stable resources, delete-then-recreate for
the VM itself.
