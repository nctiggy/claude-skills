#!/usr/bin/env bash
# proxmox-vm.sh — lab-adapter provider: ephemeral Ubuntu cloud-image VMs on the pve
# cluster for a poc-test suite. Follows the snuc-part template spec + boot-order rules
# (references/proxmox-vms.md) and the SAFETY RAILS (SKILL.md):
#   - VMIDs 900-999 ONLY, names poctest-<suite>-<role>
#   - teardown destroys only VMs recorded in the suite's state file, re-verified
#     against the range AND the name prefix at destroy time
#   - LAB_DRYRUN=1 prints every mutating command instead of executing
#
# Env:
#   LAB_PVE_HOST     pve node for qm commands           (default 172.18.0.70 = pve1)
#   LAB_PVE_USER     ssh user on pve                    (default root, key-auth)
#   LAB_CLOUD_IMAGE  path ON THE PVE HOST to an Ubuntu cloud image (required for setup)
#   LAB_SSH_PUBKEY   local path to the pubkey injected via cloud-init
#                    (default: first of ~/.ssh/id_ed25519.pub, ~/.ssh/id_rsa.pub)
#   LAB_VM_CORES / LAB_VM_MEMORY / LAB_VM_DISK_GROW    (default 4 / 8192 / +40G)
#   LAB_STATE_DIR    default ~/.cache/craig-home-lab
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVE="${LAB_PVE_USER:-root}@${LAB_PVE_HOST:-172.18.0.70}"
STATE_DIR="${LAB_STATE_DIR:-$HOME/.cache/craig-home-lab}"
VMID_MIN=900 VMID_MAX=999
DRY="${LAB_DRYRUN:-}"

die() { echo "proxmox-vm: $*" >&2; exit 1; }

pve() {  # run a command on the pve host (or print it in dry-run)
  if [ -n "$DRY" ]; then
    echo "DRYRUN ssh $PVE -- $*" >&2
    return 0
  fi
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$PVE" "$@"
}

suite_meta() {  # $1=suite.yaml, $2=field (name|roles)
  python3 - "$1" "$2" <<'PY'
import sys, yaml, re
data = yaml.safe_load(open(sys.argv[1])) or {}
if sys.argv[2] == "name":
    name = str(data.get("suite") or "suite")
    print(re.sub(r"[^a-z0-9-]", "-", name.lower()))
else:
    for role in ((data.get("adapter_requirements") or {}).get("hosts") or []):
        print(role)
PY
}

state_file() { echo "$STATE_DIR/$1.json"; }

CMD="${1:-}"; shift || true
SUITE_FILE=""
POS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --suite) SUITE_FILE="$2"; shift 2 ;;
    *) POS+=("$1"); shift ;;
  esac
done

