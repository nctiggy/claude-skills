---
name: spectrocloud-cluster-profiles
description: Create and manage Spectro Cloud Palette cluster profiles via API or Terraform. Covers pack discovery, CRUD operations, versioning, and import/export.
---

# Spectro Cloud Cluster Profiles

Cluster profiles define the software stack deployed on clusters.

## Profile Types

| Type | API Value | Use Case |
|------|-----------|----------|
| Infrastructure | `cluster` | OS, K8s, CNI, CSI layers |
| Add-on | `add-on` | Application packs only |

**Best Practice**: Create separate infrastructure and add-on profiles rather than one combined profile.

## Application Deployment Priority

When adding applications, search in this order:
1. **Pack** (preferred) - Search `Public Repo` registry first
2. **Helm** - Search `Bitnami` or other helm registries
3. **Manifest** - Use only when no pack/helm exists

## Before Creating Profiles

**Ask the user:**
1. Project name? (use `spectrocloud-common` skill for UID lookup)
2. Cloud type? (edge-native, maas, eks, etc.)
3. Profile type? (cluster or add-on)
4. What packs? (use `spectrocloud-common` skill for discovery)

## MANDATORY: Pack Values Workflow

**Partial pack values WILL fail validation.** Before creating ANY profile:

### Step 1: Fetch Complete Values for EVERY Pack
```bash
# Get pack UID first (with pagination - API limits to 50)
PACK_NAME="edge-k3s"
PACK_UID=$((for OFFSET in 0 50 100; do
  curl -s "https://api.spectrocloud.com/v1/packs?filters=metadata.name=$PACK_NAME&limit=50&offset=$OFFSET" \
    -H "ApiKey: $PALETTE_API_KEY" | jq '.items[]'
done) | jq -s -r '[.[] | select(.status.disabled != true)] |
  sort_by(.spec.version | split(".") | map(tonumber? // 0)) | reverse | .[0].metadata.uid')

# Fetch COMPLETE values - save to file
curl -s "https://api.spectrocloud.com/v1/packs/$PACK_UID?includePackValues=true" \
  -H "ApiKey: $PALETTE_API_KEY" | jq -r '.packValues[0].values' > pack-values.yaml
```

### Step 2: Modify Only What's Needed
Keep ALL other values intact. Only change specific fields.

### Step 3: Include ENTIRE Values File
```hcl
# NEVER DO THIS - partial values cause failures
values = <<-EOT
  options:
    system.uri: "my-image:tag"
EOT

# ALWAYS DO THIS - complete values with modification
values = file("pack-values-modified.yaml")
```

### Step 4: Update CIDRs in K8s Packs
- `cluster-cidr` → `100.64.0.0/18`
- `service-cidr` → `100.64.64.0/18`

## Pack Types (Registry Determines Type!)

| Registry Name | Pack `type` Value |
|---------------|-------------------|
| Public Repo | `spectro` |
| Bitnami | `helm` |
| Palette Community Registry | `oci` |

Mismatch causes: `PackType 'pack' is not matching with registry type 'oci'`

**Discover registries:**
```bash
curl -s "https://api.spectrocloud.com/v1/registries/metadata" -H "ApiKey: $PALETTE_API_KEY" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid, kind: .kind}]'
```

## Common Pack Names

| Search Term | Pack Name | Registry | Type |
|-------------|-----------|----------|------|
| metallb | `lb-metallb-helm` | Public Repo | `spectro` |
| nginx/ingress | `nginx` | Public Repo | `spectro` |
| hello-universe | `hello-universe` | Palette Community Registry | `oci` |
| calico | `cni-calico` | Public Repo | `spectro` |
| cilium | `cni-cilium-oss` | Public Repo | `spectro` |
| harbor | `harbor` | Bitnami | `helm` |

## Version Selection

Always use latest available version unless user specifies one:

```bash
curl -s "https://api.spectrocloud.com/v1/packs?limit=100&filters=metadata.name=PACK_NAME" \
  -H "ApiKey: $PALETTE_API_KEY" | jq '
  [.items[] | {name: .metadata.name, uid: .metadata.uid, tag: .spec.version,
   registry: .spec.registryUid, disabled: .status.disabled}]
  | map(select(.disabled != true))
  | sort_by(.tag | split(".") | map(tonumber? // 0))
  | reverse | .[0]'
```

