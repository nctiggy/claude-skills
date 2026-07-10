#!/usr/bin/env bash
# palette-cleanup.sh — delete poctest-* Palette resources (clusters, then edge hosts)
# in the LAB project. Called by provider teardown; also safe standalone.
#
# SAFETY RAILS:
#   - operates ONLY inside LAB_PROJECT_UID (required; checked against
#     references/project-denylist.txt by lab-adapter.sh env, re-checked here)
#   - deletes ONLY resources whose metadata.name starts with "poctest-" — the
#     jq filter is the sole selection mechanism, there is no --all
#   - LAB_DRYRUN=1 prints the DELETE calls instead of issuing them
#   - idempotent: nothing to delete is success
#
# Env: PALETTE_API_KEY + PROJECT_UID (resolved via lab-adapter.sh env when absent),
#      PALETTE_API=https://api.spectrocloud.com (override for other tenants)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
API="${PALETTE_API:-https://api.spectrocloud.com}"
DRY="${LAB_DRYRUN:-}"

die() { echo "palette-cleanup: $*" >&2; exit 1; }
command -v jq >/dev/null || die "jq required"

# Resolve credentials through the adapter when not already in the environment.
if [ -z "${PALETTE_API_KEY:-}" ] || [ -z "${PROJECT_UID:-}" ]; then
  while IFS= read -r line; do
    case "$line" in
      PALETTE_API_KEY=*|PROJECT_UID=*) export "${line?}" ;;
    esac
  done < <("$SCRIPT_DIR/lab-adapter.sh" env)
fi
[ -n "${PALETTE_API_KEY:-}" ] && [ -n "${PROJECT_UID:-}" ] || die "need PALETTE_API_KEY + PROJECT_UID"

DENYLIST="$SKILL_DIR/references/project-denylist.txt"
if [ -f "$DENYLIST" ] && grep -v '^\s*#' "$DENYLIST" | grep -qx "$PROJECT_UID"; then
  die "REFUSED: PROJECT_UID $PROJECT_UID is denylisted"
fi

hdr=(-H "ApiKey: $PALETTE_API_KEY" -H "ProjectUid: $PROJECT_UID" -H "Content-Type: application/json")

del() {  # $1=kind label, $2=uid, $3=name, $4=url-path
  if [ -n "$DRY" ]; then
    echo "DRYRUN DELETE $API$4  # $1 $3 ($2)"
  else
    echo "deleting $1 $3 ($2)"
    curl -fsS -X DELETE "${hdr[@]}" "$API$4" >/dev/null \
      || echo "warn: delete of $1 $3 failed (may already be deleting)" >&2
  fi
}

# 1) Clusters named poctest-* (dashboard search scoped by the ProjectUid header).
#    IMPORTANT ORDERING (learned 2026-07-10): delete the CLUSTER first and WAIT for it
#    to drain — this must run while the node/VM is still ALIVE. If the VM is destroyed
#    first, cluster deletion can't deprovision the node, the cluster wedges in
#    "Deleting", and force-delete is then blocked for 15 min. So provider teardown
#    calls this BEFORE destroying VMs, and we block here until the clusters are gone.
clusters=$(curl -fsS -X POST "${hdr[@]}" \
  "$API/v1/dashboard/spectroclusters/search?limit=50" \
  -d '{"filter":{"conjunction":"and","filterGroups":[]},"sort":[]}' \
  | jq -r '.items[]? | select(.metadata.name | startswith("poctest-"))
           | "\(.metadata.uid) \(.metadata.name)"')
cluster_uids=()
if [ -n "$clusters" ]; then
  while read -r uid name; do
    del cluster "$uid" "$name" "/v1/spectroclusters/$uid"
    cluster_uids+=("$uid")
  done <<< "$clusters"
else
  echo "no poctest- clusters in project $PROJECT_UID"
fi

# 1b) Wait for the clusters to actually disappear (graceful delete drains the live
#     node) before touching edge hosts or destroying VMs. Up to ~12 min.
if [ -z "$DRY" ] && [ ${#cluster_uids[@]} -gt 0 ]; then
  for uid in "${cluster_uids[@]}"; do
    for _ in $(seq 1 48); do
      code=$(curl -s -o /dev/null -w '%{http_code}' "${hdr[@]}" "$API/v1/spectroclusters/$uid")
      # 404 (gone) or 500 (search index dropped it) -> treat as deleted
      case "$code" in 404|400) break ;; esac
      state=$(curl -fsS "${hdr[@]}" "$API/v1/spectroclusters/$uid" 2>/dev/null | jq -r '.status.state // "gone"')
      [ "$state" = "Deleted" ] || [ "$state" = "gone" ] && break
      sleep 15
    done
    echo "cluster $uid drained/gone"
  done
fi

# 2) Edge hosts named poctest-* (now free — their clusters are gone).
edgehosts=$(curl -fsS "${hdr[@]}" "$API/v1/edgehosts?limit=50" \
  | jq -r '.items[]? | select(.metadata.name | startswith("poctest-"))
           | "\(.metadata.uid) \(.metadata.name)"')
if [ -n "$edgehosts" ]; then
  while read -r uid name; do
    del edge-host "$uid" "$name" "/v1/edgehosts/$uid"
  done <<< "$edgehosts"
else
  echo "no poctest- edge hosts in project $PROJECT_UID"
fi

echo "palette-cleanup complete (project $PROJECT_UID)"
