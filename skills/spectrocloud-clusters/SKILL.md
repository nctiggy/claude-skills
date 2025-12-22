---
name: spectrocloud-clusters
description: Create and manage Spectro Cloud Palette Edge clusters. Covers edge-native deployments including agent mode, appliance mode, and 2-node HA. Both API and Terraform.
---

# Spectro Cloud Edge Clusters

Deploy and manage Kubernetes clusters on edge infrastructure using Palette.

## Before Creating Clusters

**Ask the user:**
1. Project name? (use `spectrocloud-common` skill to look up UID)
2. Cluster name?
3. Infrastructure profile? (must exist - use `spectrocloud-cluster-profiles` skill)
4. Add-on profile(s)? (optional - applications to deploy)
5. Edge host UIDs? (must be registered in Palette)
6. Deployment mode? (agent mode, appliance mode, or 2-node HA)
7. Network mode?
   - **VIP** (default): Requires a static IP address for the virtual IP
   - **Overlay**: Uses `overlayNetworkConfiguration` instead of VIP
8. If VIP: What IP address?
9. SSH public key(s)? (for node access)
10. NTP server(s)? (e.g., `time.google.com`, `pool.ntp.org`)

**Best Practice**: Use separate infrastructure + add-on profiles rather than one combined profile. This allows reusing infra across clusters.

**Prerequisites:**
- Edge hosts registered in Palette
- Infrastructure profile with OS, K8s, CNI layers
- Add-on profile(s) for applications (optional)
- VIP address OR overlay network configured
- NTP servers for time sync (critical for multi-node)

---

## Edge Deployment Modes

| Mode | Nodes | Profile BYOOS | Use Case |
|------|-------|---------------|----------|
| Agent Mode | 1 or 3+ | `system.uri: "NA"` | Install on existing OS |
| Appliance Mode | 1 or 3+ | Provider image URL | Immutable edge |
| 2-Node HA | Exactly 2 | Provider image URL + K3s | High availability |

**2-Node Requirements:**
- K3s distribution only (not kubeadm)
- Appliance mode only (not agent mode)
- Built with `TWO_NODE=true` in CanvOS

---

## API: Create Edge-Native Cluster

```bash
curl -s -X POST "https://api.spectrocloud.com/v1/spectroclusters/edge-native?ProjectUid=$PROJECT_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {
      "name": "my-edge-cluster",
      "labels": {"env": "demo"}
    },
    "spec": {
      "cloudType": "edge-native",
      "profiles": [
        {"uid": "<infra-profile-uid>"},
        {"uid": "<addon-profile-uid>"}
      ],
      "cloudConfig": {
        "sshKeys": ["ssh-rsa AAAA..."],
        "vip": "192.168.1.100",
        "ntpServers": ["time.google.com"]
      },
      "machinePools": [
        {
          "name": "control-plane-pool",
          "size": 1,
          "controlPlane": true,
          "controlPlaneAsWorker": true,
          "edgeHosts": [
            {"hostUid": "<edge-host-uid>"}
          ]
        }
      ]
    }
  }'
# Returns: {"uid": "cluster-uid"}
```

### Overlay Network (instead of VIP)
```bash
# Use overlayNetworkConfiguration instead of vip for overlay mode
"cloudConfig": {
  "sshKeys": ["ssh-rsa AAAA..."],
  "ntpServers": ["time.google.com"],
  "overlayNetworkConfiguration": {
    "enable": true
  }
}
```

### Multi-Node Cluster (3 control plane + workers)
```bash
"machinePools": [
  {
    "name": "control-plane-pool",
    "size": 3,
    "controlPlane": true,
    "controlPlaneAsWorker": false,
    "edgeHosts": [
      {"hostUid": "<cp1-uid>"},
      {"hostUid": "<cp2-uid>"},
      {"hostUid": "<cp3-uid>"}
    ]
  },
  {
    "name": "worker-pool",
    "size": 2,
    "controlPlane": false,
    "edgeHosts": [
      {"hostUid": "<worker1-uid>"},
      {"hostUid": "<worker2-uid>"}
    ]
  }
]
```

