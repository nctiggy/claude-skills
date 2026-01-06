# API Examples for Cluster Profiles

## Create Infrastructure Profile

```bash
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
            "tag": "2.1.0",
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
```

## Create Add-on Profile

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
            "name": "hello-universe",
            "layer": "addon",
            "tag": "1.3.1",
            "uid": "<pack-uid>",
            "registryUid": "<palette-community-registry-uid>",
            "type": "oci",
            "values": "<full-pack-values>"
          }
        ]
      }
    }
  }'
```

## Create Manifest Pack Profile

```bash
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

## Get Profile

```bash
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

## Delete Profile

```bash
curl -s -X DELETE "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID"
# Returns HTTP 204 on success
```

## Add Manifest to Existing Pack

```bash
curl -s -X POST "https://api.spectrocloud.com/v1/clusterprofiles/$PROFILE_UID/packs/$PACK_NAME/manifests" \
  -H "ApiKey: $PALETTE_API_KEY" \
  -H "ProjectUid: $PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "custom-config",
    "content": "apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: my-config\ndata:\n  key: value"
  }'
```

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
