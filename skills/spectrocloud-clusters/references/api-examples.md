# API Examples for Edge Clusters

## Create Single-Node Cluster

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

## Overlay Network (instead of VIP)

```bash
"cloudConfig": {
  "sshKeys": ["ssh-rsa AAAA..."],
  "ntpServers": ["time.google.com"],
  "overlayNetworkConfiguration": {
    "enable": true
  }
}
```

## Multi-Node Cluster (3 control plane + workers)

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

## 2-Node HA Cluster

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

## Get Cluster

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

## Get Kubeconfig

```bash
curl -s "https://api.spectrocloud.com/v1/spectroclusters/$CLUSTER_UID/assets/kubeconfig" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" > kubeconfig.yaml
```

## Delete Cluster

```bash
curl -s -X DELETE "https://api.spectrocloud.com/v1/spectroclusters/$CLUSTER_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID"
# Returns HTTP 204 on success
```

## List Edge Hosts

```bash
curl -s "https://api.spectrocloud.com/v1/edgehosts" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq '[.items[] | {name: .metadata.name, uid: .metadata.uid, state: .status.state}]'
```

## Update Cluster Profile

```bash
# Use the NEW profile version's UID
curl -s -X PUT "https://api.spectrocloud.com/v1/spectroclusters/$CLUSTER_UID/profiles" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{"profiles": [{"uid": "<new-profile-version-uid>"}]}'
```

## Add Edge Host to Existing Cluster

```bash
curl -s -X PATCH "https://api.spectrocloud.com/v1/spectroclusters/$CLUSTER_UID/machinePools/worker-pool" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{"edgeHosts": [{"hostUid": "<new-host-uid>"}]}'
```

## Profile Variables at Cluster Creation

```json
"profiles": [
  {
    "uid": "<profile-uid>",
    "variables": [
      {"name": "K8sPodCIDR", "value": "100.64.0.0/18"},
      {"name": "K8sServiceCIDR", "value": "100.64.64.0/18"}
    ]
  }
]
```