### 2-Node HA Cluster
```bash
# Key 2-node fields:
# - isTwoNodeCluster: true in cloudConfig
# - twoNodeCandidatePriority: "primary"/"secondary" per edge host
# - useControlPlaneAsWorker: true in poolConfig
"spec": {
  "cloudType": "edge-native",
  "profiles": [{"uid": "<2node-profile-uid>"}],
  "cloudConfig": {
    "sshKeys": ["ssh-rsa AAAA..."],
    "vip": "192.168.1.100",
    "ntpServers": ["time.google.com"],
    "isTwoNodeCluster": true
  },
  "machinePools": [
    {
      "name": "control-plane-pool",
      "size": 2,
      "controlPlane": true,
      "poolConfig": {
        "useControlPlaneAsWorker": true
      },
      "edgeHosts": [
        {"hostUid": "<node1-uid>", "twoNodeCandidatePriority": "primary"},
        {"hostUid": "<node2-uid>", "twoNodeCandidatePriority": "secondary"}
      ]
    }
  ]
}
```

---

## API: Get Cluster

```bash
curl -s "https://api.spectrocloud.com/v1/spectroclusters/$CLUSTER_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | jq '{
    name: .metadata.name,
    uid: .metadata.uid,
    status: .status.state,
    health: .status.health
  }'
```

## API: Get Kubeconfig

```bash
curl -s "https://api.spectrocloud.com/v1/spectroclusters/$CLUSTER_UID/assets/kubeconfig" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" > kubeconfig.yaml
```

## API: Delete Cluster

```bash
curl -s -X DELETE "https://api.spectrocloud.com/v1/spectroclusters/$CLUSTER_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID"
# Returns HTTP 204 on success
```

---

## API: List Edge Hosts

```bash
curl -s "https://api.spectrocloud.com/v1/edgehosts" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid, state: .status.state}]'
```

---

## Terraform: Edge-Native Cluster

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
    vip         = var.cluster_vip  # OR use overlay_cidr_range
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

### Terraform: Overlay Network (instead of VIP)
```hcl
cloud_config {
  ssh_keys       = [var.ssh_public_key]
  ntp_servers    = ["time.google.com"]
  overlay_cidr_range = "100.64.192.0/24"  # Use instead of vip
}
```

### Terraform: Multi-Node Cluster

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
}
```

### Terraform: 2-Node HA

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

### Terraform: Static IP Configuration

```hcl
edge_host {
  host_uid   = data.spectrocloud_appliance.edge_host.id
  static_ip  = "192.168.1.10"
  host_name  = "edge-node-01"
  nic_name   = "eth0"
}
```

---

## Profile Variables

If the cluster profile has variables, provide values at cluster creation:

**API:**
```json
"profiles": [
  {
    "uid": "<profile-uid>",
    "variables": [
      {"name": "K8sPodCIDR", "value": "10.244.0.0/16"},
      {"name": "K8sServiceCIDR", "value": "10.96.0.0/12"}
    ]
  }
]
```

**Terraform:**
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

---

## Cluster Lifecycle

### Update Cluster Profile
```bash
curl -s -X PUT "https://api.spectrocloud.com/v1/spectroclusters/$CLUSTER_UID/profiles" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{"profiles": [{"uid": "<new-profile-uid>"}]}'
```

### Add Edge Host to Existing Cluster
```bash
# PATCH machine pool to add host
curl -s -X PATCH "https://api.spectrocloud.com/v1/spectroclusters/$CLUSTER_UID/machinePools/worker-pool" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{"edgeHosts": [{"hostUid": "<new-host-uid>"}]}'
```

---

## Quick Reference

| Operation | Endpoint |
|-----------|----------|
| Create Cluster | `POST /v1/spectroclusters/edge-native` |
| Get Cluster | `GET /v1/spectroclusters/{uid}` |
| Delete Cluster | `DELETE /v1/spectroclusters/{uid}` |
| Get Kubeconfig | `GET /v1/spectroclusters/{uid}/assets/kubeconfig` |
| List Edge Hosts | `GET /v1/edgehosts` |
| Update Profile | `PUT /v1/spectroclusters/{uid}/profiles` |

## Links

- [Edge Clusters](https://docs.spectrocloud.com/clusters/edge/)
- [Site Deployment](https://docs.spectrocloud.com/clusters/edge/site-deployment/)
- [Terraform Provider](https://registry.terraform.io/providers/spectrocloud/spectrocloud/latest/docs)
- [API Reference](https://docs.spectrocloud.com/api/v1/spectroclusters/)
