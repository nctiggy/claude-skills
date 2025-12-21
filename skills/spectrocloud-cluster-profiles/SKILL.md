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

Profiles are built from packs organized in layers:

| Layer | Examples | Required |
|-------|----------|----------|
| `os` | Ubuntu, RHEL, BYOOS | Yes (infra) |
| `k8s` | kubeadm, k3s, rke2 | Yes (infra) |
| `cni` | Cilium, Calico, Flannel | Yes (infra) |
| `csi` | Local Path, Portworx, Longhorn | Optional |
| `addon` | MetalLB, Ingress, Monitoring | Optional |

## Cloud Types

| Cloud Type | API Value | Notes |
|------------|-----------|-------|
| Edge Native | `edge-native` | Uses BYOOS pack |
| MaaS | `maas` | Bare metal via MaaS |
| AWS/EKS | `eks` | Managed K8s |
| VMware | `vsphere` | vSphere integration |
| Azure/AKS | `aks` | Managed K8s |

## Before Creating Profiles

**Ask the user:**
1. API-based (ad-hoc) or Terraform-managed?
2. What cloud type? (edge-native, maas, eks, etc.)
3. Profile type? (infrastructure, add-on, or full)
4. What packs are needed? (If unsure, offer to list packs by category)

## Pack Discovery

### List Packs by Layer/Category

```bash
# Get packs for a specific layer (use filters= syntax)
curl -s "https://api.spectrocloud.com/v1/packs?filters=spec.layer=cni&limit=50" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | jq '[.items[] | {name: .metadata.name, cloudTypes: .spec.cloudTypes}] | unique_by(.name)'

# Common layers: os, k8s, cni, csi, addon
```

### Edge-Native Pack Names

| Layer | Pack Name | Notes |
|-------|-----------|-------|
| os | `edge-native-byoi` | Use preset for agent vs appliance mode |
| k8s | `edge-k8s` | Kubeadm for edge |
| k8s | `edge-k3s` | K3s for edge (required for 2-node) |
| k8s | `edge-canonical` | MicroK8s from Canonical |
| cni | `cni-calico` | Calico for edge-native |
| cni | `cni-cilium-oss` | Cilium OSS for edge-native |
| cni | `cni-cilium-canonical` | Cilium via Canonical for edge-native |

### BYOOS Pack Presets

The `edge-native-byoi` pack uses presets to switch between deployment modes:

| Preset Name | Display Name | system.uri Value |
|-------------|--------------|------------------|
| `byoi-agent-mode` | Agent Mode | `"NA"` |
| `byoi-appliance-mode` | Appliance Mode | Provider image URL |

### Query Pack Presets via API

```bash
# Get pack UID first
PACK_UID=$(curl -s "https://api.spectrocloud.com/v1/packs?filters=spec.layer=os&limit=30" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq -r '.items[] | select(.metadata.name=="edge-native-byoi") | .metadata.uid' | head -1)

# Get pack with presets
curl -s "https://api.spectrocloud.com/v1/packs/$PACK_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq '.packValues[].presets[] | {name: .name, displayName: .displayName, group: .group}'
```

### Get Pack Values from Existing Profile

```bash
# Get pack values from a profile (best way to get defaults)
PROFILE_UID="your-profile-uid"
curl -s "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | jq '.spec.published.packs[] | {name: .name, layer: .layer, tag: .tag}'
```

### Find Packs Supporting a Cloud Type

```bash
# Find packs that support edge-native
curl -s "https://api.spectrocloud.com/v1/packs?filters=spec.layer=k8s&limit=50" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq '[.items[] | select(.spec.cloudTypes | contains(["edge-native"])) | .metadata.name] | unique'
```

## Profile Variables

Use variables for values that change between clusters:

```yaml
# In pack values
networking:
  podSubnet: '{{ .spectro.var.K8sPodCIDR }}'
  serviceSubnet: '{{ .spectro.var.K8sServiceCIDR }}'
```

**Default CIDR values** (set at cluster deployment):
- Pod CIDR: `100.64.0.0/18`
- Service CIDR: `100.64.64.0/18`

Variables are defined in the profile and populated when deploying a cluster.

---

## API-Based Profile Creation

Use API for quick, ad-hoc profile creation.

### Create Infrastructure Profile

```bash
curl -X POST "https://api.spectrocloud.com/v1/clusterprofiles" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {
      "name": "edge-infra-k3s"
    },
    "spec": {
      "type": "cluster",
      "cloudType": "edge-native",
      "version": "1.0.0",
      "packs": [
        {
          "name": "edge-native-byoi",
          "layer": "os",
          "tag": "2.0.0",
          "values": "options:\n  system.uri: \"NA\""
        },
        {
          "name": "edge-k3s",
          "layer": "k8s",
          "tag": "1.30.5",
          "values": "cluster:\n  config: |\n    cluster-cidr: \"100.64.0.0/18\"\n    service-cidr: \"100.64.64.0/18\""
        },
        {
          "name": "cni-calico",
          "layer": "cni",
          "tag": "3.28.2",
          "values": ""
        }
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
    "metadata": {
      "name": "addon-monitoring"
    },
    "spec": {
      "type": "add-on",
      "version": "1.0.0",
      "packs": [
        {
          "name": "prometheus-operator",
          "layer": "addon",
          "tag": "65.0.0",
          "values": ""
        }
      ]
    }
  }'
```

