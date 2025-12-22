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

**Best Practice**: Create separate infrastructure and add-on profiles rather than one combined profile. This allows reusing the infra profile across clusters while customizing add-ons per deployment.

## Application Deployment Priority

When adding applications to a profile, search in this order:
1. **Pack** (preferred) - Search `Public Repo` registry first
2. **Helm** - Search `Bitnami` or other helm registries
3. **Manifest** - Use only when no pack/helm exists

Packs have better Palette integration (updates, drift detection). Use manifests as a last resort.

## Before Creating Profiles

**Ask the user:**
1. What project name? (use `spectrocloud-common` skill to look up UID)
2. What cloud type? (edge-native, maas, eks, etc.)
3. Profile type? (cluster or add-on)
4. What packs? (use `spectrocloud-common` skill to discover packs)

**⚠️ CRITICAL - Pack Values:**

Partial pack values WILL fail validation (e.g., `Parameter 'manifests.hello-universe.replicas' value is required`).

1. **ALWAYS fetch complete default values** before creating profiles:
   ```bash
   curl -s "https://api.spectrocloud.com/v1/packs/{PACK_UID}?includePackValues=true" \
     -H "ApiKey: $PALETTE_API_KEY" | jq -r '.packValues[0].values'
   ```
2. **Keep the ENTIRE default values file** - do not summarize or truncate
3. Only modify specific sections you need to change
4. Include full values in the profile - missing values cause validation failures
5. **ALWAYS update CIDRs** in K8s packs (k3s, kubeadm, etc.):
   - Change `cluster-cidr`/pod CIDR to `100.64.0.0/18`
   - Change `service-cidr` to `100.64.64.0/18`
   - Pack defaults (e.g., 192.168.x.x) will cause conflicts

---

## CRUD Operations

### CREATE: Infrastructure Profile
```bash
# Use ?publish=true to create and publish in one call
curl -s -X POST "https://api.spectrocloud.com/v1/clusterprofiles?publish=true" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {"name": "my-edge-infra"},
    "spec": {
      "version": "1.0.0",
      "template": {
        "type": "cluster",
        "cloudType": "edge-native",
        "packs": [
          {
            "name": "edge-native-byoi",
            "layer": "os",
            "tag": "2.0.0",
            "uid": "<pack-uid>",
            "registryUid": "<registry-uid>",
            "type": "spectro",
            "values": "options:\n  system.uri: \"NA\""
          },
          {
            "name": "edge-k3s",
            "layer": "k8s",
            "tag": "1.30.5",
            "uid": "<pack-uid>",
            "registryUid": "<registry-uid>",
            "type": "spectro",
            "values": ""
          },
          {
            "name": "cni-calico",
            "layer": "cni",
            "tag": "3.28.2",
            "uid": "<pack-uid>",
            "registryUid": "<registry-uid>",
            "type": "spectro",
            "values": ""
          }
        ]
      }
    }
  }'
# Returns: {"uid": "profile-uid"}
```

### CREATE: Add-on Profile
```bash
curl -s -X POST "https://api.spectrocloud.com/v1/clusterprofiles?publish=true" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {"name": "my-addon"},
    "spec": {
      "version": "1.0.0",
      "template": {
        "type": "add-on",
        "cloudType": "all",
        "packs": [
          {
            "name": "dex",
            "layer": "addon",
            "tag": "2.42.0",
            "uid": "<pack-uid>",
            "registryUid": "<registry-uid>",
            "type": "spectro",
            "values": ""
          }
        ]
      }
    }
  }'
```

### READ: Get Profile
```bash
# By UID
curl -s "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | jq '{
    name: .metadata.name,
    uid: .metadata.uid,
    version: .spec.version,
    cloudType: .spec.published.cloudType,
    packs: [.spec.published.packs[] | {name, layer, tag}]
  }'
```

### UPDATE: Create New Version
```bash
# Same profile name + different version = NEW UID (both appear in UI with version dropdown)
curl -s -X POST "https://api.spectrocloud.com/v1/clusterprofiles?publish=true" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {"name": "my-edge-infra"},
    "spec": {
      "version": "1.1.0",
      "template": { ... }
    }
  }'
```

### DELETE: Remove Profile
```bash
curl -s -X DELETE "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID"
# Returns HTTP 204 on success
```

---

## API Gotchas

**Pagination**: Max `limit` is ~200. Using `limit=500` returns null. Always check `.items | length`.

