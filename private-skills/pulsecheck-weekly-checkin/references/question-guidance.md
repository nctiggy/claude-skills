# PulseCheck question rubric

Write as the user, in first person. Word targets are targets, not walls —
slightly over is fine; padding to reach one is not.

## Q1 — Progress this week (required, ~200 words, 4–6 bullets MAX)

The question, verbatim:

> What did you ship, close, or move forward with this week? Keep things high
> level. This should be 4-6 bullet points max - no need to list every ticket
> you closed. Include links to additional context your manager or team might
> need.

How to write it:

- **Lead each bullet with the outcome**, then a clause of context:
  "Shipped the 2-node appliance-mode demo flow — unblocks the Q3 field
  enablement track."
- **Group tickets into the initiative they served.** Five closed tickets on
  one migration is one bullet about the migration, not five bullets.
- **One most-useful link per bullet.** Prefer ticket > doc > PR — pick the
  single link a manager would actually click.
- **Use verbs of completion:** shipped, closed, landed, decided, unblocked,
  migrated. "Worked on" and "continued" are last resorts.

## Q2 — What's up next (required, ~50 words)

The question, verbatim:

> List the specific initiatives or deliverables you're planning to start or
> complete next week. Include a ticket or doc link if one exists. Note
> anything contingent on a blocker being resolved.

How to write it:

- **Specific deliverables, not themes.** "Finish the PCG upgrade runbook" —
  not "continue infrastructure work."
- Add a ticket or doc link where one exists.
- If an item depends on a Q3 blocker resolving, flag the dependency
  explicitly.
- Usually 2–4 items. Next week's calendar (launches, reviews, demos already
  scheduled) is a strong source.

## Q3 — Blockers (only if real, ~50 words per blocker)

The question, verbatim:

> Only answer this question if you're facing any blockers. For each blocker
> or risk: name the specific dependency or issue, how long it's been
> outstanding, what happens to the timeline if it's not resolved, what you're
> actively doing about it, and who you've escalated to if applicable.

How to write it:

- **Only genuine blockers** — things that stop or seriously endanger a
  deliverable. Annoyances and normal wait states don't belong here.
- If there are none, output exactly: `No blockers this week.`
- Each blocker must cover all five points — what it is, how long it's been
  outstanding, the timeline impact, what you're doing about it, and who
  you've escalated to. Example:

  > Still waiting on security sign-off for the registry migration (open 9
  > days). If it slips past Friday, GA moves a full sprint. I've supplied the
  > requested threat-model doc and follow up daily; escalated to Priya on
  > Tuesday.

## Voice and formatting

- First person, active voice, plain language. No corporate filler
  ("synergies", "leveraged", "circled back").
- Q1 as bullets; Q2 and Q3 as tight prose.
- Slightly over a word target is OK; do not pad.
- Mark any fact you couldn't fully confirm with `[verify]` so the user can
  check it before submitting.

## Field mapping (for submission)

When saving to PulseCheck: `accomplishments` = Q1, `upcoming` = Q2,
`blockers` = Q3. The `accomplishments` and `blockers` fields accept rich-text
HTML (use `<ul><li>` for Q1 bullets and `<a href>` for links); `upcoming` is
plain text.
