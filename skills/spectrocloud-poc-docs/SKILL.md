---
name: spectrocloud-poc-docs
description: >-
  Build, test, and publish prospect-facing self-guided POC/POV guide sites for Spectro Cloud
  Palette. Full lifecycle - intake, scaffold an MkDocs Material site, author phased guides
  grounded in the spectrocloud-* technical skills, static QA (secret scan, link/anchor check,
  fence lint), optional live execution of annotated command blocks through a pluggable lab
  adapter, a critic loop, and gated publishing through a pluggable deploy provider (Cloudflare
  Pages with Access OTP gating is the default). Use when a prospect needs a step-by-step POC
  guide site, when asked to "packify" or productize POC docs, or to verify a guide's commands
  actually work before sending it to a customer.
---

# Spectro Cloud POC Docs — Build → Test → Publish

Produce a **prospect-facing, self-guided POC guide site** (MkDocs Material → gated hosting)
whose commands are **provably correct**: every critical step can carry a machine-readable
test annotation and be executed end-to-end in a lab before the customer ever sees it.

Canonical exemplars of the output: `firmus/docs-site/` and `ge-healthcare/docs-site/` in the
customer-opportunities repo — phased guides (single-node → multi-node → programmatic →
appliance) with UI/API tabs, mermaid flow, sharp-edge admonitions, and a support page.

## Compose, don't duplicate

READ these skills before authoring — this skill owns the *lifecycle*, they own the *content*:

| Skill | What you take from it |
|---|---|
| `docs-site-generator` | MkDocs Material config, brand CSS, logo assets, page conventions |
| `spectrocloud-brand` | Colors, typography, tone for anything customer-facing |
| `spectrocloud-agent-mode` / `spectrocloud-appliance-mode` | Accurate edge install/registration steps |
| `spectrocloud-clusters` / `spectrocloud-cluster-profiles` / `spectrocloud-common` | Accurate API payloads, profile/pack workflows, project lookup |
| `spectrocloud-packs` / `spectrocloud-troubleshooting` | Pack gotchas and "if it stalls" guidance |

Never write a Palette command from memory when one of those skills documents it.

## Pipeline

1. **Intake** — customer name, use case, phases, deployment modes, what hardware/tenant the
   prospect has. Decide page plan (see `references/authoring-guide.md`).
2. **Scaffold** — `scripts/scaffold_poc_site.sh <dest> --site-name "..." --project <cf-name>`
   renders `references/templates/` into a ready-to-edit site.
3. **Author** — write the guides per `references/authoring-guide.md`. Annotate testable
   command blocks with `poc-test` comments as you go (`references/testing.md`).
4. **Static QA (T0/T1, always)** — `scripts/check_docs.py <docs-site>` : mkdocs `--strict`
   build, fence-language lint, internal link + anchor check on built HTML, step-numbering
   check, **secret scan** (no `op://`, private/lab IPs, API keys, internal hostnames in
   customer docs). Then `scripts/extract_tests.py --suite <docs-site>/poc-test-suite.yaml`
   lints the test annotations against the suite.
5. **Live test (T2, optional but preferred)** — `scripts/run_doc_tests.py` executes the
   annotated blocks in order through a **lab adapter** (see the adapter contract in
   `references/testing.md`; a mock adapter ships in `scripts/adapters/mock/`). A site that
   skips T2 gets stamped **UNTESTED** in its report — say so honestly in handoff notes.
6. **Critic loop** — two review passes before publish (`references/critic-loop.md`).
7. **Publish** — `mkdocs build --strict`, then deploy through a **deploy provider**
   (`scripts/deploy/<provider>.sh` — default `cf-pages.sh`). Deployment is **not done**
   until access gating is verified on the apex *and* wildcard/preview hostnames
   (`references/publishing.md` — the preview-URL leak is the classic mistake).

## Hard rules

- **Secret hygiene**: customer-facing docs never contain `op://` refs, 1Password items,
  RFC-1918 *lab* addresses, internal hostnames, real API keys, or wsman credential strings.
  `check_docs.py` enforces this — a finding is a blocker, not a warning.
- **No unverified caveats**: instead of writing "verify this in your tenant", annotate the
  block with a `poc-test` assert and actually run it (or mark the site UNTESTED).
- **Gate before you share**: never send a URL to a prospect until `deploy/<provider>.sh verify`
  passes. Public-by-default hosting + preview URLs are how internal drafts leak.
- **Placeholders look like placeholders**: `<registration-token>`, `$PALETTE_API_KEY`,
  `<your-project-name>` — never a value that could be mistaken for (or actually be) real.

## References

- `references/authoring-guide.md` — page plan, phased-guide structure, tabs/admonitions/mermaid conventions, grounding rules
- `references/testing.md` — T0–T2 tiers, `poc-test` annotation spec, suite manifest, **lab-adapter contract**, runner usage
- `references/publishing.md` — deploy-provider interface, cf-pages + OTP gating, wildcard/preview gotcha, self-hosted stub
- `references/critic-loop.md` — the two-pass review protocol
- `references/templates/` — canonical mkdocs.yml, brand.css, wrangler.toml, page skeletons, suite manifest

## Scripts

| Script | Purpose |
|---|---|
| `scripts/scaffold_poc_site.sh` | Render templates into a new docs-site |
| `scripts/check_docs.py` | T0 static QA (build, links, fences, steps, secret scan) |
| `scripts/extract_tests.py` | Parse + lint `poc-test` annotations (T1); also a library for the runner |
| `scripts/run_doc_tests.py` | T2 live runner — executes annotated blocks via a lab adapter |
| `scripts/adapters/mock/mock-adapter.sh` | Reference adapter implementation; used by the self-tests |
| `scripts/deploy/cf-pages.sh` | Default deploy provider (wrangler + Access OTP gate + gating verify) |
| `scripts/deploy/self-hosted.sh` | Documented stub for a self-hosted docs host |

Self-tests for the tooling live in `tests/` (`python3 -m pytest tests/` or
`python3 -m unittest discover tests`), using the mock adapter only — they never touch a lab.
