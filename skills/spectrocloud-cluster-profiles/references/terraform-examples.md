# Terraform Examples for Cluster Profiles

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
    tag          = "2.0.0"
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
