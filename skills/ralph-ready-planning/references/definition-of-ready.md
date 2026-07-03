# Definition of Ready — per task

A sub-task is **Ready** only if a fresh Sonnet instance, reading **only this task**, can complete
it with zero decisions. Every item below must be present in the task entry (in `prd.json` and
`tasks.md`).

- [ ] **Exact files** — full path(s) to create or edit (a per-task "Relevant files" line).
- [ ] **Exact interface** — function/type signatures, data shapes, inputs → outputs. Not prose.
- [ ] **Edge cases enumerated** — every error / empty / boundary case listed *with* the expected
      behavior. Not "handle errors".
- [ ] **Approach decided** — the *how* is chosen. If two options exist, pick one and say why.
      Zero "choose the best".
- [ ] **Pattern to mirror** — a pointer to existing code (`path:line`) whose conventions and
      structure to copy, so style isn't reinvented.
- [ ] **Acceptance criteria** — the specific, checkable "done" condition.
- [ ] **Test to write** — the test file + the exact cases to cover.
- [ ] **Dependencies / order** — which task IDs must land first.
- [ ] **Guardrails** — what to NOT touch or change.
- [ ] **One context window** — small enough to finish in a single fresh context. If not, split it.

## The plan-level gate

The whole plan is Ready only when, for **every** task, the answer to
*"would a fresh Sonnet have to decide, guess, or ask?"* is **no**. If yes anywhere, the **plan**
— not the task, and not the executor — is the bug.

## Smells that mean "not ready"

- Vague adverbs: "appropriately", "as needed", "best practice", "properly", "etc."
- A verb without a file: "add validation" — where? on what? what shape?
- An interface described in prose instead of a signature.
- A decision deferred to execution: "decide whether to…", "if it makes sense…", "or similar".
- "Handle X" without stating *how* X is handled.

## Why this bar (not just rigor for its own sake)

Ralph gives each iteration a clean context — no memory of your intent beyond what's written in
`prd.json` + `progress.txt` + git. A gap that a human would resolve in one clarifying question
becomes, in an autonomous loop, a wrong assumption baked into a commit — and then the *next*
iteration builds on it. Front-loading the detail is cheaper than unwinding a bad guess three
tasks later.
