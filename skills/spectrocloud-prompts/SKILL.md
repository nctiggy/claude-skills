---
name: spectrocloud-prompts
description: Generate tested prompts for SpectroCloud Palette tasks. Ensures Claude uses the right skills and avoids common pitfalls.
---

# SpectroCloud Prompt Generator

Generate prompts that enforce skill usage and bake in critical learnings.

## Why This Skill Exists

Claude often:
- Ignores available skills and reinvents solutions
- Hits known issues (like pack pagination) repeatedly
- Doesn't know which skill covers which topic

**Every prompt generated here MUST:**
1. Explicitly list which skills to use
2. Include critical gotchas inline
3. Tell Claude NOT to deviate from skill guidance

## Prompt Template Structure

```
## Task: [TASK NAME]

### Required Skills
You MUST use these skills - do NOT attempt to figure things out without them:
- `spectrocloud-common` - [what to use it for]
- `spectrocloud-[specific]` - [what to use it for]

### Critical Rules (DO NOT IGNORE)
- [Baked-in gotcha 1]
- [Baked-in gotcha 2]

### Steps
1. [Step with skill reference]
2. [Step with skill reference]

### If Something Fails
- Check `spectrocloud-troubleshooting` skill
- [Specific recovery guidance]
```

---

## Prompt: 2-Node Edge Cluster Deployment

Use this when deploying a 2-node HA Edge cluster with appliance mode.

```
## Task: Deploy 2-Node Edge Cluster

### Required Skills
You MUST use these skills - do NOT attempt to figure things out without them:
- `spectrocloud-common` - API auth, project lookup, pack discovery
- `spectrocloud-appliance-mode` - CanvOS builds, ISO creation, user-data
- `spectrocloud-cluster-profiles` - Profile creation with correct pack values
- `spectrocloud-clusters` - 2-node cluster creation (API or Terraform)
- `spectrocloud-troubleshooting` - Event monitoring during provisioning

### Critical Rules (DO NOT IGNORE)
1. **Pack API paginates at 50** - Use offset loop (0, 50, 100, 150) to find latest versions
2. **Check actual image tag after build** - Don't assume format, use `docker images | grep $REPO`
3. **2-node requires K3s** - Not kubeadm or RKE2
4. **Edge tokens are TENANT-scoped** - No ProjectUid header when creating tokens
5. **Version alignment** - Provider image K8s version must match edge-k3s pack version
6. **Fetch COMPLETE pack values** - Partial values cause validation failures

### Steps

#### Phase 1: Setup
1. Get API key from 1Password using MCP tools (see `spectrocloud-common`)
2. Look up project UID by name
3. Create edge host registration token (NO ProjectUid header!)

#### Phase 2: Build (on build machine)
4. SSH to build machine, clone CanvOS
5. Configure .arg with K3s, TWO_NODE=true
6. Create user-data with bridge networking (see `spectrocloud-appliance-mode`)
7. Run `earthly --push +provider-image && earthly +iso`
8. **CHECK ACTUAL IMAGE TAG**: `docker images | grep $IMAGE_REPO` - note exact tag
9. Rename ISO with version: `palette-edge-k3s-<VERSION>-<DATE>.iso`

#### Phase 3: Deploy VMs
10. Upload ISO to Proxmox
11. Create 2 VMs: 4+ CPU, 8GB+ RAM, 150GB+ disk
12. Set boot order: `order=scsi0;ide2;net0`
13. Boot and wait for edge hosts to register in Palette

#### Phase 4: Cluster Profile
14. Fetch COMPLETE pack values for each pack (see `spectrocloud-cluster-profiles`)
15. Use exact image tag from step 8 in BYOOS system.uri
16. Match K8s pack version to what was built
17. Create profile via API or Terraform

#### Phase 5: Create Cluster
18. Use 2-node API structure from `spectrocloud-clusters`:
    - `machinePoolConfig` (not `machinePools`)
    - `twoNodeCandidatePriority`: "primary"/"secondary"
    - `isTwoNodeCluster: true` in cloudConfig
19. Monitor events using `spectrocloud-troubleshooting` skill

### If Something Fails
- **Pack not found**: Check pagination - API limits to 50, use offset
- **Profile validation fails**: You used partial pack values - fetch complete defaults
- **Cluster stuck**: SSH to edge host, check `journalctl -u spectro-stylus-agent.service -f`
- **Version mismatch errors**: Provider image tag doesn't match K8s pack version
```

