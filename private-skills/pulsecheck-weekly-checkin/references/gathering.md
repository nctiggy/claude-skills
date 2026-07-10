# Gathering evidence

Strictly read-only: never modify, label, respond to, or delete anything in
any source. Work the window `WINDOW_START` (this week's Monday 00:00 local)
→ `WINDOW_END` (now), plus next week's calendar for Q2. As you go, keep a
running list of `(claim → source → link)` — this becomes the Evidence
appendix.

Work the three sources below **in order** (Calendar, then Gmail, then Zoom).
Do all three if they're available; you don't need results from one before
starting the next.

## When a source is missing or empty

Any connector may be unavailable, error, or return nothing. Handle it and
keep going — do not stop the check-in:

- **Connector not available / call errors:** skip that source, record it as
  "couldn't read", and move to the next one.
- **Source returns nothing for the window** (e.g., empty calendar, no sent
  mail, no recordings): that's a valid result — record it as "read, nothing
  relevant" and move on.
- Build the draft from whatever sources did return signal. If *no* source
  yielded anything, say so plainly and ask the user to paste their week's raw
  material rather than inventing content.
- Report the outcome per source in the draft's **Sources checked** line so
  the user knows what the answers rest on.

## Google Calendar

Tools: `mcp__claude_ai_Google_Calendar__list_calendars`, then
`mcp__claude_ai_Google_Calendar__list_events`.

1. `list_calendars` to find the user's primary calendar (plus any obvious
   team calendar they own).
2. `list_events` with `timeMin`/`timeMax` set to the check-in window.
3. `list_events` again for **next week** (coming Monday → Sunday) — already-
   scheduled launches, reviews, and demos are direct Q2 evidence.

Extract:

- **Outcomes** — events whose titles signal a result: launch, demo, review,
  ship, GA, cutover, go/no-go, retro. These often anchor Q1 bullets.
- **Collaborations** — recurring syncs and 1:1s show which initiatives got
  sustained attention this week.
- **Focus blocks** — self-scheduled deep-work blocks hint at what the user
  was building (corroborate with email/Zoom before claiming it as done).
- Grab each event's link/URL for the Q1 evidence appendix.
- **Skip events the user declined** — attendance the user opted out of is
  not evidence of work.

## Gmail

Tools: `mcp__claude_ai_Gmail__search_threads`, then
`mcp__claude_ai_Gmail__get_thread`.

Use date-bounded queries in Gmail syntax
(`after:YYYY/MM/DD before:YYYY/MM/DD` for the window):

1. **Sent mail — the strongest Q1 signal:**
   `from:me after:YYYY/MM/DD before:YYYY/MM/DD`
   What the user announced, delivered, decided, or handed off in their own
   words.
2. **Decisions and deliverables sent:** scan those sent threads for
   attachments, doc links, "here's the final", "shipping", "approved",
   "signed off".
3. **Blocker and escalation threads (→ Q3):**
   `(blocker OR blocked OR "waiting on" OR escalat* OR "at risk" OR slip) after:YYYY/MM/DD before:YYYY/MM/DD`

Then `get_thread` on the promising hits — subjects lie; read the bodies.
Pull doc, ticket, and PR links out of thread bodies; these are usually the
best links for Q1 bullets.

## Zoom

Tools: `mcp__claude_ai_Zoom_for_Claude__recordings_list`,
`mcp__claude_ai_Zoom_for_Claude__search_meetings`, then
`mcp__claude_ai_Zoom_for_Claude__get_meeting_assets` and
`mcp__claude_ai_Zoom_for_Claude__get_file_content`.

1. `recordings_list` and/or `search_meetings` scoped to the check-in window.
2. For each relevant meeting, `get_meeting_assets` to enumerate what exists,
   then `get_file_content` to read it.
3. **Prefer the AI summary over the raw transcript** — it's shorter and
   already surfaces decisions and action items. Fall back to the transcript
   only when the summary is missing or you need to confirm a specific claim.

Extract:

- **Decisions made** in meetings the user attended (Q1: "decided", "agreed").
- **Action items the user owns** — commitments made this week feed Q2.
- **Blockers raised**, and critically, **who owns the dependency** — that's
  the escalation name Q3 requires.

## Turning evidence into signal

- **De-duplicate across sources.** The same initiative will show up as a
  calendar review, a sent email, and a Zoom decision — that's one Q1 bullet
  with the strongest link, not three.
- **Rank by outcome.** Shipped/closed/decided beats in-progress; in-progress
  beats attended. Fill the 4–6 slots from the top of that ranking.
- **Thin week = fewer bullets.** Three honest bullets beat six padded ones.
  Never promote "attended a meeting" to an accomplishment.
- **One best link per bullet** (ticket > doc > PR), carried through to the
  Evidence appendix with its source noted.
