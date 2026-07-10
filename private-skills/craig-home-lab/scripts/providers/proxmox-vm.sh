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
#   LAB_PVE_HOST     PIN a pve node for placement (e.g. 172.18.0.72 = pve3 for GPU
#                    passthrough). Unset = least-busy online node is chosen.
#   LAB_PVE_BOOTSTRAP node that answers the placement query (default 172.18.0.70 = pve1)
#   LAB_PVE_USER     ssh user on pve                    (default root, key-auth)
#   LAB_SSH_JUMP     ProxyJump host (user@addr) with a leg on VLAN19 — exec needs it;
#                    saved into the suite state at setup
#   LAB_CLOUD_IMAGE  path ON THE PVE HOST to the golden Ubuntu cloud image (required
#                    for setup; must have qemu-guest-agent baked in)
#   LAB_SSH_PUBKEY   local path to the pubkey injected via cloud-init
#                    (default: first of ~/.ssh/id_ed25519.pub, ~/.ssh/id_rsa.pub)
#   LAB_VM_CORES / LAB_VM_MEMORY / LAB_VM_DISK_GROW    (default 4 / 8192 / +40G)
#   LAB_STATE_DIR    default ~/.cache/craig-home-lab
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Any online cluster member can answer the placement query; qm create/destroy are
# node-local so we resolve an actual target node (least-busy unless LAB_PVE_HOST pins one).
LAB_PVE_BOOTSTRAP="${LAB_PVE_BOOTSTRAP:-172.18.0.70}"
PVE_HOST="${LAB_PVE_HOST:-$LAB_PVE_BOOTSTRAP}"
PVE="${LAB_PVE_USER:-root}@$PVE_HOST"
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

# Pick the least-busy online cluster node (by memory fraction) and echo its IP.
# Read-only cluster query against the bootstrap node; falls back to the bootstrap
# IP on any error so setup never hard-fails on placement.
resolve_pve_host() {
  local blob
  blob="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
      "${LAB_PVE_USER:-root}@$LAB_PVE_BOOTSTRAP" \
      'pvesh get /cluster/resources --type node --output-format json; echo __SPLIT__; pvesh get /cluster/status --output-format json' 2>/dev/null)" \
    || { echo "$LAB_PVE_BOOTSTRAP"; return; }
  PVE_BLOB="$blob" python3 - "$LAB_PVE_BOOTSTRAP" <<'PY'
import os, sys, json
fallback = sys.argv[1]
try:
    res_raw, st_raw = os.environ["PVE_BLOB"].split("__SPLIT__")
    res, st = json.loads(res_raw), json.loads(st_raw)
except Exception:
    print(fallback); sys.exit()
ip = {n["name"]: n.get("ip") for n in st if n.get("type") == "node"}
best = None
for n in res:
    if n.get("status") != "online":
        continue
    frac = n.get("mem", 0) / (n.get("maxmem", 1) or 1)
    cand = (frac, n["node"])
    if best is None or cand < best:
        best = cand
print((ip.get(best[1]) if best else None) or fallback)
PY
}

