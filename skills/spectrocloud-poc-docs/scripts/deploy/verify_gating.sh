#!/usr/bin/env bash
# verify_gating.sh — prove a Cloudflare Pages site is actually gated, on the apex
# hostname AND on a preview-style wildcard hostname.
#
#   verify_gating.sh --project <pages-project> [--extra-host <hostname>]
#
# A hostname counts as GATED when an unauthenticated request is redirected to
# Cloudflare Access (Location contains cloudflareaccess.com) — anything that
# returns page content (2xx) is OPEN and fails the check. Exit 0 only if every
# probed hostname is gated.
set -euo pipefail

PROJECT="" EXTRA=""
while [ $# -gt 0 ]; do
  case "$1" in
    --project)    PROJECT="$2"; shift 2 ;;
    --extra-host) EXTRA="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
[ -n "$PROJECT" ] || { echo "usage: verify_gating.sh --project NAME [--extra-host HOST]" >&2; exit 2; }

# A synthetic preview-style hostname: real preview URLs look like
# <deployment-hash>.<project>.pages.dev; any subdomain exercises the same
# wildcard route, so an ungated wildcard shows up here as page content.
PROBES=("$PROJECT.pages.dev" "poc-gating-probe.$PROJECT.pages.dev")
[ -n "$EXTRA" ] && PROBES+=("$EXTRA")

fail=0
for host in "${PROBES[@]}"; do
  headers=$(curl -sSI --max-time 20 "https://$host/" 2>/dev/null || true)
  status=$(printf '%s' "$headers" | awk 'NR==1 {print $2}')
  location=$(printf '%s' "$headers" | awk 'tolower($1)=="location:" {print $2}' | tr -d '\r')

  if printf '%s' "$location" | grep -qi 'cloudflareaccess\.com'; then
    echo "GATED  $host (HTTP $status -> Access login)"
  elif [ -z "$status" ]; then
    echo "??     $host — no response (DNS/network); treating as failure" >&2
    fail=1
  elif [ "${status:0:1}" = "2" ]; then
    echo "OPEN   $host (HTTP $status — serving content WITHOUT authentication)" >&2
    fail=1
  else
    echo "OPEN?  $host (HTTP $status, no Access redirect — inspect manually)" >&2
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo
  echo "GATING VERIFICATION FAILED — do not share this URL with the customer." >&2
  echo "Most common cause: the Access app covers $PROJECT.pages.dev but not" >&2
  echo "*.$PROJECT.pages.dev — run cf_access_gate.sh again (it sets both)." >&2
  exit 1
fi
echo
echo "gating verified on all probed hostnames — safe to share https://$PROJECT.pages.dev"
