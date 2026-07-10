# Cross-Tenant Profile Cloning

Clone profiles between different Palette tenants. Pack UIDs and registry UIDs differ between tenants, so a simple export/import won't work - you must resolve pack references in the destination tenant.

## Prerequisites

Set up environment variables for both tenants:
```bash
# Source tenant
export SRC_API_KEY="<source-tenant-api-key>"
export SRC_PROJECT_UID="<source-project-uid>"
export SRC_HOST="api.spectrocloud.com"
# Destination tenant
export DST_API_KEY="<destination-tenant-api-key>"
export DST_PROJECT_UID="<destination-project-uid>"
export DST_HOST="api.spectrocloud.com"
# Profile to clone
export PROFILE_UID="<profile-uid-to-clone>"
```

## Step 1: Export Profile from Source Tenant

```bash
curl -s "https://$SRC_HOST/v1/clusterprofiles/$PROFILE_UID" \
  -H "ApiKey: $SRC_API_KEY" \
  -H "ProjectUid: $SRC_PROJECT_UID" > profile-export.json

# Verify export
jq '{name: .metadata.name, version: .spec.version, packs: [.spec.published.packs[] | {name, tag, layer}]}' profile-export.json
```

## Step 2: Extract Pack References

```bash
# List packs that need resolution in destination tenant
jq -r '.spec.published.packs[] | "\(.name):\(.tag)"' profile-export.json
```

## Step 3: Resolve Packs in Destination Tenant

For **each pack** from Step 2, resolve its UID in the destination tenant:

```bash
# Resolve a single pack (repeat for each pack)
PACK_NAME="edge-k3s"
PACK_VERSION="1.32.9"

RESOLVED=$((for OFFSET in 0 50 100 150; do
  curl -s "https://$DST_HOST/v1/packs?filters=metadata.name=$PACK_NAME&limit=50&offset=$OFFSET" \
    -H "ApiKey: $DST_API_KEY" | jq '.items[]'
done) | jq -s --arg ver "$PACK_VERSION" '
  [.[] | select(.status.disabled != true and .spec.version == $ver)] | .[0] |
  {uid: .metadata.uid, registryUid: .spec.registryUid, type: .spec.type}')

echo "$PACK_NAME:$PACK_VERSION -> $RESOLVED"
# Build pack-mappings.json: { "pack-name:version": { "uid": "...", "registryUid": "...", "type": "..." }, ... }
```

## Step 4: Transform Profile JSON

Replace source tenant UIDs with destination tenant UIDs:

```bash
# Transform profile with resolved pack mappings
jq --slurpfile mappings pack-mappings.json '
  # Remove source-specific fields
  del(.metadata.uid, .status, .spec.published) |

  # Use draft as template
  .spec.template = .spec.draft |
  del(.spec.draft) |

  # Update each pack with destination UIDs
  .spec.template.packs = [.spec.template.packs[] |
    . as $pack |
    ($mappings[0]["\($pack.name):\($pack.tag)"] // null) as $resolved |
    if $resolved then
      .uid = $resolved.uid |
      .registryUid = $resolved.registryUid
    else . end
  ]
' profile-export.json > profile-import.json
```

## Step 5: Import to Destination Tenant

```bash
curl -s -X POST "https://$DST_HOST/v1/clusterprofiles?publish=true" \
  -H "ApiKey: $DST_API_KEY" \
  -H "ProjectUid: $DST_PROJECT_UID" \
  -H "Content-Type: application/json" \
  -d @profile-import.json | jq '{uid: .uid, name: .metadata.name}'
```

## Validation Checklist

Before importing, verify:
- [ ] All packs exist in destination tenant (Step 3 resolved all packs)
- [ ] Pack versions match exactly (or update to available versions)
- [ ] BYOOS `system.uri` updated if it references tenant-specific registry URLs (check with `jq '.spec.template.packs[] | select(.name == "edge-native-byoi") | .values' profile-import.json`)
