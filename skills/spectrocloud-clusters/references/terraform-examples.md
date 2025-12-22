# Terraform Examples for Edge Clusters

## Standalone Clusters Module

**Use this structure** so clusters can be managed independently from profiles.
Profiles are referenced via data sources (created in separate `profiles/` module).

```hcl
# clusters/main.tf - Complete standalone cluster module

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
variable "project_name" {}
variable "ssh_public_key" {}
variable "cluster_vip" {}
variable "infra_profile_name" {
  description = "Name of infrastructure profile (created in profiles/ module)"
}

# --- Reference profiles created in separate module ---
data "spectrocloud_cluster_profile" "infra" {
  name    = var.infra_profile_name
  context = "project"
}

# --- Reference registered edge hosts ---
data "spectrocloud_appliance" "node1" {
  name = "edge-node-01"
}

data "spectrocloud_appliance" "node2" {
  name = "edge-node-02"
}

# --- Create cluster ---
resource "spectrocloud_cluster_edge_native" "cluster" {
  name    = "demo-2node-cluster"
  context = "project"

  cluster_profile {
    id = data.spectrocloud_cluster_profile.infra.id
  }

  cloud_config {
    ssh_keys            = [var.ssh_public_key]
    vip                 = var.cluster_vip
    ntp_servers         = ["time.google.com"]
    is_two_node_cluster = true
  }

  machine_pool {
    name                    = "control-plane-pool"
    control_plane           = true
    control_plane_as_worker = true

    edge_host {
      host_uid      = data.spectrocloud_appliance.node1.id
      two_node_role = "primary"
    }
    edge_host {
      host_uid      = data.spectrocloud_appliance.node2.id
      two_node_role = "secondary"
    }
  }
}

output "cluster_id" {
  value = spectrocloud_cluster_edge_native.cluster.id
}
```

**terraform.tfvars:**
```hcl
project_name       = "Default"
infra_profile_name = "demo-edge-infra"  # Must exist (from profiles/ module)
ssh_public_key     = "ssh-rsa AAAA..."
cluster_vip        = "192.168.1.100"
```

**Independent lifecycle:**
```bash
# Destroy cluster only (profiles remain)
cd clusters && terraform destroy

# Recreate cluster
cd clusters && terraform apply

# Update to new profile version
# 1. Update profiles/main.tf with new version
# 2. cd profiles && terraform apply
# 3. cd ../clusters && terraform apply  # Picks up new version
```

---

## Basic Single-Node Cluster

```hcl
resource "spectrocloud_cluster_edge_native" "cluster" {
  name    = "my-edge-cluster"
  context = "project"

  # Infrastructure profile
  cluster_profile {
    id = data.spectrocloud_cluster_profile.infra.id
  }
  # Add-on profile (optional)
  cluster_profile {
    id = data.spectrocloud_cluster_profile.addon.id
  }

  cloud_config {
    ssh_keys    = [var.ssh_public_key]
    vip         = var.cluster_vip
    ntp_servers = ["time.google.com"]
  }

  machine_pool {
    name                    = "control-plane-pool"
    control_plane           = true
    control_plane_as_worker = true

    edge_host {
      host_uid = data.spectrocloud_appliance.edge_host.id
    }
  }
}

data "spectrocloud_cluster_profile" "infra" {
  name    = "my-edge-infra"
  context = "project"
}

data "spectrocloud_cluster_profile" "addon" {
  name    = "my-edge-addon"
  context = "project"
}

data "spectrocloud_appliance" "edge_host" {
  name = "edge-host-01"
}
```

## Overlay Network (instead of VIP)

```hcl
cloud_config {
  ssh_keys       = [var.ssh_public_key]
  ntp_servers    = ["time.google.com"]
  overlay_cidr_range = "100.64.192.0/24"  # Use instead of vip
}
```

## Multi-Node Cluster (3 control plane + workers)

```hcl
machine_pool {
  name          = "control-plane-pool"
  control_plane = true

  edge_host {
    host_uid = data.spectrocloud_appliance.cp1.id
  }
  edge_host {
    host_uid = data.spectrocloud_appliance.cp2.id
  }
  edge_host {
    host_uid = data.spectrocloud_appliance.cp3.id
  }
}

machine_pool {
  name          = "worker-pool"
  control_plane = false

  edge_host {
    host_uid = data.spectrocloud_appliance.worker1.id
  }
  edge_host {
    host_uid = data.spectrocloud_appliance.worker2.id
  }
}
```

## 2-Node HA Cluster

**Note**: API uses `twoNodeCandidatePriority` but Terraform provider >= 0.26.x uses `two_node_role`.
Verify with: `terraform providers schema -json | jq '.provider_schemas[].resource_schemas.spectrocloud_cluster_edge_native'`

```hcl
resource "spectrocloud_cluster_edge_native" "two_node" {
  name    = "two-node-cluster"
  context = "project"

  cluster_profile {
    id = data.spectrocloud_cluster_profile.two_node_profile.id
  }

  cloud_config {
    ssh_keys            = [var.ssh_public_key]
    vip                 = var.cluster_vip
    ntp_servers         = ["time.google.com"]
    is_two_node_cluster = true  # Enable 2-node HA
  }

  machine_pool {
    name                    = "control-plane-pool"
    control_plane           = true
    control_plane_as_worker = true

    edge_host {
      host_uid      = data.spectrocloud_appliance.node1.id
      two_node_role = "primary"    # NOT two_node_candidate_priority
    }
    edge_host {
      host_uid      = data.spectrocloud_appliance.node2.id
      two_node_role = "secondary"  # NOT two_node_candidate_priority
    }
  }
}
```

## Static IP Configuration

```hcl
edge_host {
  host_uid   = data.spectrocloud_appliance.edge_host.id
  static_ip  = "192.168.1.10"
  host_name  = "edge-node-01"
  nic_name   = "eth0"
}
```

## Profile Variables Override

```hcl
cluster_profile {
  id = data.spectrocloud_cluster_profile.edge_profile.id

  pack {
    name   = "edge-k3s"
    tag    = "1.30.5"
    values = <<-EOT
      cluster-cidr: {{ .spectro.var.K8sPodCIDR }}
      service-cidr: {{ .spectro.var.K8sServiceCIDR }}
    EOT
  }
}
```
