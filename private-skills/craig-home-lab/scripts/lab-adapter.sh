#!/usr/bin/env bash
# lab-adapter.sh — Craig's home-lab implementation of the spectrocloud-poc-docs
# LAB ADAPTER contract (setup | env | exec | teardown).
#
#   run_doc_tests.py --adapter .../craig-home-lab/scripts/lab-adapter.sh --suite ...
#
# Providers (selected with LAB_PROVIDER, default existing-host):
#   existing-host   no provisioning; roles map to hosts named in LAB_HOSTS
#   proxmox-vm      ephemeral Ubuntu cloud-image VMs on pve1 (VMID 900-999, poctest- names)
#
# Common env:
#   LAB_PROVIDER      existing-host | proxmox-vm
#   LAB_PROJECT_UID   Palette project UID for the POC (REQUIRED; denylist-checked)
#   LAB_DRYRUN=1      print every mutating command instead of executing (providers honor it)
#   LAB_STATE_DIR     default ~/.cache/craig-home-lab (holds only vmids/ips/roles — no secrets)
#
# SAFETY RAILS (see SKILL.md): poctest- prefix, VMID 900-999, project denylist,
# secrets via `op read` only, lab hosts only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROVIDER="${LAB_PROVIDER:-existing-host}"
PROVIDER_SH="$SCRIPT_DIR/providers/$PROVIDER.sh"
DENYLIST="$SKILL_DIR/references/project-denylist.txt"

die() { echo "lab-adapter: $*" >&2; exit 1; }

check_project_denylist() {
  [ -n "${LAB_PROJECT_UID:-}" ] || return 0
  if [ -f "$DENYLIST" ] && grep -v '^\s*#' "$DENYLIST" | grep -qx "$LAB_PROJECT_UID"; then
    die "REFUSED: LAB_PROJECT_UID $LAB_PROJECT_UID is on references/project-denylist.txt"
  fi
}

resolve_palette_key() {
  if [ -n "${PALETTE_API_KEY:-}" ]; then
    printf '%s' "$PALETTE_API_KEY"
    return
  fi
  # shellcheck disable=SC1090
  [ -f "$HOME/code/customer-opportunities/.env" ] && source "$HOME/code/customer-opportunities/.env"
  [ -n "${OP_SERVICE_K8S_ACCOUNT_TOKEN:-}" ] || die "no PALETTE_API_KEY and no OP_SERVICE_K8S_ACCOUNT_TOKEN (source customer-opportunities/.env)"
  command -v op >/dev/null || die "1Password CLI (op) not installed"
  OP_SERVICE_ACCOUNT_TOKEN="$OP_SERVICE_K8S_ACCOUNT_TOKEN" \
    op read "op://k8s/${LAB_PALETTE_KEY_ITEM:-xcgzcp2hzkdvjd35d4aj3e6vky}/password" \
    || die "op read of Palette API key failed"
}

CMD="${1:-}"
shift || true

case "$CMD" in
  setup|teardown)
    [ -x "$PROVIDER_SH" ] || die "unknown provider: $PROVIDER ($PROVIDER_SH missing)"
    check_project_denylist
    exec "$PROVIDER_SH" "$CMD" "$@"
    ;;
  exec)
    [ -x "$PROVIDER_SH" ] || die "unknown provider: $PROVIDER ($PROVIDER_SH missing)"
    exec "$PROVIDER_SH" exec "$@"
    ;;
  env)
    check_project_denylist
    [ -n "${LAB_PROJECT_UID:-}" ] || die "LAB_PROJECT_UID must be exported (the adapter never guesses a project)"
    key="$(resolve_palette_key)"
    [ -n "$key" ] || die "empty Palette API key"
    echo "PALETTE_API_KEY=$key"
    echo "PROJECT_UID=$LAB_PROJECT_UID"
    ;;
  *)
    echo "usage: lab-adapter.sh {setup [--suite F] | env | exec <host> <script> | teardown [--suite F]}" >&2
    exit 2
    ;;
esac
