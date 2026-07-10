# Saving the check-in to PulseCheck

Full API reference: https://pulsecheck-docs.pages.dev/

## Two surfaces, two auths

| Surface | Host | Auth | Can write? |
|---|---|---|---|
| Reporting API | `api.pulsecheck.spectrocloud.com` | OAuth2 Bearer from a `pca_`/`psk_` key pair | **No — read-only.** Use it only to look up the current `cycle_id`. |
| App API | `pulsecheck.spectrocloud.com` (Remix `.data` routes) | Session cookie `__pulse_session` via Okta/Google SSO | **Yes — the only write path.** |

Always write with `intent=draft`. Use `intent=submit` only on explicit user
instruction in the current conversation.

## Step 1 — Get the current cycle (Reporting API)

Credentials: the `pca_`/`psk_` key pair lives in the 1Password **Lobster**
vault, item **"Pulsecheck API Token"** (username = `pca_` client_id,
password = `psk_` client_secret). The 1Password service-account token is in
`~/code/customer-opportunities/.env` as `OP_SERVICE_LOBSTER_ACCOUNT_TOKEN`
(lines may be `export`-prefixed).

```bash
# Load the 1Password service-account token (handles optional `export ` prefix)
export OP_SERVICE_ACCOUNT_TOKEN=$(grep OP_SERVICE_LOBSTER_ACCOUNT_TOKEN ~/code/customer-opportunities/.env \
  | sed 's/^export //' | cut -d= -f2- | tr -d '"')

CLIENT_ID=$(op item get "Pulsecheck API Token" --vault Lobster --fields username)
CLIENT_SECRET=$(op item get "Pulsecheck API Token" --vault Lobster --fields password --reveal)

# Exchange for a bearer token
ACCESS_TOKEN=$(curl -s -X POST https://api.pulsecheck.spectrocloud.com/auth/token \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}" \
  | jq -r '.access_token')

# Current cycle is the first element
CYCLE=$(curl -s https://api.pulsecheck.spectrocloud.com/api/v1/cycles \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" | jq -r '.cycles[0].cycle_id')
echo "Current cycle: ${CYCLE}"
```

## Step 2 — Get the `__pulse_session` cookie (once)

There is no token grant for the App API — the cookie comes from a real SSO
login. Do this once in a **headed** browser and persist the session:

- Run a headed Playwright login to `https://pulsecheck.spectrocloud.com`
  (Okta/Google SSO), let the user complete the sign-in, then save
  `storageState` to `~/.pulsecheck/pulse-auth.json` and `chmod 600` it.
- Reuse that state on later runs until it expires; **treat the file like a
  password** — never print the cookie value, never commit it, never copy it
  into a routine or prompt.

```bash
mkdir -p ~/.pulsecheck && chmod 700 ~/.pulsecheck
# ...after Playwright saves storageState to ~/.pulsecheck/pulse-auth.json:
chmod 600 ~/.pulsecheck/pulse-auth.json

# Extract the cookie value for curl
PULSE_COOKIE=$(jq -r '.cookies[] | select(.name=="__pulse_session") | .value' \
  ~/.pulsecheck/pulse-auth.json)
```

## Step 3 — POST the draft (App API)

Field mapping: `accomplishments` = Q1 (rich-text HTML), `upcoming` = Q2
(plain text), `blockers` = Q3 (rich-text HTML).

```bash
curl -s -i "https://pulsecheck.spectrocloud.com/my-check-in.data?cycle=${CYCLE}&edit=1" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H "Cookie: __pulse_session=${PULSE_COOKIE}" \
  --data-urlencode "accomplishments=<ul><li>Shipped X — <a href=\"...\">ticket</a></li></ul>" \
  --data-urlencode "upcoming=Finish Y; start Z (contingent on the security sign-off)." \
  --data-urlencode "blockers=No blockers this week." \
  --data-urlencode "intent=draft"
```

Interpreting the response:

- **Saved:** a non-redirect `202` with the header `x-remix-response: yes`.
- **Cookie expired:** a `SingleFetchRedirect` to `/sign-in` — re-run the
  headed SSO login (Step 2) and retry.

## Unattended / cowork runs

Respect the routine's chosen mode. In **draft** mode, don't write to
PulseCheck — deliver the drafted Q1/Q2/Q3 answers plus the evidence appendix
and stop. In **submit** mode, POST with `intent=submit` — but only if a
session cookie is available at run time. A pure cloud routine has no access to
the local `~/.pulsecheck/pulse-auth.json` cookie, so if none is present, fall
back to delivering the finished answers for one-step submission rather than
failing. Never store the session cookie inside a routine definition or its
prompt.
