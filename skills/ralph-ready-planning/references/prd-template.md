# PRD template (Fable fills this in)

Extends snarktank `create-prd`. Keep this document **tight** — its job is to lock the *decisions*
and *context*. The step-by-step detail lives in the task list (`references/definition-of-ready.md`),
not here.

```markdown
# <Feature> — PRD

**Blast radius:** low | medium | high   <!-- sets the autonomy + critic level; see SKILL.md dial -->

## 1. Summary
One paragraph: what we're building, for whom, and why now.

## 2. Goals / success criteria
- Measurable product-level outcomes. What "done and working" looks like to a user.

## 3. Non-goals (explicit)
- What this deliberately does NOT do. Prevents scope creep and wrong guesses.

## 4. Decisions already made
| Decision | Chosen | Rejected alternative | Why |
|---|---|---|---|
|  |  |  |  |
- Every architectural choice is made HERE, before execution — never deferred to Sonnet.

## 5. Context & constraints (from Phase 0 investigation)
- Existing patterns to follow (`file:line`), the APIs used + their quirks, versions, limits,
  auth model, and anything discovered by reading the real code.

## 6. Risks & mitigations
- Especially the safety/security model for medium+ blast radius. Each mitigation should become a
  **testable acceptance criterion**, not a hope.

## 7. Acceptance criteria (top-level)
- The checkable conditions for the whole feature. (Task-level criteria live in the task list.)

## 8. Out of scope / follow-ups
- Parked items, so they're captured without expanding this PRD.
```

## Notes for the author (Fable)

- If section 4 is thin, you haven't investigated enough — go back to Phase 0. A high-quality PRD
  is mostly *decisions already made* plus *context*, so the executor inherits judgment instead of
  making it.
- For **high blast radius**, section 6 is the most important part of the document: write the
  fail-safe behavior, the anti-spoof/abuse model, and the "what must never happen" list as
  explicit, testable requirements.