---

## Prompt: Agent Mode Deployment

Use this for quick agent-mode deployments on existing VMs/nodes.

```
## Task: Deploy Agent Mode Edge Cluster

### Required Skills
You MUST use these skills - do NOT attempt to figure things out without them:
- `spectrocloud-common` - API auth, project lookup, pack discovery
- `spectrocloud-agent-mode` - Agent installation, registration
- `spectrocloud-cluster-profiles` - Profile with BYOOS system.uri: "NA"
- `spectrocloud-clusters` - Cluster creation
- `spectrocloud-troubleshooting` - Event monitoring

### Critical Rules (DO NOT IGNORE)
1. **Agent mode supports 1 or 3+ nodes** - NOT 2-node (use appliance mode for 2-node)
2. **BYOOS pack must use "NA"** - Set `options.system.uri: "NA"`
3. **Pack API paginates at 50** - Use offset loop for version discovery
4. **Edge tokens are TENANT-scoped** - No ProjectUid header

### Steps
1. Get API key, look up project UID
2. Create edge host token (NO ProjectUid header)
3. Install agent on target node(s) - see `spectrocloud-agent-mode`
4. Wait for edge host(s) to register
5. Create cluster profile with BYOOS system.uri: "NA"
6. Create cluster, monitor with event stream
```

---

## Prompt: Update Cluster Profile

Use this when updating packs on an existing cluster.

```
## Task: Update Cluster Profile

### Required Skills
- `spectrocloud-cluster-profiles` - Profile versioning
- `spectrocloud-clusters` - Profile update API
- `spectrocloud-troubleshooting` - Monitor update progress

### Critical Rules
1. **Create NEW profile version** - Don't modify in place
2. **Fetch current pack values first** - Don't lose existing configuration
3. **Pack pagination at 50** - Use offset when finding new pack versions

### Steps
1. Get current profile: `GET /v1/clusterprofiles/{uid}`
2. Find new pack version (with pagination!)
3. Fetch complete pack values for new version
4. Create new profile version (same name, bumped version)
5. Update cluster to new profile: `PUT /v1/spectroclusters/{uid}/profiles`
6. Monitor events during update
```

---

## Prompt: Terraform Infrastructure Profile

Use this when creating reusable Terraform for profiles.

```
## Task: Create Terraform Cluster Profile

### Required Skills
- `spectrocloud-common` - Registry lookup, Terraform provider setup
- `spectrocloud-cluster-profiles` - Pack types, Terraform examples

### Critical Rules
1. **Always specify registry_uid** - Packs exist in multiple registries
2. **Fetch pack values via API first** - Then save to files
3. **Use file() for pack values** - Not inline heredocs for large values

### Steps
1. Look up registry UIDs via API (see `spectrocloud-common`)
2. For each pack, fetch complete default values
3. Save values to `pack-values/<pack>.yaml` files
4. Create Terraform with explicit registry_uid on each pack data source
5. Reference values with `file("${path.module}/pack-values/<pack>.yaml")`
```

---

## Adding New Prompts

When a task repeatedly causes issues:

1. Identify which skills cover the task
2. List the gotchas that keep tripping Claude up
3. Write step-by-step instructions referencing skills
4. Include failure recovery guidance
5. Test the prompt and refine

**The goal**: Claude should never hit the same issue twice if we've documented it.
