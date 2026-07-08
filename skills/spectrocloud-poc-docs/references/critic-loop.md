# Critic loop — two review passes before publish

Run both passes after T0/T1 (and T2 when applicable) are green, before `deploy`.
Each pass produces findings as `severity · page:line · problem · fix`; apply the
fixes, re-run `check_docs.py`, then move on. Two passes, not endless polish.

## Pass 1 — the prospect (cold reader)

Adopt the persona of the customer engineer who will actually run this, alone,
with no Spectro Cloud context beyond the site itself. Walk every page top to
bottom and flag:

- **Can I actually run this?** Every command complete (headers, env vars set
  earlier, files created earlier)? Does step N ever depend on something no step
  created? Are placeholders obvious about what to substitute?
- **Do I know it worked?** Does each step/phase end with a check whose expected
  output is shown or described?
- **Am I ever stranded?** If a step fails, is there a "stalls" note or a support
  pointer within reach?
- **Do I know why?** One line of motivation per phase — engineers distrust
  ritual instructions.
- Jargon used before it's defined; assumed tenant permissions never listed in
  prerequisites; time estimates missing or dishonest.

## Pass 2 — the SE reviewer (technical + hygiene)

Adopt the persona of a second SE who owns the account if this POC fails:

- **Accuracy against the skills**: re-check every Palette command/payload against
  `spectrocloud-clusters`, `spectrocloud-cluster-profiles`, `spectrocloud-agent-mode`,
  `spectrocloud-appliance-mode`, `spectrocloud-common`. Any command not covered by
  a skill or a `poc-test` annotation gets flagged.
- **Sharp edges surfaced**: are the known failure modes (2-node limit, single-node
  VIP rule, name regex, partial pack values) called out *before* the step that
  triggers them?
- **Hygiene sweep beyond the scanner**: anything internal a regex can't catch —
  other customers' names, internal project slang, tenant-specific UIDs presented
  as if universal, screenshots showing internal data.
- **Test honesty**: do annotations actually assert the thing the text claims
  ("cluster Healthy" asserted as Healthy, not just created)? Is anything marked
  tested that T2 skipped?

## Exit criteria

- Zero unresolved error-severity findings from either pass.
- `check_docs.py` clean after the fixes.
- A one-paragraph review summary saved with the site (what was flagged, what
  changed) — it becomes part of the handoff note.
