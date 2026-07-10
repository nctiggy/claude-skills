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
clusters=$(curl -fsS -X POST "${hdr[@]}" \
  "$API/v1/dashboard/spectroclusters/search?limit=50" \
  -d '{"filter":{"conjunction":"and","filterGroups":[]},"sort":[]}' \
  | jq -r '.items[]? | select(.metadata.name | startswith("poctest-"))
           | "\(.metadata.uid) \(.metadata.name)"')
if [ -n "$clusters" ]; then
  while read -r uid name; do
    del cluster "$uid" "$name" "/v1/spectroclusters/$uid"
  done <<< "$clusters"
else
  echo "no poctest- clusters in project $PROJECT_UID"
fi

# 2) Edge hosts named poctest-* (delete after their clusters).
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
