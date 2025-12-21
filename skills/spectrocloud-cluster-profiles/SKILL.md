---
name: spectrocloud-cluster-profiles
description: Create and manage Spectro Cloud Palette cluster profiles via API or Terraform. Covers pack discovery, profile types, versioning, import/export, and cloud-specific configurations.
---

# Spectro Cloud Cluster Profiles

Cluster profiles define the software stack deployed on clusters. This skill covers creating profiles via API (ad-hoc) or Terraform (managed infrastructure).

## Profile Types

| Type | Use Case |
|------|----------|
| **Infrastructure** | OS, K8s, CNI, CSI layers only |
| **Add-on** | Application packs (monitoring, ingress, etc.) |
| **Full** | Complete stack (infra + add-ons) |

**Recommended pattern**: Separate infrastructure profiles from add-on profiles for reusability.

## Pack Layers

| Layer | Examples | Required |
|-------|----------|----------|
| `os` | Ubuntu, RHEL, BYOOS | Yes (infra) |
| `k8s` | kubeadm, k3s, rke2 | Yes (infra) |
| `cni` | Cilium, Calico | Yes (infra) |
| `csi` | Portworx, Longhorn | Optional |
| `addon` | MetalLB, Monitoring | Optional |

## Cloud Types

| Cloud Type | API Value |
|------------|-----------|
| Edge Native | `edge-native` |
| MaaS | `maas` |
| AWS/EKS | `eks` |
| VMware | `vsphere` |
| Azure/AKS | `aks` |

## Before Creating Profiles

**Ask the user:**
1. API-based (ad-hoc) or Terraform-managed?
2. What cloud type?
3. Profile type? (infrastructure, add-on, or full)
4. What packs are needed? (If unsure, list packs by category)

---

## Pack Discovery

### List Packs by Layer
```bash
curl -s "https://api.spectrocloud.com/v1/packs?filters=spec.layer=cni&limit=50" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq '[.items[] | {name: .metadata.name, cloudTypes: .spec.cloudTypes}] | unique_by(.name)'
```

### Edge-Native Pack Names

| Layer | Pack Name | Notes |
|-------|-----------|-------|
| os | `edge-native-byoi` | Use preset for agent vs appliance |
| k8s | `edge-k8s` | Kubeadm for edge |
| k8s | `edge-k3s` | K3s (required for 2-node) |
| cni | `cni-calico` | Calico for edge |
| cni | `cni-cilium-oss` | Cilium for edge |

### BYOOS Pack Presets

| Preset Name | Mode | system.uri |
|-------------|------|------------|
| `byoi-agent-mode` | Agent | `"NA"` |
| `byoi-appliance-mode` | Appliance | Provider image URL |

### Query Pack Presets
```bash
PACK_UID=$(curl -s "https://api.spectrocloud.com/v1/packs?filters=spec.layer=os&limit=30" \
  -H "ApiKey: $PALETTE_API_KEY" -H "ProjectUid: $PROJECT_UID" | \
  jq -r '.items[] | select(.metadata.name=="edge-native-byoi") | .metadata.uid' | head -1)

curl -s "https://api.spectrocloud.com/v1/packs/$PACK_UID" \
  -H "ApiKey: $PALETTE_API_KEY" -H "ProjectUid: $PROJECT_UID" | \
  jq '.packValues[].presets[] | {name: .name, displayName: .displayName}'
```

---

## Profile Variables

Use variables for values that change between clusters:
```yaml
cluster-cidr: '{{ .spectro.var.K8sPodCIDR }}'
service-cidr: '{{ .spectro.var.K8sServiceCIDR }}'
```

**Default CIDRs**: Pod `100.64.0.0/18`, Service `100.64.64.0/18`

---

## API-Based Profile Creation

### Create Edge Infrastructure Profile
```bash
curl -X POST "https://api.spectrocloud.com/v1/clusterprofiles" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {"name": "edge-infra-k3s"},
    "spec": {
      "type": "cluster",
      "cloudType": "edge-native",
      "version": "1.0.0",
      "packs": [
        {"name": "edge-native-byoi", "layer": "os", "tag": "2.0.0",
         "values": "options:\n  system.uri: \"NA\""},
        {"name": "edge-k3s", "layer": "k8s", "tag": "1.30.5",
         "values": "cluster:\n  config: |\n    cluster-cidr: \"100.64.0.0/18\"\n    service-cidr: \"100.64.64.0/18\""},
        {"name": "cni-calico", "layer": "cni", "tag": "3.28.2", "values": ""}
      ]
    }
  }'
```

### Create Add-on Profile
```bash
curl -X POST "https://api.spectrocloud.com/v1/clusterprofiles" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {"name": "addon-monitoring"},
    "spec": {
      "type": "add-on",
      "version": "1.0.0",
      "packs": [
        {"name": "prometheus-operator", "layer": "addon", "tag": "65.0.0", "values": ""}
      ]
    }
  }'
```

### BYOOS Values

**Agent Mode**: `options:\n  system.uri: "NA"`

**Appliance Mode**:
```yaml
pack:
  content:
    images:
      - image: '{{.spectro.pack.edge-native-byoi.options.system.uri}}'
options:
  system.uri: "ttl.sh/my-edge-images:k3s-1.30.5-demo"
```