**Filtering**: `filters=spec.registryUid=xxx` often fails. Better to fetch all and filter with jq:
```bash
curl -s "https://api.spectrocloud.com/v1/packs?limit=200" ... | \
  jq '[.items[] | select(.spec.registryUid == "xxx")]'
```

---

## Version Selection Policy

**Always use the latest available version unless user explicitly specifies one.**

```bash
curl -s "https://api.spectrocloud.com/v1/packs?limit=100&filters=metadata.name=PACK_NAME" \
  -H "ApiKey: $PALETTE_API_KEY" | jq '
  [.items[] | {name: .metadata.name, uid: .metadata.uid, tag: .spec.version, registry: .spec.registryUid, disabled: .status.disabled}]
  | map(select(.disabled != true))
  | sort_by(.tag | split(".") | map(tonumber? // 0))
  | reverse | .[0]'
```

**Rules:**
1. Filter out disabled packs (`disabled != true`)
2. Sort by semantic version (`3.13.0 > 3.9.0`)
3. Prefer "Public Repo" registry when pack exists in multiple
4. Use latest unless user explicitly requests a version

**Pre-flight validation:**
```bash
curl -s "https://api.spectrocloud.com/v1/packs/PACK_UID" -H "ApiKey: $PALETTE_API_KEY" | \
  jq '{name: .name, disabled: .status.disabled, registryUid: .registryUid}'
```

---

## Manifests and Helm Charts

### Pack Types - Registry Determines Type!

**Critical rule**: The pack type is determined by the **registry type**, not pack contents.

| Registry Name | Pack `type` Value |
|---------------|-------------------|
| Public Repo | `spectro` |
| Bitnami | `helm` |
| Palette Community Registry | `oci` |

**Mismatch causes**: `PackType 'pack' is not matching with registry type 'oci'`

**Discover registries:**
```bash
curl -s "https://api.spectrocloud.com/v1/registries/metadata" -H "ApiKey: $PALETTE_API_KEY" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid, kind: .kind}]'
```

### Pack Naming

Pack names aren't always obvious. Common mappings:

| Search Term | Pack Name | Registry | Type |
|-------------|-----------|----------|------|
| metallb | `lb-metallb-helm` | Public Repo | `spectro` |
| nginx/ingress | `nginx` | Public Repo | `spectro` |
| opa/gatekeeper | `open-policy-agent` | Public Repo | `spectro` |
| hello-universe | `hello-universe` | Palette Community Registry | `oci` |
| calico | `cni-calico` | Public Repo | `spectro` |
| cilium | `cni-cilium-oss` | Public Repo | `spectro` |
| harbor | `harbor` | Bitnami | `helm` |

**Preferred registry**: Use "Public Repo" when a pack exists in multiple registries.

### Add Manifest Pack (Add-on Profile)
```bash
# Manifest packs work in add-on profiles (not infra-only)
curl -s -X POST "https://api.spectrocloud.com/v1/clusterprofiles?publish=true" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {"name": "my-manifest-addon"},
    "spec": {
      "version": "1.0.0",
      "template": {
        "type": "add-on",
        "cloudType": "all",
        "packs": [
          {
            "name": "my-namespace",
            "layer": "addon",
            "type": "manifest",
            "tag": "1.0.0",
            "values": "pack:\n  namespace: default",
            "manifests": [
              {
                "name": "namespace-manifest",
                "content": "apiVersion: v1\nkind: Namespace\nmetadata:\n  name: my-app"
              }
            ]
          }
        ]
      }
    }
  }'
```

### Add Manifest to Existing Pack Layer
```bash
# Attach manifests to any pack (infra or addon) after profile creation
curl -s -X POST "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID/packs/$PACK_NAME/manifests" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "custom-config",
    "content": "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: my-config\ndata:\n  key: value"
  }'
# Returns: {"uid": "manifest-uid"}
```

### Get Manifest Content
```bash
curl -s "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID/packs/$PACK_NAME/manifests/$MANIFEST_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | jq '.spec.published.content'
```

### List Helm Registries
```bash
curl -s "https://api.spectrocloud.com/v1/registries/helm?limit=20" \
  -H "ApiKey: $PALETTE_API_KEY" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid, endpoint: .spec.endpoint}]'
```

