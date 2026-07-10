# Proxmox VMs — creation pattern + adapter rules

Cluster: pve1/pve2/pve3 = 172.18.0.70/.71/.72 (root SSH). `qm` commands run over SSH to
pve1 unless a specific node is required. Web UI: `https://172.18.0.70:8006/` (untrusted cert).

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
- Network: `net0: virtio,bridge=vmbr0,tag=19` (VLAN 19, DHCP). Get the IP via
  qemu-guest-agent (`qm agent <id> network-get-interfaces`) once the guest is up.
- Cloud image: set `LAB_CLOUD_IMAGE` to the image path already present on pve1
  (e.g. a noble server cloudimg under `/var/lib/vz/template/`); the provider
  `import-from`s it onto vm-pool.

## ISO upload (appliance-mode testing)

Upload ISOs via the Proxmox API/UI to a storage that allows `iso` content, then attach
as `ide2 <storage>:iso/<name>.iso,media=cdrom`. CanvOS ISOs come from subtle-bug
(`~/CanvOS/build/palette-edge-installer.iso`) — rename with version+date before upload.
