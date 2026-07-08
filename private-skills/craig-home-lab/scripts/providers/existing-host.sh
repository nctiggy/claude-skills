#!/usr/bin/env bash
# existing-host.sh — lab-adapter provider that maps suite roles to hosts YOU name.
# No provisioning, no infrastructure teardown; teardown only cleans up poctest-
# Palette resources (clusters/edge hosts) via palette-cleanup.sh.
#
#   export LAB_HOSTS="node=ubuntu@172.19.0.31,worker=ubuntu@172.19.0.32"
#
# Roles must cover the suite's adapter_requirements.hosts. The runner never sends
# host "local" to an adapter.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMD="${1:-}"; shift || true

die() { echo "existing-host: $*" >&2; exit 1; }

parse_hosts() {  # prints "role user addr" lines
  [ -n "${LAB_HOSTS:-}" ] || die 'LAB_HOSTS not set (e.g. "node=ubuntu@172.19.0.31,...")'
  IFS=',' read -ra pairs <<< "$LAB_HOSTS"
  for pair in "${pairs[@]}"; do
    role="${pair%%=*}"; target="${pair#*=}"
    user="${target%%@*}"; addr="${target#*@}"
    [ -n "$role" ] && [ -n "$user" ] && [ -n "$addr" ] && [ "$user" != "$addr" ] \
      || die "bad LAB_HOSTS entry: $pair (want role=user@addr)"
    echo "$role $user $addr"
  done
}

target_for() {  # role -> user@addr
  local role="$1"
  while read -r r u a; do
    if [ "$r" = "$role" ]; then echo "$u@$a"; return 0; fi
  done < <(parse_hosts)
  die "role $role not in LAB_HOSTS"
}

case "$CMD" in
  setup)
    json='{"adapter": "craig-home-lab/existing-host", "hosts": {'
    first=1
    while read -r role user addr; do
      [ $first -eq 0 ] && json+=', '
      json+="\"$role\": {\"address\": \"$addr\", \"user\": \"$user\"}"
      first=0
    done < <(parse_hosts)
    json+='}}'
    echo "$json"
    ;;
  exec)
    role="${1:?exec needs <host>}"; script="${2:?exec needs <script>}"
    [ -f "$script" ] || die "no such script: $script"
    target="$(target_for "$role")"
    if [ -n "${LAB_DRYRUN:-}" ]; then
      echo "DRYRUN ssh $target 'bash -s' < $script" >&2
      exit 0
    fi
    ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$target" 'bash -s' < "$script"
    ;;
  teardown)
    # Idempotent; infra untouched — only poctest- Palette resources are removed.
    "$SCRIPT_DIR/../palette-cleanup.sh" || die "palette-cleanup failed"
    ;;
  *)
    die "usage: existing-host.sh {setup|exec <host> <script>|teardown}"
    ;;
esac
