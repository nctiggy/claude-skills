# Terraform Examples for Cluster Profiles

## Standalone Profiles Module

**Use this structure** so profiles can be managed independently from clusters.

```hcl
# profiles/main.tf - Complete standalone profile module

terraform {
  required_providers {
    spectrocloud = {
      source  = "spectrocloud/spectrocloud"
      version = ">= 0.26.0"
    }
  }
}

provider "spectrocloud" {
  host         = var.palette_host
  api_key      = var.palette_api_key
  project_name = var.project_name
}

variable "palette_host" {
  default = "api.spectrocloud.com"
}
variable "palette_api_key" {
  sensitive = true
}
variable "project_name" {
  description = "Palette project name"
}

# --- Data Sources ---
data "spectrocloud_registry" "public_repo" {
  name = "Public Repo"
}

data "spectrocloud_pack" "byoos" {
  name         = "edge-native-byoi"
  version      = "2.1.0"
  registry_uid = data.spectrocloud_registry.public_repo.id
}

data "spectrocloud_pack" "k3s" {
  name         = "edge-k3s"
  version      = "1.33.3"
  registry_uid = data.spectrocloud_registry.public_repo.id
}

data "spectrocloud_pack" "calico" {
  name         = "cni-calico"
  version      = "3.28.2"
  registry_uid = data.spectrocloud_registry.public_repo.id
}

# --- Infrastructure Profile ---
resource "spectrocloud_cluster_profile" "edge_infra" {
  name    = "demo-edge-infra"
  type    = "cluster"
  cloud   = "edge-native"
  version = "1.0.0"

  pack {
    name         = data.spectrocloud_pack.byoos.name
    tag          = data.spectrocloud_pack.byoos.version
    uid          = data.spectrocloud_pack.byoos.id
    registry_uid = data.spectrocloud_registry.public_repo.id
    type         = "spectro"
    values       = file("${path.module}/pack-values/byoos.yaml")
  }

  pack {
    name         = data.spectrocloud_pack.k3s.name
    tag          = data.spectrocloud_pack.k3s.version
    uid          = data.spectrocloud_pack.k3s.id
    registry_uid = data.spectrocloud_registry.public_repo.id
    type         = "spectro"
    values       = file("${path.module}/pack-values/k3s.yaml")
  }

  pack {
    name         = data.spectrocloud_pack.calico.name
    tag          = data.spectrocloud_pack.calico.version
    uid          = data.spectrocloud_pack.calico.id
    registry_uid = data.spectrocloud_registry.public_repo.id
    type         = "spectro"
    values       = file("${path.module}/pack-values/calico.yaml")
  }
}

# --- Outputs for clusters module ---
output "infra_profile_id" {
  value = spectrocloud_cluster_profile.edge_infra.id
}

output "infra_profile_name" {
  value = spectrocloud_cluster_profile.edge_infra.name
}
```

**Directory structure:**
```
profiles/
├── main.tf
├── terraform.tfvars
└── pack-values/
    ├── byoos.yaml      # Complete pack values from API
    ├── k3s.yaml
    └── calico.yaml
```

---

## Registry Data Sources

```hcl
data "spectrocloud_registry" "public_repo" {
  name = "Public Repo"
}

data "spectrocloud_registry" "palette_community" {
  name = "Palette Community Registry"
}

data "spectrocloud_registry" "bitnami" {
  name = "Bitnami"
}
```

## Pack Lookup

```hcl
# Standard pack from Public Repo
data "spectrocloud_pack" "calico" {
  name         = "cni-calico"
  version      = "3.28.2"
  registry_uid = data.spectrocloud_registry.public_repo.id
}

# OCI pack from Palette Community Registry
data "spectrocloud_pack" "hello_universe" {
  name         = "hello-universe"
  version      = "1.3.1"
  registry_uid = data.spectrocloud_registry.palette_community.id
}

# Helm chart as pack
data "spectrocloud_pack" "harbor" {
  name         = "harbor"
  version      = "16.3.3"  # Palette's indexed version, not source repo
  registry_uid = data.spectrocloud_registry.bitnami.id
}
```

## Infrastructure Profile

```hcl
resource "spectrocloud_cluster_profile" "edge_infra" {
  name    = "edge-infra"
  type    = "cluster"
  cloud   = "edge-native"
  version = "1.0.0"

  pack {
    name         = "edge-native-byoi"
    tag          = "2.1.0"
    uid          = data.spectrocloud_pack.byoos.id
    registry_uid = data.spectrocloud_registry.public_repo.id
    type         = "spectro"
    values       = <<-EOT
      options:
        system.uri: "NA"
    EOT
  }

  pack {
    name         = "edge-k3s"
    tag          = "1.30.5"
    uid          = data.spectrocloud_pack.k3s.id
    registry_uid = data.spectrocloud_registry.public_repo.id
    type         = "spectro"
    values       = <<-EOT
      cluster:
        config: |
          cluster-cidr: 100.64.0.0/18
          service-cidr: 100.64.64.0/18
    EOT
  }

  pack {
    name         = "cni-calico"
    tag          = "3.28.2"
    uid          = data.spectrocloud_pack.calico.id
    registry_uid = data.spectrocloud_registry.public_repo.id
    type         = "spectro"
  }
}
```

## Add-on Profile

```hcl
resource "spectrocloud_cluster_profile" "apps" {
  name    = "edge-apps"
  type    = "add-on"
  cloud   = "all"
  version = "1.0.0"

  pack {
    name         = data.spectrocloud_pack.hello_universe.name
    tag          = data.spectrocloud_pack.hello_universe.version
    uid          = data.spectrocloud_pack.hello_universe.id
    registry_uid = data.spectrocloud_registry.palette_community.id
    type         = "oci"
  }
}
```

## Manifest Pack

```hcl
resource "spectrocloud_cluster_profile" "manifests" {
  name    = "custom-manifests"
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

## Helm Pack

```hcl
resource "spectrocloud_cluster_profile" "helm_addon" {
  name    = "helm-apps"
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
        namespace: harbor
    EOT
  }
}
```

## Profile Versioning

Same name + different version = separate resources:

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

## Provider Configuration

Always set project_name:

```hcl
provider "spectrocloud" {
  project_name = var.project_name  # Required!
}
```
