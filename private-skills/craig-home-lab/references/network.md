# Lab network map

Verified 2026-06-12 (keysight agent-mode build). VLAN N ↔ 172.N′.0.0/24 scheme;
gateway is always `.1` (UniFi — also DHCP/DNS; dnsmasq lease 1d, pool reaches into
the .200s).

| VLAN | Subnet | Purpose |
|---|---|---|
| 18 | 172.18.0.0/24 | infra / Proxmox / MaaS |
| 19 | 172.19.0.0/24 | lab workloads (claude-server, test clusters) |
| — | 172.20.0.0/24 | laptop LAN |

## Hosts

| Host | Address | Notes |
|---|---|---|
| pve1 / pve2 / pve3 | 172.18.0.70 / .71 / .72 | **3-node Proxmox cluster** (root SSH; password in 1Password, see credentials.md). The `172.18.0.4` address in older notes is **STALE — never use it** |
| MaaS | 172.18.0.2 | `http://172.18.0.2:5240/MAAS`; VM + bare-metal inventory, PCG deploy target |
| subtle-bug (MS-01) | 172.18.0.107 | `ubuntu@` key-auth + passwordless sudo; **CanvOS build host** (`~/CanvOS`, earthly+docker, output ISO at `~/CanvOS/build/palette-edge-installer.iso`). bond0→br0 is a trunk: `ip link add link br0 name br0.N type vlan id N` gives L2 presence on any VLAN for probing |
| claude-server | 172.19.0.108 | remote Claude Code box (nctiggy) |
| node11–13 (MS-01) | MaaS inventory | bare metal; AMT power control (amt-power.md); 500GB NVMe OS + 1–2TB storage-pool drive |

## VLAN 19 allocations

- Free static block: **.10–.99** (keysight cluster used VIP .59 + MetalLB .60–.80).
- Routable from the laptop directly. Ephemeral poc-test VMs land here via DHCP
  (net tag 19); reserve statics from the free block if a suite needs them.

## Gotchas

- **ICMP to 172.18.0.x is filtered from VLAN 19** — TCP works; don't "prove it's down" with ping.
- **claude-server kind-bridge shadow route:** a stale docker/kind bridge
  (`br-…`, 172.18.0.0/16, linkdown) shadows the real 172.18.0.0/24 route —
  `ip route add 172.18.0.0/24 via 172.19.0.1` or delete the kind network.
- MS-01 netplan pattern (LACP bond → br0 → VLAN): see the lab section of
  `~/.claude/CLAUDE.md` for the full netplan YAML.
