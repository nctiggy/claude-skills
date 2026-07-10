---
name: craig-home-lab
description: >-
  Craig's private home-lab map and the lab-adapter implementation that plugs into the
  spectrocloud-poc-docs live-test tier (T2). Covers the Proxmox cluster (pve1-3, incl. the
  RTX A2000 GPU passthrough on pve3), MaaS, the CanvOS build host, AMT power control,
  network/VLAN layout, and 1Password service-account credential paths. Use when running POC
  doc test suites against the lab, creating/destroying ephemeral lab VMs (incl. GPU VMs),
  cleaning up poctest- Palette resources, or when any task needs lab addresses, credentials
  paths, or power control. PRIVATE - lives in private-skills/, is never uploaded by CI, and
  must never be copied into a shareable skill.
---

# Craig's Home Lab — Map + POC-Test Lab Adapter

Private companion to the generic `spectrocloud-poc-docs` skill: that skill defines the
lab-adapter **contract**; this one **implements** it against Craig's lab. Lab specifics
(IPs, hostnames, op paths) live HERE and only here — the generic skill's `check_docs.py`
blocks them from ever appearing in customer-facing output (feed it
`references/check-docs-denylist.txt` to catch this lab's hostnames too).

## SAFETY RAILS — hard MUSTs (code-enforced where possible)

1. **Never test on production or customer resources.** Lab only. (Encodes the
   no-test-on-stores SEV-1 lesson.) Palette work goes to an explicitly exported
   `LAB_PROJECT_UID`; `references/project-denylist.txt` lists UIDs the tooling refuses.
2. **`poctest-` prefix is the destructive boundary.** Anything the adapter creates
   (VMs, clusters, edge hosts) is named `poctest-*`; teardown/cleanup refuse to touch
   any resource without the prefix.
3. **Ephemeral Proxmox VMs use VMIDs 900–999 only.** The provider refuses to create or
   destroy outside that range. Existing VMs (100s) are never adapter-managed.
4. **Secrets never touch disk.** Credentials are `op read` at call time and passed via
   env/stdout; the adapter state file holds only VMIDs/IPs/roles.
5. **AMT power ops only against nodes in the MaaS inventory** (node11–13 MS-01s) —
   see `references/amt-power.md`. Never probe other hosts on 16993.
6. **Proxmox is pve1/2/3 at 172.18.0.70/.71/.72** — the old `172.18.0.4` single-node
   address is STALE; never use it. pve3 (.72) has an **NVIDIA RTX A2000** for PCIe
   passthrough — GPU VMs must be pinned there (`LAB_PVE_HOST=172.18.0.72`); see
   `references/proxmox-vms.md`.

## Lab adapter (spectrocloud-poc-docs T2)

```bash
# choose a provider: existing-host (default) or proxmox-vm
export LAB_PROVIDER=proxmox-vm
export LAB_PROJECT_UID=<poc project uid>        # required for env/cleanup
python3 <poc-docs-skill>/scripts/run_doc_tests.py \
  --suite <docs-site>/poc-test-suite.yaml \
  --adapter <this-skill>/scripts/lab-adapter.sh
```

- `scripts/lab-adapter.sh` — dispatcher implementing `setup | env | exec | teardown`.
  `env` emits `PALETTE_API_KEY` (via op) + `PROJECT_UID` (from `LAB_PROJECT_UID`).
- `scripts/providers/existing-host.sh` — no provisioning; maps suite roles to hosts you
  name in `LAB_HOSTS` (`role=user@addr,...`). Teardown = Palette cleanup only.
- `scripts/providers/proxmox-vm.sh` — creates ephemeral Ubuntu cloud-image VMs on the
  least-busy cluster node (pin with `LAB_PVE_HOST`, e.g. `172.18.0.72` for the pve3
  GPU) — VMID 900–999, `poctest-` names, VLAN 19 static IPs, guest-agent readiness,
  `LAB_SSH_JUMP` for exec. Teardown destroys exactly the recorded VMs (Palette cleanup
  runs FIRST, while VMs are alive). **`LAB_DRYRUN=1` prints every command instead of
  executing** — always dry-run first.
- `scripts/palette-cleanup.sh` — deletes `poctest-*` clusters and edge hosts in
  `LAB_PROJECT_UID`; standalone or called by provider teardown.

First live run of any suite is **supervised** — watch it; never hand a fresh suite to an
unattended loop.

## References

- `references/network.md` — VLAN↔subnet map, every lab host, routing gotchas
- `references/proxmox-vms.md` — VM template spec (the snuc-part pattern), boot-order rules, ISO upload
- `references/amt-power.md` — wsman power control on the MS-01s (port 16993 only)
- `references/credentials.md` — op service-account tokens, item paths, how `env` resolves keys
- `references/check-docs-denylist.txt` — lab hostname/IP regexes for the generic secret scan
- `references/project-denylist.txt` — Palette project UIDs the tooling must refuse

## Sync into ~/.claude/skills

This skill lives OUTSIDE `skills/` so the repo's deploy CI (path filter `skills/**`)
can never upload it. Link it locally with:

```bash
make sync-private     # symlinks private-skills/* into ~/.claude/skills/
```
