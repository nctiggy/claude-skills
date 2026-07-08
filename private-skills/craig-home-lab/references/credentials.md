# Credentials — 1Password service-account access (references only)

**Rule: this file holds item IDs and `op read` paths — never actual secret values.**
Secrets are resolved at call time with `op read` and passed via env; nothing lands on disk.

## Service-account tokens

`~/code/customer-opportunities/.env` exports two service-account tokens (gitignored;
carried into worktrees by `.worktreeinclude`):

| Env var | Vault | Holds |
|---|---|---|
| `OP_SERVICE_K8S_ACCOUNT_TOKEN` | `k8s` | Palette API keys per tenant, misc infra keys |
| `OP_SERVICE_LOBSTER_ACCOUNT_TOKEN` | `Lobster` | Proxmox root, personal-infra items |

Usage pattern (service accounts need `--vault` on `op item` commands):

```bash
source ~/code/customer-opportunities/.env
OP_SERVICE_ACCOUNT_TOKEN="$OP_SERVICE_K8S_ACCOUNT_TOKEN" op read 'op://k8s/<item>/password'
```

## Known item paths

| What | op read path |
|---|---|
| Palette API key — custeng-prod tenant | `op://k8s/xcgzcp2hzkdvjd35d4aj3e6vky/password` |
| Palette API key — other tenants | `op item list --vault k8s` (e.g. "Spectro API Key", "Mouser Palette API Key") |
| Proxmox root (pve1-3) | `op://Lobster/s6i4mdfbma6owp44gboncbmdtm/password` |
| AMT admin (node11-13) | in `k8s` vault — `op item list --vault k8s` to locate |
| Cloudflare API token (Pages/Access) | look up with `op item list` (vault `k8s` or `Lobster`) — record the item ID here once confirmed |

## How the lab adapter resolves keys

`lab-adapter.sh env` emits, in order of preference:

1. `PALETTE_API_KEY` — from the environment if already set, else
   `op read "op://k8s/${LAB_PALETTE_KEY_ITEM:-xcgzcp2hzkdvjd35d4aj3e6vky}/password"`
   using `OP_SERVICE_K8S_ACCOUNT_TOKEN`.
2. `PROJECT_UID` — from `LAB_PROJECT_UID` (must be exported; the adapter never guesses
   a project, and `references/project-denylist.txt` UIDs are refused).

Proxmox root for the proxmox-vm provider comes from `op read` the same way
(`LAB_PROXMOX_PW_ITEM` overrides the default Lobster item) — prefer SSH keys where
installed; the password path is the fallback.