### Edge-Specific: BYOOS Pack Values

Both modes use `edge-native-byoi` pack with different presets:

**Agent Mode** (preset: `byoi-agent-mode`):
```yaml
options:
  system.uri: "NA"
```

**Appliance Mode** (preset: `byoi-appliance-mode`):
```yaml
pack:
  content:
    images:
      - image: '{{.spectro.pack.edge-native-byoi.options.system.uri}}'
options:
  system.uri: "ttl.sh/my-edge-images:k3s-1.30.5-demo"
```

The `system.uri` points to the provider image built with CanvOS. The preset auto-configures the pack structure.

---

## Terraform-Based Profile Management

Use Terraform for version-controlled, reproducible profile management.

### Recommended Repository Structure

```
customer-palette-profiles/
├── terraform/
│   ├── main.tf              # Provider config, data sources
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Profile UIDs for reference
│   ├── profiles/
│   │   ├── infra-edge.tf    # Edge infrastructure profile
│   │   ├── infra-maas.tf    # MaaS infrastructure profile
│   │   └── addon-*.tf       # Add-on profiles
│   └── values/
│       ├── edge-k8s.yaml    # K8s pack values
│       ├── cilium.yaml      # CNI values
│       └── prometheus.yaml  # Monitoring values
└── README.md
```

### Provider Configuration

```hcl
# main.tf
terraform {
  required_providers {
    spectrocloud = {
      source  = "spectrocloud/spectrocloud"
      version = ">= 0.21.0"
    }
  }
}

provider "spectrocloud" {
  # Credentials from environment:
  # SPECTROCLOUD_APIKEY
  # SPECTROCLOUD_HOST (default: api.spectrocloud.com)
  project_name = var.project_name
}

# Get pack registry
data "spectrocloud_registry" "public" {
  name = "Public Repo"
}
```

### Variables

```hcl
# variables.tf
variable "project_name" {
  description = "Palette project name"
  type        = string
}

variable "pod_cidr" {
  description = "Pod network CIDR"
  type        = string
  default     = "100.64.0.0/18"
}

variable "service_cidr" {
  description = "Service network CIDR"
  type        = string
  default     = "100.64.64.0/18"
}

variable "profile_version" {
  description = "Semver version for profiles"
  type        = string
  default     = "1.0.0"
}
```

### Infrastructure Profile

```hcl
# profiles/infra-edge.tf

# Get pack data
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
  name        = "edge-infra-k3s"
  description = "Edge infrastructure profile with K3s"
  type        = "cluster"
  cloud       = "edge-native"
  version     = var.profile_version

  pack {
    name         = data.spectrocloud_pack.byoos.name
    tag          = data.spectrocloud_pack.byoos.version
    registry_uid = data.spectrocloud_registry.public.id
    type         = "spectro"
    values       = <<-EOT
      options:
        system.uri: "NA"
    EOT
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
    values       = file("${path.module}/values/calico.yaml")
  }
}
```

### Pack Values Files

```yaml
# values/edge-k3s.yaml
cluster:
  config: |
    flannel-backend: none
    disable-network-policy: true
    disable:
      - traefik
      - local-storage
      - servicelb
    cluster-cidr: "100.64.0.0/18"
    service-cidr: "100.64.64.0/18"
    write-kubeconfig: /run/kubeconfig
    write-kubeconfig-mode: 600
```

```yaml
# values/calico.yaml
pack:
  namespace: kube-system

manifests:
  calico:
    env:
      - name: CALICO_IPV4POOL_CIDR
        value: "100.64.0.0/18"
```

### Add-on Profile

```hcl
# profiles/addon-monitoring.tf

data "spectrocloud_pack" "prometheus" {
  name         = "prometheus-operator"
  version      = "65.0.0"
  registry_uid = data.spectrocloud_registry.public.id
}

resource "spectrocloud_cluster_profile" "monitoring" {
  name        = "addon-monitoring"
  description = "Prometheus + Grafana monitoring stack"
  type        = "add-on"
  version     = var.profile_version

  pack {
    name         = data.spectrocloud_pack.prometheus.name
    tag          = data.spectrocloud_pack.prometheus.version
    registry_uid = data.spectrocloud_registry.public.id
    type         = "spectro"
    values       = file("${path.module}/values/prometheus.yaml")
  }
}
```

### Profile Versioning Workflow

When updating profiles:

