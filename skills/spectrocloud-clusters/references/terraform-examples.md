# Terraform Examples for Edge Clusters

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

```hcl
resource "spectrocloud_cluster_edge_native" "two_node" {
  name    = "two-node-cluster"
  context = "project"

  cluster_profile {
    id = data.spectrocloud_cluster_profile.two_node_profile.id
  }

  cloud_config {
    ssh_keys           = [var.ssh_public_key]
    vip                = var.cluster_vip
    ntp_servers        = ["time.google.com"]
    is_two_node_cluster = true  # Enable 2-node HA
  }

  machine_pool {
    name                    = "control-plane-pool"
    control_plane           = true
    control_plane_as_worker = true

    edge_host {
      host_uid                   = data.spectrocloud_appliance.node1.id
      two_node_candidate_priority = "primary"
    }
    edge_host {
      host_uid                   = data.spectrocloud_appliance.node2.id
      two_node_candidate_priority = "secondary"
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
