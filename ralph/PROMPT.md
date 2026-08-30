# Ralph prompt — harness scaffold, no milestone planned yet

This `ralph/` directory was installed by `loop/ralph-onboard.sh` from
`craig-ai-tooling/ai-lawnmower`. Its only job is to make `./ralph/loop.sh`
runnable, so a Ralph Job clone-and-run no longer dies for want of the file.

This is NOT a real milestone. Do not dispatch this repo to the cluster until a
planning pass has replaced this file, `ralph/IMPLEMENTATION_PLAN.md` and
`ralph/PROGRESS.md` with an actual plan — `loop/ralph-prepare.sh <task-id> --go`
in ai-lawnmower, or the same shape written by hand.

## Do this, in order

1. Read `ralph/IMPLEMENTATION_PLAN.md`. If it has no open `- [ ]` task, stop —
   there is nothing to do yet. Do not invent one.
2. Read `ralph/PROGRESS.md` to see what earlier iterations already did, and do
   not redo it.
3. Read this repo's own `AGENTS.md` or `CLAUDE.md` at its root, if either
   exists. Its working rules apply to you.
4. Take the topmost unchecked `- [ ]` task in `ralph/IMPLEMENTATION_PLAN.md`.
   Exactly one.
5. Do that task, and only that task. Stay inside the `Files touched` allowlist
   in `ralph/IMPLEMENTATION_PLAN.md` — a diff outside it is rejected before it
   can ship.
6. Run the task's own verification command. It must pass.
7. Tick the task to `- [x]` and append to `ralph/PROGRESS.md`: the task, the
   command you ran, and its real output — not a summary of what it should have
   said.
8. Commit only the paths you touched. Never `git add -A` — other work may share
   this tree.
9. If every task is `- [x]`, append a final line to `ralph/PROGRESS.md`
   containing only `RALPH_COMPLETE` — a line of its own, nothing else — and
   stop.

## If you are blocked

Mark the task `- [!]`, write what blocked you in `ralph/PROGRESS.md`, commit
that, and stop. A blocked task recorded honestly beats a confident wrong diff.
