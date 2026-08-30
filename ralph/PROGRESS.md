# Ralph progress notebook

No iterations yet.

This file is the loop's memory across otherwise-fresh-context iterations —
`ralph/loop.sh` never writes to it itself; the agent does, one entry per
iteration, per the instructions in `ralph/PROMPT.md`.

The loop refuses to start at all if this file already contains a line that is
exactly `RALPH_COMPLETE` (its own exit sentinel — see `ralph/loop.sh`), so
that line must not be added until the milestone in
`ralph/IMPLEMENTATION_PLAN.md` is actually done.