1. **Increment version** in `variables.tf`:
   ```hcl
   variable "profile_version" {
     default = "1.1.0"  # Bumped from 1.0.0
   }
   ```

2. **Apply changes**:
   ```bash
   terraform plan
   terraform apply
   ```

3. **New version created** - existing clusters stay on old version until updated

Version strategy:
- **Patch** (1.0.1): Config tweaks, value changes
- **Minor** (1.1.0): Pack version updates, new optional packs
- **Major** (2.0.0): Breaking changes, K8s major version bump

---

## Import/Export Profiles

### Export Profile to JSON

```bash
# Get profile by UID
curl -s "https://api.spectrocloud.com/v1/clusterprofiles/{profile-uid}" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" > profile-export.json

# Get profile by name
PROFILE_UID=$(curl -s "https://api.spectrocloud.com/v1/clusterprofiles?name=edge-infra-kubeadm" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | jq -r '.items[0].metadata.uid')

curl -s "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" > profile-export.json
```

### Import Profile from JSON

```bash
# Clean up export for import (remove UIDs, status, etc.)
jq 'del(.metadata.uid, .status, .spec.published)' profile-export.json > profile-import.json

# Create in new project
curl -X POST "https://api.spectrocloud.com/v1/clusterprofiles" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $NEW_PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d @profile-import.json
```

### Clone Profile Between Projects

```bash
#!/bin/bash
# clone-profile.sh

SOURCE_PROJECT=$1
TARGET_PROJECT=$2
PROFILE_NAME=$3

# Export from source
PROFILE_UID=$(curl -s "https://api.spectrocloud.com/v1/clusterprofiles?name=$PROFILE_NAME" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $SOURCE_PROJECT" | jq -r '.items[0].metadata.uid')

curl -s "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $SOURCE_PROJECT" | \
  jq 'del(.metadata.uid, .status, .spec.published)' > /tmp/profile-clone.json

# Import to target
curl -X POST "https://api.spectrocloud.com/v1/clusterprofiles" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $TARGET_PROJECT" \
  -H "Content-Type: application/json" \
  -d @/tmp/profile-clone.json

echo "Cloned $PROFILE_NAME from $SOURCE_PROJECT to $TARGET_PROJECT"
```

---

## Cloud-Specific Examples

### MaaS Infrastructure Profile

```hcl
resource "spectrocloud_cluster_profile" "maas_infra" {
  name    = "maas-infra-kubeadm"
  type    = "cluster"
  cloud   = "maas"
  version = var.profile_version

  pack {
    name   = "ubuntu-maas"
    tag    = "22.04"
    values = ""
  }

  pack {
    name   = "kubernetes"
    tag    = "1.30.4"
    values = file("${path.module}/values/maas-k8s.yaml")
  }

  pack {
    name   = "cni-cilium"
    tag    = "1.16.0"
    values = file("${path.module}/values/cilium.yaml")
  }
}
```

### EKS Managed Profile

```hcl
resource "spectrocloud_cluster_profile" "eks_infra" {
  name    = "eks-infra"
  type    = "cluster"
  cloud   = "eks"
  version = var.profile_version

  pack {
    name   = "amazon-linux-eks"
    tag    = "2"
    values = ""
  }

  pack {
    name   = "kubernetes-eks"
    tag    = "1.30"
    values = ""
  }

  pack {
    name   = "cni-aws-vpc-eks"
    tag    = "1.18.0"
    values = ""
  }
}
```

---

## Troubleshooting

### Pack not found
```bash
# Verify pack exists and get exact name/version
curl -s "https://api.spectrocloud.com/v1/packs?search=kubernetes" \
  -H "ApiKey: $PALETTE_API_KEY" | jq '.items[] | {name: .metadata.name, versions: .spec.versions}'
```

### Profile creation fails
- Check all required layers are present (os, k8s, cni for infrastructure)
- Verify pack versions are compatible
- Ensure cloud type matches pack requirements

### Variable not resolving
- Variables use mustache syntax: `{{ .spectro.var.VarName }}`
- Define variables in profile or set at cluster deployment
- Check for typos in variable names

### Terraform state drift
```bash
# Refresh state to match Palette
terraform refresh

# Import existing profile
terraform import spectrocloud_cluster_profile.edge_infra {profile-uid}
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
| Agent Mode Preset | `byoi-agent-mode` (`system.uri: "NA"`) |
| Appliance Mode Preset | `byoi-appliance-mode` (provider image URL) |
| Profile Variable Syntax | `{{ .spectro.var.VarName }}` |

## Links

- [Cluster Profiles Overview](https://docs.spectrocloud.com/profiles/cluster-profiles/)
- [Create Cluster Profiles](https://docs.spectrocloud.com/profiles/cluster-profiles/create-cluster-profiles/)
- [Terraform Provider Docs](https://registry.terraform.io/providers/spectrocloud/spectrocloud/latest/docs)
- [Pack Management](https://docs.spectrocloud.com/registries-and-packs/)
