#!/usr/bin/env bash
# cf_access_gate.sh — ensure a Cloudflare Access (Zero Trust) one-time-PIN app gates a
# Pages project on BOTH its apex hostname and its preview-URL wildcard.
#
#   cf_access_gate.sh --project <pages-project> --domains "customer.com spectrocloud.com"
#
# THE GOTCHA THIS SCRIPT EXISTS FOR: every `wrangler pages deploy` also serves the site
# at https://<hash>.<project>.pages.dev. An Access app on <project>.pages.dev alone
# leaves every one of those preview hostnames world-readable. The app must include the
# wildcard *.<project>.pages.dev as well.
#
# Idempotent: finds an existing app for the apex domain and updates it, else creates one.
# Requires: CLOUDFLARE_API_TOKEN (Access: Edit), CLOUDFLARE_ACCOUNT_ID, curl, python3.
set -euo pipefail

PROJECT="" DOMAINS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --domains) DOMAINS="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
[ -n "$PROJECT" ] && [ -n "$DOMAINS" ] || { echo "usage: cf_access_gate.sh --project NAME --domains \"d1 d2\"" >&2; exit 2; }
: "${CLOUDFLARE_API_TOKEN:?set CLOUDFLARE_API_TOKEN (Access: Edit)}"
: "${CLOUDFLARE_ACCOUNT_ID:?set CLOUDFLARE_ACCOUNT_ID}"

API="https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/access"
AUTH=(-H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" -H "Content-Type: application/json")
APEX="$PROJECT.pages.dev"
WILDCARD="*.$PROJECT.pages.dev"

json_get() { python3 -c 'import json,sys; d=json.load(sys.stdin); print(eval(sys.argv[1], {"d": d}))' "$1"; }

# 1) Find existing app whose domain matches the apex.
app_id=$(curl -fsS "${AUTH[@]}" "$API/apps?per_page=100" | python3 -c '
import json, sys
apex = sys.argv[1]
apps = json.load(sys.stdin).get("result") or []
for a in apps:
    domains = set(a.get("self_hosted_domains") or []) | {a.get("domain", "")}
    if apex in domains:
        print(a["id"]); break
' "$APEX")

app_body=$(python3 -c '
import json, sys
apex, wildcard = sys.argv[1], sys.argv[2]
print(json.dumps({
    "name": apex,
    "type": "self_hosted",
    "domain": apex,
    "self_hosted_domains": [apex, wildcard],
    "session_duration": "24h",
}))' "$APEX" "$WILDCARD")

if [ -n "$app_id" ]; then
  echo "updating Access app $app_id ($APEX + $WILDCARD)"
  curl -fsS -X PUT "${AUTH[@]}" "$API/apps/$app_id" -d "$app_body" | json_get 'd["success"]' >/dev/null
else
  echo "creating Access app ($APEX + $WILDCARD)"
  app_id=$(curl -fsS -X POST "${AUTH[@]}" "$API/apps" -d "$app_body" | json_get 'd["result"]["id"]')
fi
[ -n "$app_id" ] || { echo "failed to create/find Access app" >&2; exit 1; }

# 2) Ensure an allow policy for the domains (one-time PIN is Access's default login
#    method when no other IdP is configured).
policy_body=$(python3 -c '
import json, sys
domains = sys.argv[1].split()
print(json.dumps({
    "name": "allow-" + "-".join(domains),
    "decision": "allow",
    "include": [{"email_domain": {"domain": d}} for d in domains],
}))' "$DOMAINS")

existing_policy=$(curl -fsS "${AUTH[@]}" "$API/apps/$app_id/policies" | python3 -c '
import json, sys
pols = json.load(sys.stdin).get("result") or []
print(pols[0]["id"] if pols else "")')

if [ -n "$existing_policy" ]; then
  echo "updating policy $existing_policy (allow: $DOMAINS via one-time PIN)"
  curl -fsS -X PUT "${AUTH[@]}" "$API/apps/$app_id/policies/$existing_policy" -d "$policy_body" >/dev/null
else
  echo "creating policy (allow: $DOMAINS via one-time PIN)"
  curl -fsS -X POST "${AUTH[@]}" "$API/apps/$app_id/policies" -d "$policy_body" >/dev/null
fi

echo "gated: $APEX and $WILDCARD -> emails ending in: $DOMAINS"
echo "now PROVE it: verify_gating.sh --project $PROJECT"
