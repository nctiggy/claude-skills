---
name: pulsecheck-weekly-checkin
description: >-
  Draft the user's weekly PulseCheck check-in by mining their own Google
  Calendar, Gmail, and Zoom transcripts for the current check-in week, then
  writing well-formed answers to the three questions (Q1 progress, Q2 up next,
  Q3 blockers). Produces a reviewable DRAFT and never auto-submits. Use when
  the user asks to write, prepare, draft, or submit their weekly check-in or
  pulse-check, or as a recurring weekly task in Claude cowork. PRIVATE - lives in
  private-skills/, is never uploaded by CI, and references internal credential paths;
  do not copy into a shareable skill.
allowed-tools: mcp__claude_ai_Google_Calendar__list_calendars, mcp__claude_ai_Google_Calendar__list_events, mcp__claude_ai_Gmail__search_threads, mcp__claude_ai_Gmail__get_thread, mcp__claude_ai_Zoom_for_Claude__recordings_list, mcp__claude_ai_Zoom_for_Claude__search_meetings, mcp__claude_ai_Zoom_for_Claude__get_meeting_assets, mcp__claude_ai_Zoom_for_Claude__get_file_content, Read, Bash
metadata:
  version: 1.0.0
  author: craig.smith@spectrocloud.com
---

# PulseCheck Weekly Check-in

Draft the user's weekly PulseCheck check-in from their own calendar, email,
and Zoom activity. You produce a **draft for review** — you never submit
anything without explicit approval.

## Golden rules

1. **Never fabricate.** Every claim in the draft must trace to a real
   calendar event, email thread, or Zoom transcript you actually read. If you
   can't source it, leave it out or mark it `[verify]`.
2. **Thin week? Short draft.** If the evidence is sparse, write fewer, honest
   bullets. Never pad with filler or inflate routine work into achievements.
3. **Never auto-submit.** The default output is a draft in the conversation.
   Saving to PulseCheck happens only after the user approves, and only as
   `intent=draft` unless the user explicitly says "submit".

## Workflow

### 1. Establish the week

The PulseCheck cycle runs **Monday through Sunday**. Compute:

- **This week's window:** the most recent Monday 00:00 local time → now.
  This is the evidence window for Q1 and Q3.
- **Next week's window:** the coming Monday → Sunday. Scan this on the
  calendar for Q2 (what's up next).

State the dates you're using at the top of the draft so the user can catch an
off-by-one week immediately.

### 2. Gather evidence (read-only)

Follow `references/gathering.md`. In short:

- **Google Calendar** — `list_calendars`, then `list_events` for this week
  (outcomes, collaborations, focus blocks) and next week (Q2 commitments).
- **Gmail** — `search_threads` with date-bounded queries, especially
  `from:me` sent mail (the strongest Q1 signal) and blocker-language searches
  for Q3; `get_thread` on the promising hits.
- **Zoom** — `recordings_list` / `search_meetings` for the window, then
  `get_meeting_assets` + `get_file_content` for AI summaries and transcripts.

All gathering is strictly read-only. Do not modify, label, respond to, or
delete anything in any source.

**Proceed with whatever sources you have.** If a connector isn't available,
errors, or returns nothing (e.g., Zoom not connected, empty calendar for the
week), skip it and keep going with the sources that do work — never fail the
whole check-in over one missing source. Keep a short list of which sources you
could and couldn't read, and report it in the draft (see step 4) so the user
knows what the answers are based on.

### 3. Synthesize the three answers

Follow the rubric in `references/question-guidance.md` exactly — question
prompts, word targets, formatting, and tone. Q1 is 4–6 outcome-led bullets
with one link each; Q2 is ~50 words of specific next-week deliverables; Q3 is
genuine blockers only (or exactly `No blockers this week.`).

### 4. Present the draft

Show the user:

1. The week's dates and a one-line **Sources checked** note (which of
   calendar / mail / Zoom you read, and any you couldn't).
2. The three answers, clearly labeled Q1 / Q2 / Q3.
3. An **Evidence appendix**: for each Q1 bullet, the source it came from
   (event title + date, email subject, or meeting name) and its link, so the
   user can audit every claim in seconds.

Invite corrections — the user knows things the sources don't.

### 5. Save as draft (only after approval)

Only after the user approves the text, offer to save it to PulseCheck as a
**draft**, following `references/submit.md`. Never use `intent=submit`
unless the user explicitly instructs it in this conversation.

## Recurring use (Claude cowork)

When running as a scheduled cowork routine: draft-only, always. Deliver the
draft plus evidence appendix to the user for review; do not save to
PulseCheck, send email, or post anywhere without approval. A cloud routine
won't have the local PulseCheck session cookie, so submission isn't possible
there anyway. Setup instructions and a ready-to-use routine prompt are in
`cowork-routine.md`.

## Using this outside Claude

For Codex, ChatGPT, or any other assistant, hand the user the single
self-contained prompt in `flattened/codex-checkin-prompt.md` — it embeds the
full rubric and has no dependency on this skill's runtime or files.
