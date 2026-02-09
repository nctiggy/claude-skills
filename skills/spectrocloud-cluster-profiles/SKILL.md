---
name: spectrocloud-cluster-profiles
description: Create and manage Spectro Cloud Palette cluster profiles via API or Terraform. Covers pack discovery, CRUD operations, versioning, import/export, and cross-tenant cloning.
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

**For edge-native profiles, determine K8s version FIRST:**
- Use `spectrocloud-common` skill's "K8s Version Discovery" section
- Default to **n-1 minor** (e.g., 1.32.x when 1.33 is latest) for stability
- Query before asking user - present the recommended version

```bash
# Quick check: Get recommended K8s version for edge profiles
PACK_NAME="edge-k3s"  # or edge-k8s for kubeadm
K8S_VERSION=$((for OFFSET in 0 50 100 150; do
  curl -s "https://api.spectrocloud.com/v1/packs?filters=metadata.name=$PACK_NAME&limit=50&offset=$OFFSET" \
    -H "ApiKey: $PALETTE_API_KEY" | jq '.items[]'
done) | jq -s '[.[] | select(.status.disabled != true) | .spec.version] | unique |
  sort_by(split(".") | map(tonumber)) | reverse |
  group_by(split(".")[0:2] | join(".")) |
  sort_by(.[0] | split(".") | map(tonumber)) | reverse | .[1][0] // .[0][0]')
echo "Recommended: $K8S_VERSION"
```

**ALWAYS get the latest version of each pack** unless the user specifies a version. Use the Version Selection query below for EVERY pack.

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

**BYOOS Pack (edge-native-byoi)**: Exists in TWO registries with different types:
- **Public Repo** (5eecc89d0b150045ae661cef) → `type = "spectro"` (recommended)
- **Palette Community Registry** (64eaff453040297344bcad5d) → `type = "oci"`

**Always use latest BYOOS version** (currently 2.1.0). Query to confirm:
```bash
curl -s "https://api.spectrocloud.com/v1/packs?filters=metadata.name=edge-native-byoi&limit=50" \
  -H "ApiKey: $API_KEY" | jq -r '[.items[] | select(.spec.registryUid == "5eecc89d0b150045ae661cef")] |
  sort_by(.spec.version | split(".") | map(tonumber)) | reverse | .[0] | {version: .spec.version, uid: .metadata.uid}'
```

Profile creation fails with "PackType 'X' is not matching with registry type 'Y'" if type doesn't match registry.

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

## Version Selection (MANDATORY)

**ALWAYS query for the latest version of EVERY pack** before creating profiles. Never assume or hardcode versions - they change frequently.

**CRITICAL**: API paginates at 50 results. Popular packs like Calico have many versions - you MUST use pagination to find the true latest:

```bash
# Get LATEST version of a pack (handles pagination properly)
PACK_NAME="cni-calico"  # Replace with actual pack name
LATEST=$((for OFFSET in 0 50 100 150; do
  curl -s "https://api.spectrocloud.com/v1/packs?filters=metadata.name=$PACK_NAME&limit=50&offset=$OFFSET" \
    -H "ApiKey: $PALETTE_API_KEY" | jq '.items[]'
done) | jq -s '[.[] | select(.status.disabled != true)] |
  sort_by(.spec.version | split(".") | map(tonumber? // 0)) |
  reverse | .[0] | {name: .metadata.name, version: .spec.version, uid: .metadata.uid, registry: .spec.registryUid}')
echo "$LATEST"
```

**Run this query for EACH pack you're adding to the profile.** Do not skip this step or use cached/remembered versions.

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

**Note**: Profile listing also paginates at 50 results. Use offset parameter for projects with many profiles.

```bash
# List all profiles (with pagination)
(for OFFSET in 0 50 100; do
  curl -s "https://api.spectrocloud.com/v1/clusterprofiles?limit=50&offset=$OFFSET" \
    -H "ApiKey: $PALETTE_API_KEY" \
    -H "ProjectUid: $PROJECT_UID" | jq '.items[]'
done) | jq -s '[.[] | {name: .metadata.name, uid: .metadata.uid, version: .spec.version}]'

# Filter by name (still use pagination if many versions)
curl -s "https://api.spectrocloud.com/v1/clusterprofiles?filters=metadata.name=PROFILE_NAME&limit=50" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid, version: .spec.version}]'
```

### Delete
```bash
curl -s -X DELETE "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $PALETTE_API_KEY" -H "ProjectUid: $PROJECT_UID"
```

## Cross-Tenant Profile Cloning

Clone profiles between different Palette tenants. Pack UIDs and registry UIDs differ between tenants, so a simple export/import won't work - you must resolve pack references in the destination tenant.

### Prerequisites

