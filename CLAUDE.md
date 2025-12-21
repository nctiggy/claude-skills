# Claude Skills Repository

## Workflow

### Publishing Skills
**DO NOT manually upload skills or create artifacts.** The GitHub Actions pipeline handles everything:

1. Make changes to skills in `skills/<skill-name>/SKILL.md`
2. Commit and push to `main`
3. GitHub Actions will:
   - Validate skills
   - Package them as `.skill` files
   - Upload to Anthropic API
   - Create downloadable artifacts

### After Pushing

1. **Verify GitHub Actions succeeded**:
   ```bash
   gh run list --limit 3  # Check recent runs
   gh run view <run-id>   # View details if needed
   ```

2. **Sync for Claude Code CLI** (symlinks source dirs for live development):
   ```bash
   make sync  # Creates symlinks in ~/.claude/skills/
   ```

3. **Download artifacts for Claude Web Client**:
   ```bash
   # Get latest successful run ID
   gh run list --limit 1 --status success

   # Download and copy to Desktop
   gh run download <run-id> --dir /tmp/skill-artifacts
   cp /tmp/skill-artifacts/packaged-skills/*.skill ~/Desktop/
   ```
   Then drag `.skill` files into Claude web client to add them.

## Skills Structure

Each skill is a directory in `skills/` containing:
- `SKILL.md` - The skill definition with frontmatter (name, description)

### Content Guidelines
**Keep skills generic and shareable.** Do NOT include:
- Personal infrastructure (IP addresses, hostnames like `subtle-bug.maas`)
- Secret store references (1Password vaults, specific credential paths)
- MCP server names specific to your environment
- Any environment-specific configuration

Use placeholder values like `<your-api-key>`, `$PROJECT_UID`, or generic examples instead.

## Testing Skills

### SpectroCloud Edge Testing
- Use `subtle-bug.maas` as build machine for CanvOS builds
- Proxmox at 172.18.0.4:8006 for VM testing
- Credentials in 1Password (k8s vault)

### Cleanup Checklist
When testing edge deployments, remember to clean up:
1. Edge hosts from Palette (Clusters → Edge Hosts → Delete)
2. VMs from Proxmox
3. ISOs from Proxmox storage
4. Nodes from MaaS (if registered)
