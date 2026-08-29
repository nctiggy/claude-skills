# Ralph loop — LM-25 Skill library consolidation

You are one iteration of a Ralph loop in the `claude-skills` repository. You have
no memory of any previous iteration. Everything you need is on disk. Do exactly
one task, verify it, commit it, and exit.

## Every iteration, in order

1. Read `ralph/IMPLEMENTATION_PLAN.md`. It holds the milestone context, the
   `Files touched` allowlist, and the ordered task list.
2. Read `ralph/PROGRESS.md` to see what previous iterations already did and what
   they learned. This is the only record of them that exists.
3. Read `ralph/VALIDATION_CONTRACT.md`. It defines what "done" means for the whole
   milestone. Nothing you do may break an assertion that already holds.
4. Take the **topmost** task still written as `- [ ]` in `ralph/IMPLEMENTATION_PLAN.md`.
   That one, and only that one.
5. Do the work. Read the files you are about to change before changing them.
6. Run the verification named in the task. If it fails, fix your own change until
   it passes. Do not move on to another task.
7. Change that task's `- [ ]` to `- [x]` in `ralph/IMPLEMENTATION_PLAN.md`.
8. Append a dated entry to `ralph/PROGRESS.md`: the task, what you changed, the
   verification command and its result, and anything the next iteration would
   otherwise have to rediscover.
9. Commit and exit.

## Rules

- Run every command from the repository root. Use absolute paths or `-C`; do not
  `cd`.
- Stay inside the `Files touched` allowlist in `ralph/IMPLEMENTATION_PLAN.md`. A
  diff outside it fails the milestone.
- This milestone creates no files. Every path you may touch already exists. If a
  task seems to want a new file, you have misread it — edit the existing SKILL.md.
- **Never `git add -A`.** Other sessions work in this repository at the same time.
  Stage only the paths you personally edited, by name. Check `git status` first and
  leave anything you did not create alone.
- Never force-push and never rewrite shared history.
- Skill rules enforced by `make validate`: frontmatter `name` must equal the
  directory name; `description` must be under 1024 characters and contain no angle
  brackets; SKILL.md must stay under 500 lines.
- The no-argument `make validate` loops over skills without `&&`, so read its
  output for `INVALID:` lines instead of trusting its exit status alone.
  `make validate SKILL=name` does exit non-zero when that one skill fails.
- `skills/` is published. It must never contain lab IPs, `.maas`/`.lan` hostnames,
  1Password references, personal handles, or credentials.
  `python3 scripts/secret_scan.py skills` enforces this.
- `gws` commands in this milestone are documented, not executed for real. Verify
  them with `--dry-run`, which validates locally, exits 0, and sends nothing to
  Google. Never run a `gws` write command without `--dry-run`.
- Do not invent work. If a task looks wrong, do the smallest correct version of it
  and say so in `ralph/PROGRESS.md`.

## Finishing the milestone

When every task in `ralph/IMPLEMENTATION_PLAN.md` is `- [x]` and every assertion in
`ralph/VALIDATION_CONTRACT.md` passes when you actually run its check, append a
final line to `ralph/PROGRESS.md` containing only the sentinel `RALPH_COMPLETE`,
commit, and exit. Do not write that sentinel for any other reason.
