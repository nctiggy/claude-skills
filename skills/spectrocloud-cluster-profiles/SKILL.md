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
1. What project UID? (required for API calls)
2. What cloud type? (edge-native, maas, eks, etc.)
3. Profile type? (cluster or add-on)
4. What packs? (If unsure, help discover packs)

---

## Pack Discovery

**Ask user for the pack name.** If unknown, suggest browsing Palette UI or searching below.

### Find Pack by Exact Name (Recommended)
```bash
# Get all versions of a pack by exact name - returns uid and registryUid needed for profiles
curl -s "https://api.spectrocloud.com/v1/packs?filters=metadata.name=hello-universe&limit=50" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq '[.items[] | {name: .metadata.name, version: .spec.version, uid: .metadata.uid,
      registryUid: .spec.registryUid, layer: .spec.layer}] | sort_by(.version) | reverse'
```

### Search Packs by Keyword (When Exact Name Unknown)
```bash
# Search addon packs containing a keyword - fetches 100 at a time, greps locally
KEYWORD="hello"
curl -s "https://api.spectrocloud.com/v1/packs?filters=spec.layer=addon&limit=100" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" | \
  jq --arg kw "$KEYWORD" '[.items[] | select(.metadata.name | ascii_downcase | contains($kw | ascii_downcase)) |
      {name: .metadata.name, version: .spec.version, displayName: .spec.displayName}] | unique_by(.name)'
```

### Common Edge-Native Packs

| Layer | Pack Name | Notes |
|-------|-----------|-------|
| os | `edge-native-byoi` | Agent or appliance mode |
| k8s | `edge-k3s` | K3s (required for 2-node) |
| k8s | `edge-k8s` | Kubeadm |
| cni | `cni-calico` | Calico |
| cni | `cni-cilium-oss` | Cilium |
| addon | `hello-universe` | Demo app |

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

## Quick Reference

| Item | Value |
|------|-------|
| Create & Publish | `POST /v1/clusterprofiles?publish=true` |
| Read | `GET /v1/clusterprofiles/{uid}` |
| Delete | `DELETE /v1/clusterprofiles/{uid}` |
| Required Headers | `ApiKey`, `ProjectUid`, `Content-Type` |
| Pack Fields | `name`, `layer`, `tag`, `uid`, `registryUid`, `type`, `values` |
| Profile Types | `cluster` (infra), `add-on` |

## Links

- [API Docs](https://docs.spectrocloud.com/api/v1/clusterprofiles/)
- [Cluster Profiles](https://docs.spectrocloud.com/profiles/cluster-profiles/)