---

## Terraform-Based Profile Management

### Repository Structure
```
customer-palette-profiles/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── profiles/
│   │   ├── infra-edge.tf
│   │   └── addon-*.tf
│   └── values/
│       └── edge-k3s.yaml
```

### Provider Configuration
```hcl
terraform {
  required_providers {
    spectrocloud = {
      source  = "spectrocloud/spectrocloud"
      version = ">= 0.21.0"
    }
  }
}

provider "spectrocloud" {
  project_name = var.project_name
}

data "spectrocloud_registry" "public" {
  name = "Public Repo"
}
```

### Edge Infrastructure Profile
```hcl
data "spectrocloud_pack" "byoos" {
  name         = "edge-native-byoi"
  version      = "2.0.0"
  registry_uid = data.spectrocloud_registry.public.id
}

data "spectrocloud_pack" "k3s" {
  name         = "edge-k3s"
  version      = "1.30.5"
  registry_uid = data.spectrocloud_registry.public.id
}

data "spectrocloud_pack" "calico" {
  name         = "cni-calico"
  version      = "3.28.2"
  registry_uid = data.spectrocloud_registry.public.id
}

resource "spectrocloud_cluster_profile" "edge_infra" {
  name    = "edge-infra-k3s"
  type    = "cluster"
  cloud   = "edge-native"
  version = var.profile_version

  pack {
    name         = data.spectrocloud_pack.byoos.name
    tag          = data.spectrocloud_pack.byoos.version
    registry_uid = data.spectrocloud_registry.public.id
    type         = "spectro"
    values       = "options:\n  system.uri: \"NA\""
  }

  pack {
    name         = data.spectrocloud_pack.k3s.name
    tag          = data.spectrocloud_pack.k3s.version
    registry_uid = data.spectrocloud_registry.public.id
    type         = "spectro"
    values       = file("${path.module}/values/edge-k3s.yaml")
  }

  pack {
    name         = data.spectrocloud_pack.calico.name
    tag          = data.spectrocloud_pack.calico.version
    registry_uid = data.spectrocloud_registry.public.id
    type         = "spectro"
    values       = ""
  }
}
```

### K3s Values File
```yaml
# values/edge-k3s.yaml
cluster:
  config: |
    flannel-backend: none
    disable-network-policy: true
    disable: [traefik, local-storage, servicelb]
    cluster-cidr: "100.64.0.0/18"
    service-cidr: "100.64.64.0/18"
```

### Version Strategy
- **Patch** (1.0.1): Config tweaks
- **Minor** (1.1.0): Pack version updates
- **Major** (2.0.0): Breaking changes

---

## Import/Export Profiles

### Export Profile
```bash
PROFILE_UID=$(curl -s "https://api.spectrocloud.com/v1/clusterprofiles?name=my-profile" \
  -H "ApiKey: $PALETTE_API_KEY" -H "ProjectUid: $PROJECT_UID" | jq -r '.items[0].metadata.uid')

curl -s "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $PALETTE_API_KEY" -H "ProjectUid: $PROJECT_UID" > profile-export.json
```

### Import Profile
```bash
jq 'del(.metadata.uid, .status, .spec.published)' profile-export.json > profile-import.json

curl -X POST "https://api.spectrocloud.com/v1/clusterprofiles" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $NEW_PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d @profile-import.json
```

### Clone Between Projects
```bash
#!/bin/bash
SOURCE_PROJECT=$1; TARGET_PROJECT=$2; PROFILE_NAME=$3

PROFILE_UID=$(curl -s "https://api.spectrocloud.com/v1/clusterprofiles?name=$PROFILE_NAME" \
  -H "ApiKey: $PALETTE_API_KEY" -H "ProjectUid: $SOURCE_PROJECT" | jq -r '.items[0].metadata.uid')

curl -s "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $PALETTE_API_KEY" -H "ProjectUid: $SOURCE_PROJECT" | \
  jq 'del(.metadata.uid, .status, .spec.published)' | \
  curl -X POST "https://api.spectrocloud.com/v1/clusterprofiles" \
    -H "ApiKey: $PALETTE_API_KEY" -H "ProjectUid: $TARGET_PROJECT" \
    -H "Content-Type: application/json" -d @-
```

---

## Quick Reference

| Item | Value |
|------|-------|
| API Endpoint | `https://api.spectrocloud.com/v1/clusterprofiles` |
| Terraform Provider | `spectrocloud/spectrocloud` |
| Default Pod CIDR | `100.64.0.0/18` |
| Default Service CIDR | `100.64.64.0/18` |
| BYOOS Pack | `edge-native-byoi` |
| Agent Mode Preset | `byoi-agent-mode` |
| Appliance Mode Preset | `byoi-appliance-mode` |
| Variable Syntax | `{{ .spectro.var.VarName }}` |

## Links

- [Cluster Profiles Overview](https://docs.spectrocloud.com/profiles/cluster-profiles/)
- [Create Cluster Profiles](https://docs.spectrocloud.com/profiles/cluster-profiles/create-cluster-profiles/)
- [Terraform Provider](https://registry.terraform.io/providers/spectrocloud/spectrocloud/latest/docs)
