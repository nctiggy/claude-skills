# Proxmox VMs — creation pattern + adapter rules

Cluster: pve1/pve2/pve3 = 172.18.0.70/.71/.72 (root SSH). `qm` is node-local — run it on
the node that owns the VM. The proxmox-vm provider places new VMs on the least-busy
online node unless `LAB_PVE_HOST` pins one. Web UI: `https://172.18.0.70:8006/`
(untrusted cert). **pve3 has an NVIDIA RTX A2000 available for PCIe passthrough** (see
GPU section below).

## The template spec (Craig's standard — from VM 101 `snuc-part`, June 2026)

```text
bios: ovmf, efidisk0 on vm-pool (efitype=4m)
cpu: host, cores: 4, memory: 8192, numa: 0, ostype: l26
scsihw: virtio-scsi-single
disks: virtio0/virtio1 on vm-pool (Ceph RBD = thin), backup=0, iothread=1
cdrom: ide2 <iso>,media=cdrom
net0: virtio,bridge=vmbr0,tag=19
agent: 1, onboot: 1
```

Why: RBD `vm-pool` disks are already thin — no qcow2-on-cephfs or NVMe-emulation
gymnastics. Guest sees `/dev/vda`, `/dev/vdb`; adapt user-data `install.device`
accordingly for VM tests.

## Boot-order rules (both learned the hard way)

- **Never set a custom boot order on a fresh VM** when the disk exists at `qm create`
  time. Proxmox's default (disk; cdrom; net) is correct: empty disk falls through to CD
  on first boot; after install it boots from disk.
- **Exception (cloud-image import, hit 2026-06-12):** `qm create` with NO disk then
  `qm set --scsi0 vm-pool:0,import-from=...` locks `boot: order=net0` at create time and
  the VM PXE-loops. In that one case you MUST `qm set <id> --boot order=scsi0`.
  The proxmox-vm provider uses the cloud-image path, so it always applies this fix.

## Adapter-managed (ephemeral) VMs

- **VMID range 900–999 only** — the provider refuses anything outside it, so the
  permanent VMs (100s: MaaS, PCG nodes, templates) can never collide or be destroyed.
- **Names are `poctest-<suite>-<role>`** — teardown matches on VMID range AND name
  prefix AND the suite's state file before destroying.
- Network: `net0: virtio,bridge=vmbr0,tag=19` (VLAN 19). The provider assigns a static
  IP from the poctest range 172.19.0.200-254 via cloud-init; readiness is confirmed via
  qemu-guest-agent (`qm agent <id> network-get-interfaces`) since neither pve nor the
  runner routes into VLAN 19. `exec` reaches guests through `LAB_SSH_JUMP` (ProxyJump
  via an on-VLAN19 host).
- Placement: least-busy online node (memory fraction) unless `LAB_PVE_HOST` pins one.
  Teardown targets the node recorded in the suite state (`pve_host`).
- Cloud image: set `LAB_CLOUD_IMAGE` to the golden image path present on every node
  (a noble server cloudimg with qemu-guest-agent baked in, under
  `/var/lib/vz/template/`); the provider `import-from`s it onto vm-pool (shared Ceph).

## GPU passthrough (pve3 — NVIDIA RTX A2000)

pve3 (172.18.0.72) has an **NVIDIA RTX A2000** that can be passed through to a VM.

- **GPU VMs MUST be created on pve3** — `hostpci` is node-local and the least-busy
  placement won't land there deliberately. Pin it: `export LAB_PVE_HOST=172.18.0.72`.
- Find the PCI address on pve3: `ssh root@172.18.0.72 "lspci -nn | grep -i nvidia"`
  (pass the audio function too, or use the whole device with `,pcie=1`).
- Attach: `qm set <id> --machine q35 --hostpci0 <pci-addr>,pcie=1` — passthrough wants
  the q35 machine type alongside the OVMF/UEFI bios the template already uses.
- Only ONE VM can hold the GPU at a time; a second `hostpci` claim fails at VM start.
  Check who has it: `ssh root@172.18.0.72 "grep -l hostpci /etc/pve/qemu-server/*.conf"`.
- Guest needs the NVIDIA driver (e.g. `apt install -y nvidia-driver-535-server` on
  Ubuntu; verify with `nvidia-smi`). For K8s GPU workloads add the NVIDIA GPU Operator /
  device plugin on top.

## ISO upload (appliance-mode testing)

Upload ISOs via the Proxmox API/UI to a storage that allows `iso` content, then attach
as `ide2 <storage>:iso/<name>.iso,media=cdrom`. CanvOS ISOs come from subtle-bug
(`~/CanvOS/build/palette-edge-installer.iso`) — rename with version+date before upload.
