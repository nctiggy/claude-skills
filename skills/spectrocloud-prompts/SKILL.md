---
name: spectrocloud-prompts
description: Generate context-efficient prompts for SpectroCloud tasks. Uses critic loop to optimize. Enforces skill usage and agent delegation.
---

# SpectroCloud Prompt Generator

Generate prompts optimized for **context preservation** in the primary session.

## Core Principles

### 1. Context is Precious
The main session's context window is limited. Every prompt MUST:
- **Delegate heavy work to agents** - Exploration, builds, monitoring go to subagents
- **Use skills as pre-loaded knowledge** - Don't re-discover what's documented
- **Keep main session as orchestrator** - Coordinate, don't execute everything inline

### 2. Skills ARE the Knowledge
Skills contain tested, refined knowledge. Prompts should:
- Reference skills, not reinvent
- Trust skill guidance over improvisation
- Add learnings back to skills, not prompts

### 3. Agents Preserve Context
Use agents (Task tool) for:
- Long-running operations (builds, monitoring)
- Exploration and discovery
- Any task that generates verbose output

---

## Prompt Generation Workflow (MANDATORY)

**Every prompt MUST go through the critic loop before being finalized.**

### Step 1: Draft Initial Prompt
Write the prompt following the template structure below.

### Step 2: Run Prompt Critic
Apply this critic checklist to the draft:

```
## Prompt Critic Checklist

### Context Efficiency
- [ ] Does it delegate long tasks to agents?
- [ ] Does it avoid verbose exploration in main session?
- [ ] Are skills referenced instead of inline explanations?
- [ ] Is the main session orchestrating, not doing everything?

### Skill Usage
- [ ] Are ALL relevant skills listed?
- [ ] Does each step reference which skill to consult?
- [ ] Are critical gotchas from skills baked in?
- [ ] Is there NO redundant explanation of what skills already cover?

### Agent Delegation
- [ ] Build tasks → agent
- [ ] Monitoring/polling → agent
- [ ] Discovery/exploration → agent
- [ ] Pack value fetching → agent or inline (small)
- [ ] Terraform apply → can be main session (needs interaction)

### Failure Handling
- [ ] Does it reference troubleshooting skill?
- [ ] Are common failures listed with skill-based recovery?
- [ ] Is there guidance on when to escalate vs retry?

### Conciseness
- [ ] Can any section be shorter?
- [ ] Are there redundant instructions?
- [ ] Is the prompt <100 lines when possible?
```

### Step 3: Refine Based on Critic
Fix any issues found. Repeat critic until all boxes checked.

### Step 4: Finalize
The prompt is ready when the critic passes.

---

## Prompt Template Structure

```
## Task: [TASK NAME]

### Context Strategy
- Main session: [what it orchestrates]
- Agents: [what gets delegated]

### Required Skills
Use these skills - they contain the knowledge, don't reinvent:
- `spectrocloud-X` - [one-line purpose]

### Critical Rules
[Only rules NOT in skills - assume skills will be read]

### Workflow

#### Phase N: [Name]
**[Agent/Main]**: [brief description]
- Step (skill: `skill-name`)
- Step (skill: `skill-name`)

### On Failure
- Check `spectrocloud-troubleshooting`
- [Specific recovery if not in troubleshooting skill]
```

---

## Prompt: 2-Node Edge Cluster Deployment

```
## Task: Deploy 2-Node Edge Cluster

### Context Strategy
- Main session: Orchestrate phases, create Terraform, final deployment
- Build Agent: CanvOS build on remote machine
- Monitor Agent: Watch cluster events during provisioning
- Skill Tracker Agent: Capture learnings for skill updates

### Required Skills
Use these - they contain the knowledge:
- `spectrocloud-common` - Auth, project lookup, pack discovery (pagination!)
- `spectrocloud-appliance-mode` - CanvOS, user-data, ISO versioning
- `spectrocloud-cluster-profiles` - Pack values, version alignment
- `spectrocloud-clusters` - 2-node API/Terraform structure
- `spectrocloud-troubleshooting` - Event monitoring, known errors

### Critical Rules
1. Pack API paginates at 50 - use offset loop
2. Check actual image tag after build - don't assume format
3. 2-node = K3s only
4. Edge tokens = tenant-scoped (no ProjectUid)
5. Version alignment: provider image K8s = edge-k3s pack version

### Workflow

#### Phase 1: Setup [Main]
- Get API key via MCP (skill: `common`)
- Look up project UID (skill: `common`)
- Create edge token - NO ProjectUid header (skill: `clusters`)

#### Phase 2: Build [Agent]
Spawn agent for remote build:
- SSH to build machine, clone CanvOS
- Configure .arg: K3s, TWO_NODE=true (skill: `appliance-mode`)
- Create user-data with bridge networking (skill: `appliance-mode`)
- Build: `earthly --push +provider-image && earthly +iso`
- **Capture actual image tag**: `docker images | grep $REPO`
- Rename ISO with version
- Return: image tag, ISO path

#### Phase 3: Deploy VMs [Main or Agent]
- Upload ISO to Proxmox
- Create 2 VMs (4 CPU, 8GB, 150GB, boot: scsi0;ide2;net0)
- Wait for edge hosts in Palette

#### Phase 4: Terraform [Main]
Create reusable Terraform (skill: `cluster-profiles`, `clusters`):
- Fetch pack values (use image tag from Phase 2)
- Create profiles/ module
- Create clusters/ module
- Apply profiles first, then clusters

#### Phase 5: Monitor [Agent]
Spawn monitor agent:
- Poll events every 10s (skill: `troubleshooting`)
- Report errors, filter noise
- Alert on actionable issues

### On Failure
- `spectrocloud-troubleshooting` for event analysis
- Pack not found → pagination issue
- Profile validation → incomplete pack values
- Cluster stuck → SSH to edge host, check stylus agent

### Skill Improvement
Spawn tracker agent to capture learnings → update skills at end
```

---

## Prompt: Agent Mode Deployment

```
## Task: Deploy Agent Mode Edge Cluster

### Context Strategy
- Main session: Orchestrate, create profile/cluster
- Monitor Agent: Event polling

### Required Skills
- `spectrocloud-common` - Auth, pack discovery
- `spectrocloud-agent-mode` - Installation steps
- `spectrocloud-cluster-profiles` - BYOOS with "NA"
- `spectrocloud-clusters` - Cluster creation
- `spectrocloud-troubleshooting` - Event monitoring

### Critical Rules
1. Agent mode = 1 or 3+ nodes (NOT 2)
2. BYOOS system.uri = "NA"
3. Pack pagination at 50

### Workflow

#### Phase 1: Setup [Main]
- Auth, project lookup (skill: `common`)
- Create edge token - NO ProjectUid (skill: `clusters`)

#### Phase 2: Install Agent [Main or Agent]
- Install on target nodes (skill: `agent-mode`)
- Wait for registration

#### Phase 3: Deploy [Main]
- Create profile with BYOOS "NA" (skill: `cluster-profiles`)
- Create cluster (skill: `clusters`)

#### Phase 4: Monitor [Agent]
- Event polling (skill: `troubleshooting`)

### On Failure
- See `spectrocloud-troubleshooting`
```

---

## Adding New Prompts

1. **Draft** following template
2. **Run critic checklist** - ALL boxes must check
3. **Refine** until critic passes
4. **Test** the prompt
5. **Capture learnings** back to skills (not prompts)

**Prompts reference skills. Skills contain knowledge.**
