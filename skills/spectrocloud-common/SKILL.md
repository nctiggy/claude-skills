---
name: spectrocloud-common
description: Common Spectro Cloud Palette utilities for API operations. Project lookup, pack discovery, registry types, and troubleshooting. Used by other Palette skills.
---

# Spectro Cloud Common Utilities

Shared utilities for all Palette API operations. Reference this skill for project/pack lookups.

## End-to-End Workflow

**For meeting prep / demo setup, follow this order:**

1. **Get credentials** → Check 1Password for `palette-api-key`, set `PALETTE_API_KEY`
2. **Get project** → Ask user for project name, look up `PROJECT_UID`
3. **Discover existing resources** → List profiles, clusters, edge hosts
4. **Decide what to create/update** → Present findings to user
5. **Create/update profiles** → Use `spectrocloud-cluster-profiles` skill
6. **Create cluster** → Use `spectrocloud-clusters` skill (if edge hosts available)
7. **Verify deployment** → Check cluster state, get kubeconfig

**API vs Terraform decision:**
- **API**: Quick one-off demos, testing, exploration
- **Terraform**: Repeatable deployments, production, GitOps workflows

## Authentication

All API calls require `PALETTE_API_KEY` and `PROJECT_UID` environment variables.

### Get Credentials from 1Password

**Preferred method** - Use 1Password CLI or MCP tools:
```bash
# Using op CLI (if user has 1Password configured)
export PALETTE_API_KEY=$(op read "op://k8s vault/palette-api-key/credential")

# Or ask Claude to use MCP tools:
# - mcp__subtle-bug__op_list_items to find the secret
# - mcp__subtle-bug__op_inject_secret to retrieve it
```

**Manual method** (less preferred):
```bash
export PALETTE_API_KEY="<your-api-key>"
```

**Before any Palette API operations**, verify credentials are set:
```bash
# Test API connectivity
curl -s "https://api.spectrocloud.com/v1/projects" \
  -H "ApiKey: $PALETTE_API_KEY" | jq 'if .items then "OK: Found \(.items | length) projects" else "ERROR: \(.)" end'
```

---

## Project Lookup

API calls require a Project UID. Ask for the project **name**, then look it up:

```bash
# List all projects
curl -s "https://api.spectrocloud.com/v1/projects" \
  -H "ApiKey: $PALETTE_API_KEY" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid}]'
```

**If name isn't an exact match**, search case-insensitively:
```bash
PROJECT_NAME="demo"
curl -s "https://api.spectrocloud.com/v1/projects" \
  -H "ApiKey: $PALETTE_API_KEY" | \
  jq --arg name "$PROJECT_NAME" '[.items[] |
    select(.metadata.name | ascii_downcase | contains($name | ascii_downcase)) |
    {name: .metadata.name, uid: .metadata.uid}]'
```

**If multiple matches**, present options to user and confirm before proceeding.

---

## Pack Discovery

**Ask user for the pack name.** If unknown, suggest browsing Palette UI or searching.

### Find Pack by Exact Name (All Versions, Newest First)

**Important**: Pack API paginates at 50 results. Newer versions may require offset parameter.

```bash
# Get ALL versions of a pack (handles pagination)
PACK_NAME="edge-k3s"
(for OFFSET in 0 50 100 150; do
  curl -s "https://api.spectrocloud.com/v1/packs?filters=metadata.name=$PACK_NAME&limit=50&offset=$OFFSET" \
    -H "ApiKey: $PALETTE_API_KEY" | \
    jq '[.items[] | select(.status.disabled != true) |
      {name: .metadata.name, version: .spec.version, uid: .metadata.uid,
       registryUid: .spec.registryUid, layer: .spec.layer}]'
done) | jq -s 'add | sort_by(.version | split(".") | map(tonumber? // 0)) | reverse'
```

