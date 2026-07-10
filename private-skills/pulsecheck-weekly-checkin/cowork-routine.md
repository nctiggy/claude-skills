# Recurring weekly routine (Claude cowork)

Run this skill automatically once a week so a reviewed draft is waiting
before the check-in is due.

## Recommended schedule

**Friday 15:00 America/Chicago** — cron `0 15 * * 5`. Late enough that the
week's work has happened, early enough to review and submit before the cycle
closes Sunday. Adjust to taste.

The **model is your choice** when you create the routine — this skill is
model-agnostic and works the same on any of them.

## Choose the routine's mode — you decide

Pick one when you create the routine. **Draft is the recommended default.**

- **Draft mode** — generate the check-in and leave it as a draft for you to
  review and submit yourself. Nothing is finalized without you.
- **Submit mode** — generate *and* submit the check-in (`intent=submit`).
  Use this only if you're comfortable finalizing without a review step.

Both modes always produce the full answers plus the evidence appendix, so you
can audit what was (or will be) submitted.

**Submit mode needs a session cookie at run time.** Submitting hits the
cookie-authenticated App API, so Submit mode only finalizes when a valid
`__pulse_session` cookie is available where the routine runs (a locally-run
schedule, or one with your captured `storageState`). A pure cloud routine has
no cookie — in that case Submit mode still produces the finished answers and
asks you to approve the one-step submit rather than failing.

## Routine prompt — Draft mode (ready to use)

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

## Routine prompt — Submit mode (ready to use)

```text
Run the pulsecheck-weekly-checkin skill for the current check-in week
(Monday through Sunday, evidence window = this Monday 00:00 to now).

1. Gather evidence read-only from my Google Calendar, Gmail, and Zoom
   per the skill's references/gathering.md. Also scan next week's
   calendar for Q2. If a source is unavailable or empty, skip it and
   proceed with the rest.
2. Write Q1 (progress, 4-6 bullets with one link each), Q2 (up next,
   ~50 words), and Q3 (blockers, or exactly "No blockers this week.")
   per the skill's references/question-guidance.md.
3. Submit the check-in to PulseCheck with intent=submit, following
   references/submit.md, IF a __pulse_session cookie is available. If no
   cookie is available, do NOT submit — deliver the finished answers and
   tell me to submit them myself.
4. Report the outcome: the week's dates and a "Sources checked" line, the
   three answers labeled Q1/Q2/Q3, whether it was submitted or is awaiting
   my submission, and an Evidence appendix mapping each Q1 bullet to its
   source and link. Mark anything you could not verify with [verify].
```

## Setting it up in Claude Code

Use the `/schedule` skill with whichever prompt matches your chosen mode:

```text
/schedule create a weekly routine: every Friday at 15:00 America/Chicago
(cron 0 15 * * 5), running the [Draft mode | Submit mode] routine prompt above
```

Then pick whichever model you prefer when prompted. Confirm the routine has
access to the Google Calendar, Gmail, and Zoom connectors; it does not need
anything else.

## Guardrails

- **You choose draft or submit.** Draft is the default and never writes to
  PulseCheck. Submit mode finalizes only when a session cookie is present at
  run time; otherwise it hands you the finished answers to submit. Never store
  that cookie in the routine definition or its prompt.
- **Read-only sources.** The routine only reads calendar, mail, and Zoom;
  it never modifies, labels, replies, or deletes.
- **Evidence appendix required.** In both modes, every Q1 bullet arrives with
  its source and link, so you can audit it in under a minute.
