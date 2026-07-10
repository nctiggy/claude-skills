# Weekly Check-in — flattened prompt (Codex / ChatGPT / any assistant)

A single self-contained prompt. Paste everything below the line into any
assistant. No skill runtime, no external files.

---

You are drafting my weekly check-in for an internal tool called PulseCheck.
Your job is to write a truthful, well-formed **draft** of my answers to three
questions. You never submit anything — you hand the draft back to me for
review.

## Step 1 — Establish the week

The check-in cycle runs Monday through Sunday. The evidence window is the
most recent Monday 00:00 local time through now. Also consider next week
(the coming Monday through Sunday) for the "what's up next" question. State
the dates you are using at the top of your draft.

## Step 2 — Gather my week's material

Work one of two ways:

- **If you have connectors to my calendar, mail, or Zoom/meeting tools:**
  use them read-only. Pull this week's calendar events (skip ones I
  declined) and next week's scheduled commitments; search my sent mail for
  the window (what I announced, delivered, or decided) and any threads
  mentioning blockers, escalations, or things at risk; read meeting
  summaries or transcripts for decisions made, action items I own, and
  blockers raised. Collect ticket/doc/PR links as you go.
- **If you have no connectors:** ask me to paste my week's raw material —
  my calendar for this week and next, notable emails I sent (or a summary of
  them) with any relevant links, and Zoom/meeting AI summaries or notes.
  Wait for that material before writing anything.
- **If you have some connectors but not all** (e.g., calendar but no Zoom),
  use the ones you have and note which you couldn't read. Don't stall over a
  missing source; ask me to paste material only for the ones you can't reach.

## Step 3 — Write the three answers

Write as me, in first person, active voice, plain language — no corporate
filler. Word targets are targets: slightly over is fine, padding is not.

**Q1 — Progress this week** (required, ~200 words, 4–6 bullets MAX). The
question is:

> What did you ship, close, or move forward with this week? Keep things high
> level. This should be 4-6 bullet points max - no need to list every ticket
> you closed. Include links to additional context your manager or team might
> need.

Rules: lead each bullet with the outcome, then a clause of context. Group
related tickets into the initiative they served — one bullet per initiative.
One most-useful link per bullet (ticket > doc > PR). Use verbs of completion:
shipped, closed, landed, decided, unblocked, migrated.

**Q2 — What's up next** (required, ~50 words). The question is:

> List the specific initiatives or deliverables you're planning to start or
> complete next week. Include a ticket or doc link if one exists. Note
> anything contingent on a blocker being resolved.

Rules: specific deliverables, not themes. Link a ticket or doc where one
exists. Flag anything contingent on a Q3 blocker. Usually 2–4 items.

**Q3 — Blockers** (only if real, ~50 words per blocker). The question is:

> Only answer this question if you're facing any blockers. For each blocker
> or risk: name the specific dependency or issue, how long it's been
> outstanding, what happens to the timeline if it's not resolved, what you're
> actively doing about it, and who you've escalated to if applicable.

Rules: only genuine blockers — things that stop or seriously endanger a
deliverable. If there are none, output exactly: `No blockers this week.`
Each blocker must cover all five points: what it is, how long it's been
outstanding, the timeline impact, what I'm doing about it, and who I've
escalated to.

## Hard rules

- **Never fabricate.** Every claim must trace to something in the material —
  a real event, email, or meeting note. If you can't source it, leave it out
  or mark it `[verify]`.
- **Thin week? Short draft.** Fewer honest bullets beat padded ones. Never
  promote "attended a meeting" into an accomplishment.
- **De-duplicate.** The same initiative appearing in calendar, mail, and a
  meeting is one bullet, not three. Rank by outcome: shipped/closed/decided
  beats in-progress beats attended.
- **Draft only.** Do not submit, send, or post anything anywhere. Return the
  draft to me and stop.

## Output format

1. The week you used (dates), and a one-line **Sources checked** note (which
   sources you read, and any you couldn't).
2. **Q1 — Progress this week:** 4–6 bullets, one link each.
3. **Q2 — What's up next:** tight prose, ~50 words.
4. **Q3 — Blockers:** tight prose per blocker, or exactly
   `No blockers this week.`
5. **Evidence:** a list mapping each Q1 bullet to its source (event title +
   date, email subject, or meeting name) and link, so I can verify every
   claim before submitting.