## CRUD Operations

### Create (API)
```bash
curl -s -X POST "https://api.spectrocloud.com/v1/clusterprofiles?publish=true" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{"metadata": {"name": "my-profile"}, "spec": {...}}'
```

### Read
```bash
curl -s "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $PALETTE_API_KEY" -H "ProjectUid: $PROJECT_UID"
```

### Update (Create New Version)
**To update a profile deployed to a cluster:**
1. Create new version (same name, bumped version number)
2. Update cluster to use new version (see `spectrocloud-clusters` skill)

```bash
# Create new version of existing profile
curl -s -X POST "https://api.spectrocloud.com/v1/clusterprofiles?publish=true" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {"name": "my-existing-profile"},
    "spec": {
      "version": "1.1.0",
      ...
    }
  }'
# This creates version 1.1.0 alongside existing 1.0.0
```

### List Profile Versions
```bash
curl -s "https://api.spectrocloud.com/v1/clusterprofiles?filters=metadata.name=PROFILE_NAME" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid, version: .spec.version}]'
```

### Delete
```bash
curl -s -X DELETE "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $PALETTE_API_KEY" -H "ProjectUid: $PROJECT_UID"
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Parameter X value is required" | You used partial pack values - fetch and include complete defaults |
| "PackType 'pack' is not matching with registry type 'oci'" | Wrong pack type - check registry (Public Repo=spectro, Community=oci, Bitnami=helm) |
| Can't find latest pack version | API paginates at 50 - use offset parameter |
| Profile validation fails | Ensure ALL pack default values are included, not just modified sections |

## API Gotchas

- **Pagination**: API paginates at 50 results. Always use offset for pack discovery.
- **Filtering**: Often fails. Fetch all and filter with jq.

## BYOOS Pack Values

- **Agent Mode**: `options: { system.uri: "NA" }`
- **Appliance Mode**: Set `system.uri` to provider image URL

### CRITICAL: Provider Image / K8s Version Alignment

For appliance mode, **three components MUST align**:
1. **Provider image K8s version** - Built into image during CanvOS build
2. **BYOOS pack system.uri** - Must reference exact image tag from registry
3. **K8s layer version** - The edge-k3s pack version must match

**Workflow:**
1. After CanvOS build, check actual tag: `docker images | grep $IMAGE_REPO`
2. Use that EXACT tag in BYOOS `system.uri`
3. Set K8s pack version to match what was built (e.g., if you built with `K8S_VERSION=1.32.9`, use edge-k3s version 1.32.9)

**Failure mode**: Mismatched versions cause cluster provisioning to hang or fail.

## Terraform: Registry UID Required

When packs exist in multiple registries, `spectrocloud_pack` data source returns error:
```
Error: Multiple packs returned. Restrict packs criteria to a single match.
```

**Solution**: Always specify `registry_uid`:
```hcl
locals {
  palette_registry_uid = "5eecc89d0b150045ae661cef"  # Public Palette registry
}

data "spectrocloud_pack" "edge_k3s" {
  name         = "edge-k3s"
  version      = "1.32.9"
  registry_uid = local.palette_registry_uid  # Required!
}
```

Get registry UID:
```bash
curl -s "https://api.spectrocloud.com/v1/registries/metadata" -H "ApiKey: $API_KEY" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid}]'
```

## Profile Variables

Use for cluster-specific values: `{{ .spectro.var.K8sPodCIDR }}`, `{{ .spectro.var.K8sServiceCIDR }}`

## Additional Resources

- `references/api-examples.md` - Full API examples
- `references/terraform-examples.md` - Terraform patterns

## Quick Reference

| Operation | Endpoint |
|-----------|----------|
| Create & Publish | `POST /v1/clusterprofiles?publish=true` |
| Read | `GET /v1/clusterprofiles/{uid}` |
| Delete | `DELETE /v1/clusterprofiles/{uid}` |
| Get Pack Values | `GET /v1/packs/{uid}?includePackValues=true` |

## Links

- [API Docs](https://docs.spectrocloud.com/api/v1/clusterprofiles/)
- [Cluster Profiles](https://docs.spectrocloud.com/profiles/cluster-profiles/)
