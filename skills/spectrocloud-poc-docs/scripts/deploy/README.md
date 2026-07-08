# Deploy provider interface

Publishing is abstracted behind providers so the pipeline never hardcodes a host.
A provider is one executable, `scripts/deploy/<provider>.sh`, implementing:

```
<provider>.sh deploy --site-dir <docs-site> [--config <deploy.yaml>]
    Build (mkdocs build --strict) and publish the site. Exit 0 on success.

<provider>.sh gate   --site-dir <docs-site> [--config <deploy.yaml>]
    Idempotently ensure access gating exists (who may read the site).
    Safe to run repeatedly.

<provider>.sh verify --site-dir <docs-site> [--config <deploy.yaml>]
    Prove the gating actually works — on EVERY hostname the platform serves,
    including wildcard/preview hostnames. Exit 0 only if nothing is public.
```

`--config` defaults to `<site-dir>/deploy.yaml`:

```yaml
provider: cf-pages
project: acme-docs
site_title: "Acme POC Guide"
allowed_domains:
  - acme.com
  - spectrocloud.com
```

**A deployment is not done until `verify` passes.** The canonical failure mode:
gating the apex hostname but not the per-deployment preview hostnames — the site
looks locked while every preview URL is world-readable.

Providers shipped here:

| Provider | Status | Notes |
|---|---|---|
| `cf-pages.sh` | full | Cloudflare Pages + Access one-time-PIN gating; helpers `cf_access_gate.sh`, `verify_gating.sh` |
| `self-hosted.sh` | documented stub | for a rsync/SSH docs host with its own OTP auth; adapt to your stack |

To add a provider: copy `self-hosted.sh`, implement the three subcommands, keep the
exit-code semantics, and select it via `provider:` in `deploy.yaml`.