# ping timeout flag differs by platform: macOS -t = timeout, Linux -t = TTL (-W = timeout)
PING_TIMEOUT_FLAG="-W"; [ "$(uname)" = "Darwin" ] && PING_TIMEOUT_FLAG="-t"
ping_probe() { ping -c1 "$PING_TIMEOUT_FLAG" "$1" "$2" >/dev/null 2>&1; }  # $1=timeout-secs $2=addr

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

    # Placement: unless LAB_PVE_HOST pins a node, target the least-busy online
    # member so runs land off whichever node is loaded. vm-pool is shared Ceph and
    # the cloud image is present on every node, so any node can host the VM.
    if [ -z "${LAB_PVE_HOST:-}" ] && [ -z "$DRY" ]; then
      PVE_HOST="$(resolve_pve_host)"
      PVE="${LAB_PVE_USER:-root}@$PVE_HOST"
      echo "proxmox-vm: placing on least-busy node -> $PVE_HOST" >&2
    fi

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
    # Sets NEXT_VMID (no echo/subshell: $(next_vmid) would lose the `used+=`
    # bookkeeping and hand every role the same VMID).
    next_vmid() {
      local id
      for ((id = VMID_MIN; id <= VMID_MAX; id++)); do
        if ! grep -qx "$id" <<< "$used"; then
          used+=$'\n'"$id"
          NEXT_VMID="$id"
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

    # VLAN-19 static addressing. The pve host / gateway have NO L3 path into 172.19
    # (tagged VM VLAN) — only on-subnet hosts reach the guests. So readiness is NOT
    # a ping from here; we ask the QEMU guest agent (over virtio-serial, no network
    # path) to report the guest's interfaces, then confirm the assigned IP is live.
    # Requires qemu-guest-agent in the image (baked into the golden LAB_CLOUD_IMAGE)
    # and --agent 1 on the VM. Test exec then reaches guests via LAB_SSH_JUMP (a
    # ProxyJump through an on-VLAN19 runner). Static IPs stay deterministic.
    gw="${LAB_VM_GW:-172.19.0.1}"
    ns="${LAB_VM_NAMESERVER:-8.8.8.8}"
    ip_prefix="${LAB_VM_IP_PREFIX:-172.19.0}"
    ip_base_last="${LAB_VM_IP_BASE_LAST:-200}"   # poctest reserved: 172.19.0.200-254
    declare -A vmid_of addr_of ip_taken
    # Pre-seed ip_taken from OTHER suites' state files: the runner has no L3 path
    # into VLAN19, so the ping probe below can NOT see another suite's live VMs —
    # without this, two concurrent suites would both claim .200+. (Own suite's
    # stale state is skipped; it gets overwritten at the end of setup.)
    own_sf="$(state_file "$suite")"
    for other_sf in "$STATE_DIR"/*.json; do
      [ -f "$other_sf" ] || continue
      [ "$other_sf" = "$own_sf" ] && continue
      while IFS= read -r used_ip; do
        [ -n "$used_ip" ] && ip_taken[$used_ip]=1
      done < <(python3 -c '
import json, sys
for h in json.load(open(sys.argv[1])).get("hosts", {}).values():
    print(h.get("address", ""))' "$other_sf" 2>/dev/null)
    done
    idx=0
    for role in "${roles[@]}"; do
      next_vmid; vmid="$NEXT_VMID"
      name="poctest-$suite-$role"
      [ "${#name}" -le 63 ] || die "VM name too long: $name"
      # Pick a free static IP (probe locally; skip probing in dry-run). A ping probe
      # alone is NOT enough: a sibling VM created seconds ago in this same loop is
      # still running cloud-init and won't answer ping yet, so its IP would look
      # "free" — track IPs assigned this run in ip_taken and skip them.
      last=$((ip_base_last + idx)); vmip=""
      if [ -n "$DRY" ]; then
        vmip="$ip_prefix.$last"
      else
        while [ "$last" -le 254 ]; do
          cand="$ip_prefix.$last"
          [ -n "${ip_taken[$cand]:-}" ] && { last=$((last + 1)); continue; }
          ping_probe 1 "$cand" && { last=$((last + 1)); continue; }
          vmip="$cand"; break
        done
        [ -n "$vmip" ] || die "no free static IP in $ip_prefix.$ip_base_last-254"
      fi
      ip_taken[$vmip]=1
      # UEFI (ovmf) with Secure Boot NOT enforced — pre-enrolled-keys=1 blocks the
      # generic cloud image's boot chain under this OVMF (learned 2026-07-09).
      # Secure-Boot validation belongs to appliance mode (signed CanvOS image).
      # NB: stdout is the adapter's JSON contract — every mutating qm call's progress
      # ("transferred…", "generating cloud-init ISO") MUST go to stderr, or it pollutes
      # the JSON the harness parses. Only the final `echo "$json"` writes to stdout.
      pve qm create "$vmid" --name "$name" --agent 1 \
        --bios ovmf --efidisk0 vm-pool:0,efitype=4m,pre-enrolled-keys=0 \
        --cpu host --cores "${LAB_VM_CORES:-4}" --memory "${LAB_VM_MEMORY:-8192}" \
        --numa 0 --ostype l26 --scsihw virtio-scsi-single \
        --serial0 socket --net0 "virtio,bridge=vmbr0,tag=19" >&2
      pve qm set "$vmid" --scsi0 "vm-pool:0,import-from=$LAB_CLOUD_IMAGE,iothread=1,backup=0" >&2
      pve qm set "$vmid" --ide2 vm-pool:cloudinit --ciuser ubuntu \
        --sshkeys "$remote_key" --ipconfig0 "ip=$vmip/24,gw=$gw" --nameserver "$ns" >&2
      # Fixed boot order HDD;CD;NET (disk first — import defaults boot to net0, which
      # loops a reinstall). Set AFTER ide2 exists so all referenced devices resolve.
      # NB: pve() flattens args over ssh, so the ';' must be quoted for the REMOTE
      # shell (embedded single-quotes) or it splits into bogus commands.
      pve qm set "$vmid" --boot "'order=scsi0;ide2;net0'" >&2
      pve qm disk resize "$vmid" scsi0 "${LAB_VM_DISK_GROW:-+40G}" >&2
      pve qm start "$vmid" >&2
      [ -n "$DRY" ] || ssh-keygen -R "$vmip" >/dev/null 2>&1 || true  # reused IPs churn host keys
      vmid_of[$role]="$vmid"
      addr_of[$role]="$vmip"
      idx=$((idx + 1))
    done

    # Readiness via the guest agent (virtio-serial — needs no VLAN19 path). Wait up to
    # ~5 min for the agent to report a non-loopback IPv4. Prefer the assigned static;
    # if the guest came up on a different IP (e.g. DHCP), adopt what the agent reports.
    if [ -n "$DRY" ]; then
      for role in "${roles[@]}"; do
        echo "DRYRUN wait-for-agent vmid=${vmid_of[$role]} role=$role ip=${addr_of[$role]}" >&2
      done
    else
      for role in "${roles[@]}"; do
        vmid="${vmid_of[$role]}"; got=""
        for _ in $(seq 1 60); do
          blob="$(pve qm agent "$vmid" network-get-interfaces 2>/dev/null)" || blob=""
          if [ -n "$blob" ]; then
            got="$(printf '%s' "$blob" | AGENT_WANT="${addr_of[$role]}" python3 -c '
import os, sys, json
want = os.environ.get("AGENT_WANT")
try: data = json.load(sys.stdin)
except Exception: sys.exit()
found = []
for i in data:
    if i.get("name") == "lo": continue
    for a in (i.get("ip-addresses") or []):
        if a.get("ip-address-type") == "ipv4": found.append(a["ip-address"])
print(want if want in found else (found[0] if found else ""))
')"
            [ -n "$got" ] && break
          fi
          sleep 5
        done
        [ -n "$got" ] || die "vm ${vmid_of[$role]} ($role) agent never reported an IPv4 (guest network down?)"
        if [ "$got" != "${addr_of[$role]}" ]; then
          echo "proxmox-vm: $role up on $got (assigned ${addr_of[$role]}) — adopting agent-reported IP" >&2
          addr_of[$role]="$got"
        fi
      done
    fi

    # State (vmids/ips/roles + placement/jump — no secrets), then the contract JSON.
    json="{\"adapter\": \"craig-home-lab/proxmox-vm\", \"pve_host\": \"$PVE_HOST\", \"ssh_jump\": \"${LAB_SSH_JUMP:-}\", \"hosts\": {"
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
    # Guests live on VLAN19 which this host can not route to directly — hop through
    # an on-subnet runner. LAB_SSH_JUMP overrides; else use the value saved at setup.
    jump="${LAB_SSH_JUMP:-$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1])).get("ssh_jump", ""))' "$sf")}"
    jump_opt=(); [ -n "$jump" ] && jump_opt=(-J "$jump")
    if [ -n "$DRY" ]; then
      echo "DRYRUN ssh ${jump_opt[@]+"${jump_opt[@]}"} $user@$addr 'bash -s' < $script" >&2
      exit 0
    fi
    # Ephemeral throwaway VMs on reused static IPs — don't pollute/conflict known_hosts.
    # (${arr[@]+...} guard: empty-array expansion under set -u errors on bash 3.2/macOS,
    # same idiom as the suites loop in teardown.)
    ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      ${jump_opt[@]+"${jump_opt[@]}"} "$user@$addr" 'bash -s' < "$script"
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
    # Delete Palette clusters/edge hosts FIRST, while the VMs are still ALIVE, so the
    # cluster can drain+deprovision the node cleanly. Destroying the VM first wedges the
    # cluster in "Deleting" (force-delete then blocked 15 min) and orphans the edge host.
    # palette-cleanup blocks until the clusters are gone. (learned 2026-07-10)
    "$SCRIPT_DIR/../palette-cleanup.sh" || echo "warn: palette-cleanup failed (rerun manually)" >&2
    for suite in ${suites[@]+"${suites[@]}"}; do
      sf="$(state_file "$suite")"
      [ -f "$sf" ] || continue
      # Target the node the VMs were created on (qm is node-local; a VM on pve2 is
      # invisible to qm on pve1). Fall back to the current PVE if unrecorded.
      sf_host="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("pve_host",""))' "$sf" 2>/dev/null)"
      [ -n "$sf_host" ] && PVE="${LAB_PVE_USER:-root}@$sf_host"
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
    ;;

  *)
    die "usage: proxmox-vm.sh {setup --suite F | exec <host> <script> | teardown [--suite F]}"
    ;;
esac
