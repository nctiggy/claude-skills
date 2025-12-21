---
name: spectrocloud-common
description: Common Spectro Cloud Palette utilities for API operations. Project lookup, pack discovery, registry types, and troubleshooting. Used by other Palette skills.
---

# Spectro Cloud Common Utilities

Shared utilities for all Palette API operations. Reference this skill for project/pack lookups.

## Authentication

All API calls require:
```bash
export PALETTE_API_KEY="<your-api-key>"
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

### Find Pack by Exact Name
```bash
curl -s "https://api.spectrocloud.com/v1/packs?filters=metadata.name=hello-universe&limit=50" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq '[.items[] | {name: .metadata.name, version: .spec.version, uid: .metadata.uid,
      registryUid: .spec.registryUid, layer: .spec.layer}] | sort_by(.version) | reverse'
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

## Terraform Data Sources

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