Set up environment variables for both tenants:
```bash
# Source tenant
export SRC_API_KEY="<source-tenant-api-key>"
export SRC_PROJECT_UID="<source-project-uid>"
export SRC_HOST="api.spectrocloud.com"  # or your self-hosted URL

# Destination tenant
export DST_API_KEY="<destination-tenant-api-key>"
export DST_PROJECT_UID="<destination-project-uid>"
export DST_HOST="api.spectrocloud.com"  # or your self-hosted URL

# Profile to clone
export PROFILE_UID="<profile-uid-to-clone>"
```

### Step 1: Export Profile from Source Tenant

```bash
curl -s "https://$SRC_HOST/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $SRC_API_KEY" \
  -H "ProjectUid: $SRC_PROJECT_UID" > profile-export.json

# Verify export
jq '{name: .metadata.name, version: .spec.version, packs: [.spec.published.packs[] | {name, tag, layer}]}' profile-export.json
```

### Step 2: Extract Pack References

```bash
# List packs that need resolution in destination tenant
jq -r '.spec.published.packs[] | "\(.name):\(.tag)"' profile-export.json
```

### Step 3: Resolve Packs in Destination Tenant

For **each pack** from Step 2, resolve its UID in the destination tenant:

```bash
# Resolve a single pack (repeat for each pack)
PACK_NAME="edge-k3s"
PACK_VERSION="1.32.9"

RESOLVED=$((for OFFSET in 0 50 100 150; do
  curl -s "https://$DST_HOST/v1/packs?filters=metadata.name=$PACK_NAME&limit=50&offset=$OFFSET" \
    -H "ApiKey: $DST_API_KEY" | jq '.items[]'
done) | jq -s --arg ver "$PACK_VERSION" '
  [.[] | select(.status.disabled != true and .spec.version == $ver)] | .[0] |
  {uid: .metadata.uid, registryUid: .spec.registryUid, type: .spec.type}')

echo "$PACK_NAME:$PACK_VERSION -> $RESOLVED"
```

**Build a mapping file** with all resolved packs:
```bash
# Create pack-mappings.json with structure:
# { "pack-name:version": { "uid": "...", "registryUid": "...", "type": "..." }, ... }
```

### Step 4: Transform Profile JSON

Replace source tenant UIDs with destination tenant UIDs:

```bash
# Transform profile with resolved pack mappings
jq --slurpfile mappings pack-mappings.json '
  # Remove source-specific fields
  del(.metadata.uid, .status, .spec.published) |

  # Use draft as template
  .spec.template = .spec.draft |
  del(.spec.draft) |

  # Update each pack with destination UIDs
  .spec.template.packs = [.spec.template.packs[] |
    . as $pack |
    ($mappings[0]["\($pack.name):\($pack.tag)"] // null) as $resolved |
    if $resolved then
      .uid = $resolved.uid |
      .registryUid = $resolved.registryUid
    else . end
  ]
' profile-export.json > profile-import.json
```

### Step 5: Import to Destination Tenant

```bash
curl -s -X POST "https://$DST_HOST/v1/clusterprofiles?publish=true" \
  -H "ApiKey: $DST_API_KEY" \
  -H "ProjectUid: $DST_PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d @profile-import.json | jq '{uid: .uid, name: .metadata.name}'
```

### Validation Checklist

Before importing, verify:
- [ ] All packs exist in destination tenant (Step 3 resolved all packs)
- [ ] Pack versions match exactly (or update to available versions)
- [ ] BYOOS `system.uri` updated if it references tenant-specific registry URLs

### BYOOS Pack Warning

If cloning profiles with BYOOS packs (appliance mode), the `system.uri` value references a container registry URL that may be tenant-specific. Update it manually:

```bash
# Check for BYOOS packs
jq '.spec.template.packs[] | select(.name == "edge-native-byoi") | .values' profile-import.json

# If system.uri points to source tenant's registry, update it for destination
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Parameter X value is required" | You used partial pack values - fetch and include complete defaults |
| "PackType 'pack' is not matching with registry type 'oci'" | Wrong pack type - check registry (Public Repo=spectro, Community=oci, Bitnami=helm) |
| Can't find latest pack version | API paginates at 50 - use offset parameter |
| Profile validation fails | Ensure ALL pack default values are included, not just modified sections |
| Profiles created but don't exist | Missing `project_name` in Terraform provider - profiles are orphaned |
| Terraform shows ID but API returns null | Add `project_name` to provider, `terraform state rm`, re-apply |
| Cross-tenant: Pack not found in destination | Pack may not exist or version differs - check available versions in destination tenant |
| Cross-tenant: Import fails with UID error | Pack/registry UIDs weren't resolved - run Step 3 for all packs |
| Cross-tenant: Profile imports but cluster fails | BYOOS `system.uri` still points to source tenant's registry - update for destination |

## API Gotchas

- **Pagination**: API paginates at 50 results. Always use offset for pack discovery.
- **Filtering**: Often fails. Fetch all and filter with jq.

## BYOOS Pack Values: Agent vs Edge Mode

The BYOOS (edge-native-byoi) pack is the **ONLY mode-specific pack** in a Palette Edge infrastructure profile. All other packs (K8s, CNI, storage) and all add-on profiles are mode-agnostic.

### Three Differences Between Agent and Edge Mode

| Config Area | Agent Mode | Edge/Appliance Mode |
|-------------|-----------|-------------------|
| `options.system.uri` | `"NA"` | Go template with sub-options (see below) |
| Containerd config | Spectro-specific paths | System defaults (no root/state/grpc/BinaryName) |
| Initramfs commands | `spectro.slice` + `system.slice` | `system.slice` only |

**Why they differ:** Agent mode runs a Spectro-managed containerd alongside the system containerd, so it needs custom paths (`/var/lib/spectro/containerd`, `/run/spectro/containerd`, `/opt/bin/runc`) and a separate `spectro.slice` for CPU isolation. Edge/appliance mode uses the OS-native containerd baked into the provider image.

### Agent Mode options block
```yaml
options:
  system.uri: "NA"
