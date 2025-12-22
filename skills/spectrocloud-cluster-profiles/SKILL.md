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

## Critical: Pack Values

Partial pack values WILL fail validation.

1. **Fetch complete default values**:
   ```bash
   curl -s "https://api.spectrocloud.com/v1/packs/{PACK_UID}?includePackValues=true" \
     -H "ApiKey: $PALETTE_API_KEY" | jq -r '.packValues[0].values'
   ```
2. **Keep the ENTIRE default values file**
3. Only modify specific sections you need
4. **ALWAYS update CIDRs** in K8s packs:
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

## API Gotchas

- **Pagination**: Max `limit` ~200. Using 500 returns null.
- **Filtering**: Often fails. Fetch all and filter with jq.

## BYOOS Pack Values

- **Agent Mode**: `options: { system.uri: "NA" }`
- **Appliance Mode**: Set `system.uri` to provider image URL

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
