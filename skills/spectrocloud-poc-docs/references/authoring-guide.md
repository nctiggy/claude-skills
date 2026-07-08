# Authoring guide — prospect-facing POC guide sites

The output is a site a prospect works through **alone**, phase by phase, ending each
phase at an observable win. Model pages on the exemplars: `firmus/docs-site/`
(phased agent-mode → appliance GPU POC) and `ge-healthcare/docs-site/` (linear
download → install → validate).

## Intake questions (answer before scaffolding)

1. Customer name, email domain (for gating), and the POC's business goal.
2. What are they proving? (edge, VMO, self-hosted install, GPU/AI, multi-cluster...)
3. Phases: what ordering builds confidence fastest? Default arc:
   *single node fast win → scale out → programmatic/API → production posture (appliance/immutable)*.
4. What hardware/tenant do they actually have? Write to *their* environment.
5. UI-first or API-first audience? (Usually both → tabs.)
6. Will we live-test the guide (T2)? If yes, which lab adapter?

## Page plan

```
docs/
├── index.md              # welcome, phase table w/ time estimates, help pointer
├── prerequisites.md      # tenant access, API key, workstation tooling, hardware
├── phase-1-*.md          # one page per phase, named for the outcome
├── phase-2-*.md
└── reference/
    ├── support.md        # SE/AE contacts, escalation channel
    └── <topic>.md        # deep dives pulled out of the flow (e.g. gpu-operator.md)
```

Navigation: flat `nav` with phases in order, `Reference` section last (see
`templates/mkdocs.yml.tmpl`). Every phase page ends with a **Next:** link.

## Phase page anatomy (the firmus pattern)

1. **Title + Goal line** — one sentence, an *observable* outcome ("...proven by
   `nvidia-smi` executing inside a pod").
2. **Mermaid flow** of the whole phase — the reader sees the shape before the steps.
3. **"Sharp edges" admonition up front** — the 1–3 rules that cause silent failure
   (e.g. "agent mode is 1 or 3+ nodes, never 2"; "single-node VIP must equal the
   node's own IP"). Never bury these in step 4.
4. **Numbered steps** (`## Step N — verb phrase`), each with:
   - **UI/API tabs** (`=== "Palette UI"` / `=== "API"`) when both paths exist.
   - Complete, runnable commands — full curl with headers, full YAML.
   - `poc-test` annotations on the blocks that prove the step (see `testing.md`).
5. **Verification step** — every phase ends by *checking* something (cluster state
   via API, `kubectl get nodes`, a test pod).
6. **"If provisioning stalls" note** — where the logs are, the most likely cause.

## Grounding rules (accuracy)

- **Never write a Palette command from memory.** Pull install steps from
  `spectrocloud-agent-mode` / `spectrocloud-appliance-mode`, API payloads from
  `spectrocloud-clusters` + `spectrocloud-cluster-profiles`, lookup patterns from
  `spectrocloud-common`, pack values/gotchas from `spectrocloud-packs`, and debug
  guidance from `spectrocloud-troubleshooting`.
- Known sharp edges worth restating wherever relevant: registration tokens are
  tenant-scoped (no ProjectUid header); single-node edge clusters need
  `cloudConfig.controlPlaneEndpoint` = the node's own IP (`cloudConfig.vip`
  silently no-ops); cluster names must match `[a-z][a-z0-9-]{1,31}[a-z0-9]`;
  always fetch full pack values before editing profiles.
- If you cannot verify a command, either **annotate it and run it** (T2) or mark
  the page's report UNTESTED — do not ship a "verify this yourself" caveat.

## Style

- Brand: theme + `brand.css` from `templates/` (sourced from `docs-site-generator`
  / `spectrocloud-brand`); Plus Jakarta Sans, teal palette, co-branded index if the
  customer logo is available.
- Placeholders in angle brackets (`<registration-token>`, `<your-project-name>`) or
  env vars (`$PALETTE_API_KEY`) — never realistic-looking literals, never real ones.
- Example IPs must be obviously examples and consistent within a page; never your
  lab's addresses (`check_docs.py` blocks the 172.16–31 range outright).
- Every fence declares a language. Admonition types: `note` (context), `tip`
  (better way), `warning` (will bite), `danger` (data loss / unrecoverable).
- Time-estimate the phases in `index.md` — prospects plan their day around it.
- Keep internal material (worklogs, tenant UIDs, SE notes) out entirely; the site
  is customer-facing even though it is gated.
