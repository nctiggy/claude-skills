# LM-25 Validation Contract — Skill library consolidation

What "done" means for this milestone, decided before decomposition. A later pass
checks the built library against this file as a black box: no git history, no
diff, just the repository as it stands. Run every command from the repository
root.

## Assertions

- The library still passes its own gate: `make validate` exits 0 and prints no line beginning with `INVALID:`, so every skill keeps a name matching its directory, a description under 1024 characters with no angle brackets, and a SKILL.md under 500 lines.

- Each of the five document deliverable shapes — long-form Markdown writeup; 1-2 page executive PDF; multi-page navigable documentation site; projected deck rendered to PDF; projected deck delivered as a shareable Google Slides link — is claimed by exactly one skill: run `grep -h "^description:" skills/doc-writer/SKILL.md skills/exec-doc-generator/SKILL.md skills/docs-site-generator/SKILL.md skills/slide-deck-generator/SKILL.md` and read the four descriptions end to end; each claims one shape and sends the other shapes to the owning skill by name, so a reader choosing between them lands on a single answer with no tie to break and no shape left unclaimed.

- The boundary rules live in one place instead of being restated four times: `grep -rli "deliverable routing" skills/` lists exactly four paths, one per document skill, and exactly one of those four carries the table itself — five rows, one per shape, naming the owning skill and the artifact it produces.

- A request for a Spectro-branded deck delivered as a shareable Google Slides link is answerable end to end without leaving the library: the deck skill documents the whole sequence — copy the branded template, read its layouts, populate it, share it, hand back a `https://docs.google.com/presentation/d/` edit URL — as real `gws` commands, and appending `--dry-run` to each documented `gws` command and running it exits 0 for every one (this validates locally and sends nothing to Google).

- Nothing personal leaked into the published tree while it was edited: `python3 scripts/secret_scan.py skills` prints `Secret scan clean: skills/` and exits 0.