case "$CMD" in
  setup)
    [ -n "$SUITE_FILE" ] || die "setup needs --suite <poc-test-suite.yaml>"
    [ -n "${LAB_CLOUD_IMAGE:-}" ] || die "LAB_CLOUD_IMAGE (path on the pve host) is required"
    suite="$(suite_meta "$SUITE_FILE" name)"
    roles=()
    while IFS= read -r r; do [ -n "$r" ] && roles+=("$r"); done < <(suite_meta "$SUITE_FILE" roles)
    [ ${#roles[@]} -gt 0 ] || die "suite has no adapter_requirements.hosts"

    pubkey_file=""
    for cand in "${LAB_SSH_PUBKEY:-}" "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
      [ -n "$cand" ] && [ -f "$cand" ] && pubkey_file="$cand" && break
    done
    [ -n "$pubkey_file" ] || die "no SSH pubkey found (set LAB_SSH_PUBKEY)"

    # Free VMIDs inside the ephemeral range only.
    if [ -n "$DRY" ]; then
      used=""
    else
      used="$(pve qm list 2>/dev/null | awk 'NR>1{print $1}')"
    fi
    next_vmid() {
      local id
      for ((id = VMID_MIN; id <= VMID_MAX; id++)); do
        if ! grep -qx "$id" <<< "$used"; then
          used+=$'\n'"$id"
          echo "$id"
          return 0
        fi
      done
      die "no free VMID in $VMID_MIN-$VMID_MAX"
    }

    # Push the pubkey to the pve host for cloud-init --sshkeys.
    remote_key="/tmp/poctest-$suite.pub"
    if [ -n "$DRY" ]; then
      echo "DRYRUN scp $pubkey_file $PVE:$remote_key" >&2
    else
      scp -o BatchMode=yes -q "$pubkey_file" "$PVE:$remote_key"
    fi

    declare -A vmid_of addr_of
    for role in "${roles[@]}"; do
      vmid="$(next_vmid)"
      name="poctest-$suite-$role"
      [ "${#name}" -le 63 ] || die "VM name too long: $name"
      pve qm create "$vmid" --name "$name" \
        --bios ovmf --efidisk0 vm-pool:0,efitype=4m \
        --cpu host --cores "${LAB_VM_CORES:-4}" --memory "${LAB_VM_MEMORY:-8192}" \
        --numa 0 --ostype l26 --scsihw virtio-scsi-single \
        --net0 "virtio,bridge=vmbr0,tag=19" --agent 1
      pve qm set "$vmid" --scsi0 "vm-pool:0,import-from=$LAB_CLOUD_IMAGE,iothread=1,backup=0"
      # Cloud-image import locks boot to net0 — MUST re-point at the disk
      # (references/proxmox-vms.md, learned 2026-06-12).
      pve qm set "$vmid" --boot order=scsi0
      pve qm set "$vmid" --ide2 vm-pool:cloudinit --ciuser ubuntu \
        --sshkeys "$remote_key" --ipconfig0 ip=dhcp
      pve qm disk resize "$vmid" scsi0 "${LAB_VM_DISK_GROW:-+40G}"
      pve qm start "$vmid"
      vmid_of[$role]="$vmid"
      addr_of[$role]=""
    done

    # Wait for qemu-guest-agent to report a VLAN-19 address.
    if [ -n "$DRY" ]; then
      i=10
      for role in "${roles[@]}"; do
        addr_of[$role]="192.0.2.$i"   # TEST-NET placeholder in dry-run
        echo "DRYRUN wait-for-ip vmid=${vmid_of[$role]} role=$role" >&2
        i=$((i + 1))
      done
    else
      for role in "${roles[@]}"; do
        vmid="${vmid_of[$role]}"
        for _ in $(seq 1 60); do
          ip="$(pve qm agent "$vmid" network-get-interfaces 2>/dev/null \
                | python3 -c '
import json, sys
try:
    ifaces = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for i in ifaces:
    for a in i.get("ip-addresses") or []:
        ip = a.get("ip-address", "")
        if ip.startswith("172.19."):
            print(ip); sys.exit(0)
' || true)"
          [ -n "$ip" ] && { addr_of[$role]="$ip"; break; }
          sleep 5
        done
        [ -n "${addr_of[$role]}" ] || die "vm $vmid ($role) never reported a 172.19.x address"
      done
    fi

    # State (vmids/ips/roles only — no secrets), then the contract JSON.
    json='{"adapter": "craig-home-lab/proxmox-vm", "hosts": {'
    first=1
    for role in "${roles[@]}"; do
      [ $first -eq 0 ] && json+=', '
      json+="\"$role\": {\"address\": \"${addr_of[$role]}\", \"user\": \"ubuntu\", \"vmid\": ${vmid_of[$role]}}"
      first=0
    done
    json+='}}'
    if [ -n "$DRY" ]; then
      echo "DRYRUN would write state to $(state_file "$suite")" >&2
    else
      mkdir -p "$STATE_DIR"
      printf '%s\n' "$json" > "$(state_file "$suite")"
    fi
    echo "$json"
    ;;

  exec)
    role="${POS[0]:?exec needs <host>}"
    script="${POS[1]:?exec needs <script>}"
    [ -f "$script" ] || die "no such script: $script"
    sf=""
    for f in "$STATE_DIR"/*.json; do
      [ -f "$f" ] || continue
      if python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
sys.exit(0 if sys.argv[2] in d.get("hosts", {}) else 1)' "$f" "$role"; then sf="$f"; break; fi
    done
    [ -n "$sf" ] || die "no state file with role $role (run setup first)"
    read -r user addr < <(python3 -c '
import json, sys
h = json.load(open(sys.argv[1]))["hosts"][sys.argv[2]]
print(h["user"], h["address"])' "$sf" "$role")
    if [ -n "$DRY" ]; then
      echo "DRYRUN ssh $user@$addr 'bash -s' < $script" >&2
      exit 0
    fi
    ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$user@$addr" 'bash -s' < "$script"
    ;;

  teardown)
    if [ -n "$SUITE_FILE" ] && [ -f "$SUITE_FILE" ]; then
      suites=("$(suite_meta "$SUITE_FILE" name)")
    else
      suites=()
      for f in "$STATE_DIR"/*.json; do
        [ -f "$f" ] && suites+=("$(basename "$f" .json)")
      done
    fi
    for suite in ${suites[@]+"${suites[@]}"}; do
      sf="$(state_file "$suite")"
      [ -f "$sf" ] || continue
      while read -r role vmid; do
        # RAIL: range check from state…
        if [ "$vmid" -lt $VMID_MIN ] || [ "$vmid" -gt $VMID_MAX ]; then
          echo "REFUSING to destroy vmid $vmid (outside $VMID_MIN-$VMID_MAX)" >&2
          continue
        fi
        # …AND live name check: only poctest- VMs die.
        if [ -z "$DRY" ]; then
          name="$(pve qm config "$vmid" 2>/dev/null | awk '/^name:/{print $2}')"
          case "$name" in
            poctest-*) ;;
            "") echo "vmid $vmid already gone" >&2; continue ;;
            *) echo "REFUSING to destroy vmid $vmid (name '$name' lacks poctest- prefix)" >&2; continue ;;
          esac
        fi
        pve qm stop "$vmid" --timeout 30 || true
        pve qm destroy "$vmid" --purge || true
      done < <(python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
for role, h in d.get("hosts", {}).items():
    print(role, h.get("vmid", -1))' "$sf")
      if [ -n "$DRY" ]; then
        echo "DRYRUN would remove state $sf" >&2
      else
        rm -f "$sf"
      fi
    done
    "$SCRIPT_DIR/../palette-cleanup.sh" || echo "warn: palette-cleanup failed (rerun manually)" >&2
    ;;

  *)
    die "usage: proxmox-vm.sh {setup --suite F | exec <host> <script> | teardown [--suite F]}"
    ;;
esac
