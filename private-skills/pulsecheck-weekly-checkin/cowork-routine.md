# Recurring weekly routine (Claude cowork)

Run this skill automatically once a week so a reviewed draft is waiting
before the check-in is due.

## Recommended schedule

**Friday 15:00 America/Chicago** — cron `0 15 * * 5`. Late enough that the
week's work has happened, early enough to review and submit before the cycle
closes Sunday. Adjust to taste.

The **model is your choice** when you create the routine — this skill is
model-agnostic and works the same on any of them.

## Routine prompt (ready to use)

```text
Run the pulsecheck-weekly-checkin skill for the current check-in week
(Monday through Sunday, evidence window = this Monday 00:00 to now).

1. Gather evidence read-only from my Google Calendar, Gmail, and Zoom
   per the skill's references/gathering.md. Also scan next week's
   calendar for Q2. If a source is unavailable or empty, skip it and
   proceed with the rest.
2. Draft Q1 (progress, 4-6 bullets with one link each), Q2 (up next,
   ~50 words), and Q3 (blockers, or exactly "No blockers this week.")
   per the skill's references/question-guidance.md.
3. Do NOT submit or save anything to PulseCheck. Do not send email or
   post anywhere.
4. Deliver the draft to me for review: the week's dates and a "Sources
   checked" line, the three answers labeled Q1/Q2/Q3, then an Evidence
   appendix mapping each Q1 bullet to its source (event/email/meeting)
   and link. Mark anything you could not verify with [verify].
```

## Setting it up in Claude Code

Use the `/schedule` skill:

```text
/schedule create a weekly routine: every Friday at 15:00 America/Chicago
(cron 0 15 * * 5), running the routine prompt above
```

Then pick whichever model you prefer when prompted. Confirm the routine has
access to the Google Calendar, Gmail, and Zoom connectors; it does not need
anything else.

## Guardrails

- **Draft-only.** The routine never writes to PulseCheck. Submission always
  happens interactively, after you've read the draft (see
  `references/submit.md`) — and a cloud routine has no session cookie to
  submit with anyway. Never store that cookie in the routine.
- **Read-only sources.** The routine only reads calendar, mail, and Zoom;
  it never modifies, labels, replies, or deletes.
- **Evidence appendix required.** Every Q1 bullet arrives with its source
  and link, so you can audit the draft in under a minute.