### Get Pack Default Values (Critical!)
```bash
# Fetch the COMPLETE default values for a pack
curl -s "https://api.spectrocloud.com/v1/packs/$PACK_UID?includePackValues=true" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | jq -r '.packValues[0].values'
```

**Important workflow for pack values:**
1. **Fetch the entire default values file** - don't summarize or truncate
2. **Keep ALL default values intact** - include the complete file in your profile
3. **Only modify specific sections** you need to change
4. Never strip out sections - missing values cause validation failures

### Search Packs by Keyword
```bash
KEYWORD="hello"
curl -s "https://api.spectrocloud.com/v1/packs?filters=spec.layer=addon&limit=100" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq --arg kw "$KEYWORD" '[.items[] | select(.metadata.name | ascii_downcase | contains($kw | ascii_downcase)) |
      {name: .metadata.name, version: .spec.version}] | unique_by(.name)'
```

---

## Registry Types

| Registry Type | Example Name | Notes |
|---------------|--------------|-------|
| Pack | "Public Repo" | Standard packs (metallb, cni, etc.) |
| Helm | "Bitnami" | Helm charts indexed as packs |
| OCI | (various) | Some packs use OCI registries |

**Important**: If a pack isn't found with a specific registry, omit `registry_uid` to let Terraform auto-discover.

### List Available Registries
```bash
# Pack registries
curl -s "https://api.spectrocloud.com/v1/registries/pack?limit=50" \
  -H "ApiKey: $PALETTE_API_KEY" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid}]'

# Helm registries
curl -s "https://api.spectrocloud.com/v1/registries/helm?limit=50" \
  -H "ApiKey: $PALETTE_API_KEY" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid, endpoint: .spec.endpoint}]'
```

---

## Discovery: What Exists?

Before creating resources, check what already exists:

### List Cluster Profiles
```bash
curl -s "https://api.spectrocloud.com/v1/clusterprofiles" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid, version: .spec.version, type: .spec.published.type}]'
```

### List Edge Clusters
```bash
curl -s "https://api.spectrocloud.com/v1/spectroclusters?filters=spec.cloudType=edge-native" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid, state: .status.state}]'
```

### List Edge Hosts (with status)
```bash
curl -s "https://api.spectrocloud.com/v1/edgehosts" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid, state: .status.state,
      health: .status.health.state, clusterUid: .status.clusterUid}]'
```

### Get Latest Pack Version

**Important**: API paginates at 50. Always check multiple pages for recent K8s versions.

```bash
# Get latest version with pagination (required for packs with many versions)
PACK_NAME="edge-k3s"
(for OFFSET in 0 50 100 150; do
  curl -s "https://api.spectrocloud.com/v1/packs?filters=metadata.name=$PACK_NAME&limit=50&offset=$OFFSET" \
    -H "ApiKey: $PALETTE_API_KEY" | jq '.items[]'
done) | jq -s '[.[] | select(.status.disabled != true)] |
  sort_by(.spec.version | split(".") | map(tonumber? // 0)) |
  reverse | .[0] | {name: .metadata.name, version: .spec.version, uid: .metadata.uid}'
```

---

## Terraform Setup

### Provider Configuration
```hcl
terraform {
  required_providers {
    spectrocloud = {
      source  = "spectrocloud/spectrocloud"
      version = ">= 0.22.0"
    }
  }
}

provider "spectrocloud" {
  host    = var.palette_host      # "api.spectrocloud.com" for SaaS
  api_key = var.palette_api_key   # From 1Password or env var

  # Optional: project_name to scope all resources
  # project_name = "my-project"
}

variable "palette_host" {
  default = "api.spectrocloud.com"
}

variable "palette_api_key" {
  sensitive = true
}
```

### tfvars Pattern
```hcl
# terraform.tfvars (do NOT commit to git)
palette_api_key = "your-api-key"

# Or use environment variable:
# export TF_VAR_palette_api_key=$(op read "op://k8s vault/palette-api-key/credential")
```

### Modular Structure (Recommended)