### Terraform: Manifest Pack (Multiple Files)
```hcl
resource "spectrocloud_cluster_profile" "addon" {
  name    = "manifest-example"
  type    = "add-on"
  cloud   = "all"
  version = "1.0.0"

  pack {
    name = "my-manifests"
    type = "manifest"

    manifest {
      name    = "namespace"
      content = <<-EOT
        apiVersion: v1
        kind: Namespace
        metadata:
          name: my-app
      EOT
    }
    manifest {
      name    = "configmap"
      content = <<-EOT
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: app-config
          namespace: my-app
        data:
          key: value
      EOT
    }
  }
}
```

### Terraform: Attach Manifest to Existing Pack
```hcl
pack {
  name = data.spectrocloud_pack.hello_universe.name
  tag  = data.spectrocloud_pack.hello_universe.version
  uid  = data.spectrocloud_pack.hello_universe.id

  # Attach additional manifest to this pack
  manifest {
    name    = "extra-configmap"
    content = <<-EOT
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: hello-config
      data:
        setting: enabled
    EOT
  }
}
```

### Terraform: Helm Pack

**Helm charts are indexed as packs** - use `data "spectrocloud_pack"`, not direct registry references.
Version numbers in Palette differ from source repos (e.g., harbor `16.3.3` not `24.0.3`).

```hcl
# Look up helm chart as a pack
data "spectrocloud_pack" "harbor" {
  name         = "harbor"
  version      = "16.3.3"  # Palette's indexed version
  registry_uid = data.spectrocloud_registry.bitnami.id
}

data "spectrocloud_registry" "bitnami" {
  name = "Bitnami"
}

resource "spectrocloud_cluster_profile" "helm-addon" {
  name    = "helm-example"
  type    = "add-on"
  cloud   = "all"
  version = "1.0.0"

  pack {
    name         = data.spectrocloud_pack.harbor.name
    tag          = data.spectrocloud_pack.harbor.version
    uid          = data.spectrocloud_pack.harbor.id
    registry_uid = data.spectrocloud_registry.bitnami.id
    type         = "helm"
    values       = <<-EOT
      pack:
        namespace: harbor  # Required!
    EOT
  }
}
```

### Terraform: Registry Data Sources

```hcl
data "spectrocloud_registry" "public_repo" {
  name = "Public Repo"
}

data "spectrocloud_registry" "palette_community" {
  name = "Palette Community Registry"
}

data "spectrocloud_pack" "hello_universe" {
  name         = "hello-universe"
  version      = "1.3.1"
  registry_uid = data.spectrocloud_registry.palette_community.id
}
```

### Terraform: Provider Project Configuration

**Always set `project_name`** - without it, resources go to the Default project:

```hcl
provider "spectrocloud" {
  project_name = var.project_name  # Required for project-scoped resources!
}
```

### Terraform: Profile Versioning

Same name + different version = separate resources. Use `depends_on` between versions.

---

## BYOOS Pack Values

**Agent Mode**: `options: { system.uri: "NA" }`

**Appliance Mode**: Set `options.system.uri` to provider image URL (e.g., `ttl.sh/my-images:k3s-1.30.5-demo`)

---

## Profile Variables

Use variables for cluster-specific values:
```yaml
cluster-cidr: '{{ .spectro.var.K8sPodCIDR }}'
service-cidr: '{{ .spectro.var.K8sServiceCIDR }}'
```

**Default CIDRs**: Pod `100.64.0.0/18`, Service `100.64.64.0/18`

---

## Import/Export

### Export
```bash
curl -s "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" > profile.json
```

### Import to Another Project
```bash
jq 'del(.metadata.uid, .status, .spec.published) |
    .spec.template = .spec.draft' profile.json | \
curl -s -X POST "https://api.spectrocloud.com/v1/clusterprofiles?publish=true" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $NEW_PROJECT_UID" \
  -H "Content-Type: application/json" -d @-
```

---

## Quick Reference

| Item | Value |
|------|-------|
| Create & Publish | `POST /v1/clusterprofiles?publish=true` |
| Read | `GET /v1/clusterprofiles/{uid}` |
| Delete | `DELETE /v1/clusterprofiles/{uid}` |
| Get Pack Values | `GET /v1/packs/{uid}?includePackValues=true` |
| Required Headers | `ApiKey`, `ProjectUid`, `Content-Type` |

## Links

- [API Docs](https://docs.spectrocloud.com/api/v1/clusterprofiles/)
- [Cluster Profiles](https://docs.spectrocloud.com/profiles/cluster-profiles/)
