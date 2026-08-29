# LM-25 — Skill library consolidation

Four skills in `skills/` answer "make me a doc": `doc-writer`, `exec-doc-generator`,
`docs-site-generator`, `slide-deck-generator`. As committed today only
`docs-site-generator` carries any boundary text (a redirect to
`spectrocloud-poc-docs`); the other three descriptions overlap freely, so a plain
"write this up" or "make me a deck" has no single owner.

This milestone does two things:

1. Replaces four-way overlap with one routing table plus four mutually exclusive
   descriptions, so every deliverable shape has exactly one owner.
2. Closes `slide-deck-generator`'s capability gap. It renders HTML to PDF, but the
   recurring ask is a Google Slides deck with a shareable link. `gws` is installed
   and exposes `slides presentations get|create|batchUpdate|pages` and
   `drive files copy` / `drive permissions create`; every one of those accepts
   `--dry-run`, which validates the request locally and exits 0 without contacting
   Google or touching the keyring for real. `skills/spectrocloud-brand/SKILL.md`
   records the 2026 Corporate Template ID under "Key Template IDs (Google Slides)",
   so the copy-and-fill path has a real anchor.

Both additions land **inside the existing SKILL.md files**. No new files, no new
`references/` directories. Skills here are shipped as self-contained directories,
and a relative path from one skill into another skill's `references/` does not
resolve for the agent reading it — so the routing table lives in `doc-writer` and
the other three skills point at it by skill name.

Verification harness (already present, no setup needed): `make validate` runs
`scripts/quick_validate.py` over every skill (name matches directory, description
under 1024 chars with no angle brackets, SKILL.md under 500 lines) and then
`scripts/secret_scan.py skills`. `make validate SKILL=name` checks one skill and
exits non-zero if that skill fails. Run everything from the repository root.

Headroom against the 500-line ceiling as committed today: `doc-writer` 213,
`exec-doc-generator` 237, `slide-deck-generator` 292, `docs-site-generator` 428.
Only `docs-site-generator` is tight; additions there must stay short.

## Out of scope for this milestone

- `start-project` plugin flattening. The plugin is not in this repository and no
  installed marketplace registers it — `~/.claude/plugins/known_marketplaces.json`
  lists only `claude-plugins-official`, whose sole plugin is `skill-creator`. Its
  source could not be located, so a task pointing at it would stall the loop.
  Flattening belongs in whichever repository owns that plugin.
- Deleting `prd` and `ralph`. Neither exists in `skills/` here; there is nothing in
  this repository to delete.

## Files touched

Only these paths may change. Every one already exists — this milestone creates no
files. A diff anywhere else is a failure.

- `ralph/IMPLEMENTATION_PLAN.md`
- `ralph/PROGRESS.md`
- `ralph/PROMPT.md`
- `ralph/VALIDATION_CONTRACT.md`
- `skills/doc-writer/SKILL.md`
- `skills/docs-site-generator/SKILL.md`
- `skills/exec-doc-generator/SKILL.md`
- `skills/slide-deck-generator/SKILL.md`

## Tasks

- [ ] Add a `## Deliverable Routing` section to `skills/doc-writer/SKILL.md`: one table, five rows, mapping each shape (long-form Markdown; 1-2 page exec PDF; multi-page docs site; deck as PDF; deck as a Google Slides link) to its single owning skill and the artifact produced. Verify: `make validate SKILL=doc-writer` exits 0 and the table names all four doc skills.

- [ ] Add a `## Google Slides Output` section to `skills/slide-deck-generator/SKILL.md`: the gws sequence — `gws drive files copy` of the 2026 Corporate Template ID from `skills/spectrocloud-brand/SKILL.md`, then `slides presentations get`, `slides presentations batchUpdate`, `drive permissions create`, ending in the edit URL. Verify: every gws command shown exits 0 with `--dry-run` appended.

- [ ] Rewrite the frontmatter `description` in `skills/doc-writer/SKILL.md` to claim only long-form Markdown writeups and send exec PDFs, docs sites and decks to the owning skill by name. Under `## When to Use`, point readers to this skill's own deliverable routing table. Verify: `make validate SKILL=doc-writer` exits 0.

- [ ] Rewrite the frontmatter `description` in `skills/exec-doc-generator/SKILL.md` to claim only the 1-2 page executive PDF and send long-form Markdown, docs sites and decks to the owning skill by name. Under `## When to Use`, point to the deliverable routing table in the `doc-writer` skill. Verify: `make validate SKILL=exec-doc-generator` exits 0.

- [ ] Rewrite the frontmatter `description` in `skills/docs-site-generator/SKILL.md` to claim only multi-page navigable sites, keep its `spectrocloud-poc-docs` redirect, and send writeups, exec PDFs and decks elsewhere by name. Under `## When to Use`, point to the deliverable routing table in `doc-writer`. Verify: `make validate SKILL=docs-site-generator` exits 0 (it is at 428 of 500 lines).

- [ ] Rewrite the frontmatter `description` in `skills/slide-deck-generator/SKILL.md` to claim projected slides in both forms — rendered PDF and shareable Google Slides link — and send writeups, exec PDFs and docs sites elsewhere by name. Under `## When to Use`, point to the deliverable routing table in `doc-writer`. Verify: `make validate SKILL=slide-deck-generator` exits 0.

- [ ] Run every check in `ralph/VALIDATION_CONTRACT.md`: `make validate`, the four-way `grep -h "^description:"`, `grep -rli "deliverable routing" skills/`, the `--dry-run` replay of the documented gws commands, and `python3 scripts/secret_scan.py skills`. Verify: `make validate` prints no `INVALID:` line, and `ralph/PROGRESS.md` gains a dated pass/fail line for each of the five assertions.
