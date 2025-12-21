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

## Before Creating Profiles

**Ask the user:**
1. What project name? (use `spectrocloud-common` skill to look up UID)
2. What cloud type? (edge-native, maas, eks, etc.)
3. Profile type? (cluster or add-on)
4. What packs? (use `spectrocloud-common` skill to discover packs)

**Critical workflow for pack values:**
1. Use `spectrocloud-common` skill to fetch **complete** default values for each pack
2. **Keep the entire default values file** - do not summarize or truncate
3. Only modify the specific sections that need customization
4. Include the full values in the profile - missing values cause validation failures

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
# Updates create a NEW profile UID with the same name but different version
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
# Returns new UID - old version still exists
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

**Version sorting**: API returns lexicographic order - "1.9.5" sorts AFTER "1.13.3". For N-1 version:
```bash
jq '[.items[] | select(.metadata.name == "edge-k3s")] |
    sort_by(.spec.version | split(".") | map(tonumber)) | reverse | .[1]'
```

---

## Helper: Get All Pack UIDs for Edge Profile
```bash
# Run this to get pack UIDs needed for profile creation
PROJECT_UID="your-project-uid"

for pack in "edge-native-byoi:os:2.0.0" "edge-k3s:k8s:1.30.5" "cni-calico:cni:3.28.2"; do
  IFS=':' read -r name layer version <<< "$pack"
  echo "=== $name ==="
  curl -s "https://api.spectrocloud.com/v1/packs?filters=spec.layer=$layer&limit=50" \
    -H "ApiKey: $PALETTE_API_KEY" \
    -H "ProjectUid: $PROJECT_UID" | \
    jq -r ".items[] | select(.metadata.name==\"$name\" and .spec.version==\"$version\") |
        \"uid: \" + .metadata.uid + \" registryUid: \" + .spec.registryUid"
done
```

---

## Manifests and Helm Charts

### Pack Types

| Type | API Value | Use Case |
|------|-----------|----------|
| Registry Pack | `spectro` | Infrastructure packs (OS, K8s, CNI) from Public Repo |
| Helm Pack | `helm` | Helm charts (nginx, metallb-helm) - check pack metadata |
| Manifest Pack | `manifest` | Inline Kubernetes YAML manifests |
| OCI Pack | `oci` | Some packs use OCI registries |

**Determining type**: Check the pack's `spec.type` field via API. Common patterns:
- `lb-metallb-helm` → type `helm`
- `nginx` → type `helm`
- `edge-k3s`, `cni-calico` → type `spectro`

### Pack Naming

Pack names aren't always obvious. Common mappings:

| Common Name | Palette Pack Name |
|-------------|-------------------|
| metallb | `lb-metallb-helm` |
| nginx-ingress | `nginx` |
| calico | `cni-calico` |
| cilium | `cni-cilium-oss` |

**Preferred registry**: Use "Public Repo" (`5eecc89d0b150045ae661cef`) when a pack exists in multiple registries.

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

### Terraform: Pack with Auto-Discovery

If a pack isn't found with a specific registry, **omit `registry_uid`**:

```hcl
# Provider auto-discovers the correct registry
data "spectrocloud_pack" "hello_universe" {
  name    = "hello-universe"
  version = "1.2.0"
}
```

### Terraform: Profile Versioning

Same profile name with different versions creates separate resources. Use `depends_on`:

```hcl
resource "spectrocloud_cluster_profile" "v1" {
  name    = "my-profile"
  version = "1.0.0"
  # ... packs
}

resource "spectrocloud_cluster_profile" "v2" {
  name       = "my-profile"
  version    = "2.0.0"
  depends_on = [spectrocloud_cluster_profile.v1]
  # ... updated packs
}
```

---

## BYOOS Pack Values

**Agent Mode** (system.uri = "NA"):
```yaml
options:
  system.uri: "NA"
```

**Appliance Mode** (provider image URL):
```yaml
pack:
  content:
    images:
      - image: '{{.spectro.pack.edge-native-byoi.options.system.uri}}'
options:
  system.uri: "ttl.sh/my-images:k3s-1.30.5-demo"
```

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

## Recommended Workflow

1. Use `spectrocloud-common` skill to look up project UID
2. Use `spectrocloud-common` skill to find packs and fetch default values
3. Create profile via API or Terraform with full values
4. Run `terraform plan` first to catch validation errors

See `spectrocloud-common` skill for troubleshooting common pack/registry issues.

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