```

### Edge/Appliance Mode options block
```yaml
options:
    system.uri: "{{ .spectro.pack.edge-native-byoi.options.system.registry }}/{{ .spectro.pack.edge-native-byoi.options.system.repo }}:{{ .spectro.pack.edge-native-byoi.options.system.k8sDistribution }}-{{ .spectro.system.kubernetes.version }}-{{ .spectro.pack.edge-native-byoi.options.system.peVersion }}-{{ .spectro.pack.edge-native-byoi.options.system.customTag }}"
    system.registry: my-registry.company.local
    system.repo: ubuntu
    system.k8sDistribution: kubeadm
    system.osName: ubuntu
    system.peVersion: v4.5.11
    system.customTag: my-custom-tag
    system.osVersion: 24.04

# providerCredentials:
#   registry: my-registry.company.local
#   user: "user"
#   password: ""
```

**Note:** Edge options use 4-space indentation (not 2-space). This matches the API's stored format.

### Agent Mode containerd config (REMOVE these for edge)
```toml
root = "/var/lib/spectro/containerd"
state = "/run/spectro/containerd"
[grpc]
  address = "/run/spectro/containerd/containerd.sock"
# ... and in runc.options:
  BinaryName = "/opt/bin/runc"
```

### Edge Mode containerd config (system defaults)
```toml
version = 2
imports = ["/etc/containerd/conf.d/*.toml"]
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "registry.k8s.io/pause:3.10"
    # ... rest of config, NO root/state/grpc/BinaryName
```

### Agent Mode spectro.slice (REMOVE for edge)
```yaml
# Agent mode has BOTH lines:
- systemctl set-property system.slice AllowedCPUs={{ .spectro.var.systemReservedCPU }}
- systemctl set-property spectro.slice AllowedCPUs={{ .spectro.var.systemReservedCPU }}

# Edge mode has ONLY system.slice:
- systemctl set-property system.slice AllowedCPUs={{ .spectro.var.systemReservedCPU }}
```

### What NOT to Conflate

- **Mode differences** (agent vs edge): system.uri, containerd paths, spectro.slice
- **Storage-weight differences** (e.g., Piraeus vs Portworx): memory reservations, NFS config — these vary by storage, NOT by mode

When cloning from RA templates, verify you're cloning the correct mode variant (e.g., `VMO-RA-Infra-Edge-*` not `VMO-RA-Infra-Agent-*`).

### CRITICAL: Provider Image / K8s Version Alignment

For appliance/edge mode, **three components MUST align**:
1. **Provider image K8s version** - Built into image during CanvOS build
2. **BYOOS pack system.uri** - Must reference exact image tag from registry
3. **K8s layer version** - The edge-k8s/edge-k3s pack version must match

**Workflow:**
1. After CanvOS build, check actual tag: `docker images | grep $IMAGE_REPO`
2. Use that EXACT tag in BYOOS `system.uri`
3. Set K8s pack version to match what was built (e.g., if you built with `K8S_VERSION=1.33.6`, use edge-k8s version 1.33.6)

**Failure mode**: Mismatched versions cause cluster provisioning to hang or fail.

## Terraform: Critical Configuration

### CRITICAL: Provider project_name Required

**The `spectrocloud` provider MUST have `project_name` set for project-scoped resources:**

```hcl
provider "spectrocloud" {
  host         = "api.spectrocloud.com"
  api_key      = var.palette_api_key
  project_name = "My-Project"  # REQUIRED!
}
```

**Failure mode**: Without `project_name`, profiles appear to create successfully (Terraform shows IDs) but are orphaned and inaccessible in the project. The API returns null when querying.

**Detection**: Query the API to verify profiles exist:
```bash
curl -s "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $API_KEY" -H "ProjectUid: $PROJECT_UID" | jq '.metadata.name'
# Returns null if profile doesn't exist in project
```

**Fix**: Add `project_name` to provider, remove stale state (`terraform state rm`), re-apply.

### Registry UID Required

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