**Separate profiles from clusters** for independent lifecycle management:

```
palette-demo/
├── shared/
│   └── providers.tf      # Shared provider config (symlinked)
├── profiles/
│   ├── providers.tf -> ../shared/providers.tf
│   ├── main.tf           # Cluster profiles only
│   ├── variables.tf
│   └── terraform.tfvars
└── clusters/
    ├── providers.tf -> ../shared/providers.tf
    ├── main.tf           # Clusters only (uses data sources for profiles)
    ├── variables.tf
    └── terraform.tfvars
```

**Benefits:**
- Delete cluster without affecting profiles: `cd clusters && terraform destroy`
- Update profiles independently: `cd profiles && terraform apply`
- Demo profile versioning without cluster changes
- Cleaner state management

**Workflow:**
```bash
# 1. Create profiles first
cd profiles && terraform init && terraform apply

# 2. Create clusters (references profiles via data sources)
cd ../clusters && terraform init && terraform apply

# 3. Demo: Delete just the cluster
cd clusters && terraform destroy

# 4. Demo: Update profile, then update cluster
cd profiles && terraform apply  # Creates new version
cd ../clusters && terraform apply  # Updates to new version
```

### Project Lookup
```hcl
data "spectrocloud_project" "this" {
  name = "my-project"
}
# Use: data.spectrocloud_project.this.id
```

### Pack Lookup (with auto-discovery)
```hcl
# Omit registry_uid to auto-discover the correct registry
data "spectrocloud_pack" "hello_universe" {
  name    = "hello-universe"
  version = "1.2.0"
}

# With explicit registry (if you know it)
data "spectrocloud_pack" "metallb" {
  name         = "lb-metallb-helm"
  version      = "0.14.9"
  registry_uid = data.spectrocloud_registry.public.id
}

data "spectrocloud_registry" "public" {
  name = "Public Repo"
}
```

### Helm Chart as Pack
```hcl
# Helm charts are indexed as packs - versions differ from source repos
data "spectrocloud_pack" "harbor" {
  name         = "harbor"
  version      = "16.3.3"  # Palette's version, not Bitnami's
  registry_uid = data.spectrocloud_registry.bitnami.id
}

data "spectrocloud_registry" "bitnami" {
  name = "Bitnami"
}
```

---

## Common Edge-Native Packs

| Layer | Pack Name | Notes |
|-------|-----------|-------|
| os | `edge-native-byoi` | Agent or appliance mode |
| k8s | `edge-k3s` | K3s (required for 2-node) |
| k8s | `edge-k8s` | Kubeadm |
| cni | `cni-calico` | Calico |
| cni | `cni-cilium-oss` | Cilium |
| addon | `hello-universe` | Demo app |

---

## Common Gotchas

| Issue | Solution |
|-------|----------|
| "no matching packs" | Omit `registry_uid` to auto-discover |
| "pack not found with tag X" | Check versions via API, not source repo |
| "Parameter X value is required" | Fetch and include pack default values |
| Pack in wrong registry | Some packs exist in multiple registries |
| Project not found | Use project name lookup, not hardcoded UID |
| Can't find latest K8s version | API paginates at 50 - use offset parameter (0, 50, 100, 150) |
| API returns empty for recent versions | Pagination issue - newer versions beyond first 50 results |

---

## Quick Reference

| Item | Endpoint |
|------|----------|
| List Projects | `GET /v1/projects` |
| Find Pack | `GET /v1/packs?filters=metadata.name=<name>` |
| Get Pack Values | `GET /v1/packs/{uid}?includePackValues=true` |
| List Pack Registries | `GET /v1/registries/pack` |
| List Helm Registries | `GET /v1/registries/helm` |
| Required Headers | `ApiKey`, `ProjectUid` (for pack calls) |

## Links

- [API Introduction](https://docs.spectrocloud.com/api/introduction/)
- [Palette API Reference](https://docs.spectrocloud.com/api/category/palette-api-v1/)
