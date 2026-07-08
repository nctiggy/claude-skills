# Testing — make the guide provably correct

Test tiers (run in order; each gate blocks the next):

| Tier | What | When | Tool |
|---|---|---|---|
| **T0** | mkdocs `--strict` build, fence-language lint, link+anchor check on built HTML, step-numbering check, secret scan | **always, blocking** | `scripts/check_docs.py <docs-site>` |
| **T1** | `poc-test` annotations parse, ids/hosts/deps valid, every `$VAR` resolvable | blocking whenever annotations exist | `scripts/extract_tests.py --suite <suite.yaml>` |
| **T2** | live execution of every annotated block, in order, via a lab adapter | optional but preferred; skipping stamps the site **UNTESTED** | `scripts/run_doc_tests.py` |
| T3 | visual/screenshot diffing | parked (not in v1) | — |

The philosophy: **a caveat is a bug.** Instead of writing "verify this in your
tenant", annotate the block with an assert and run it. If T2 is skipped, say
"UNTESTED" in the handoff — never imply tested when it wasn't.

## `poc-test` annotations

An HTML comment immediately before a fenced block — invisible in the rendered
site, no MkDocs plugin needed. Inside tabbed content, indent the whole comment to
the tab's level (4 spaces) so it stays inside the tab.

```markdown
<!-- poc-test
id: create-cluster
host: local
needs: [register-node]
timeout: 120
subst:
  "<infra-profile-uid>": "$INFRA_PROFILE_UID"
  "10.0.12.20": "$POC_HOST_NODE_ADDR"
capture:
  CLUSTER_UID: "jq -r '.uid'"
assert: test -n "$CLUSTER_UID"
-->
```

Field reference (full grammar in the `extract_tests.py` docstring):

| Field | Meaning |
|---|---|
| `id` | unique kebab-case id (required) |
| `host` | `local` (the runner box) or a host **role** from the suite manifest (required) |
| `needs` | earlier ids that must have PASSED, else this block is skipped |
| `timeout` | seconds for the block execution (default 600) |
| `file` | write the block's content to this path on the host instead of executing (yaml/config blocks) |
| `subst` | literal doc text → replacement; replacements may reference `$VARS` |
| `capture` | `VAR: shell-filter` — filter is piped the block's stdout; result becomes `$VAR` for later blocks |
| `assert` | local shell command, exit 0 = pass; env has all vars + `POC_STDOUT` (path to the stdout file) |
| `until` | local shell command polled until exit 0 — for "wait until Healthy" steps |
| `retry` | `{attempts, delay}` — with `until`: polls the condition; without `until`: re-runs the whole block (exec+capture+assert) until it passes — e.g. "wait for the edge host to register" |
| `when` | skip the block unless this var is set truthy at run time (e.g. `GPU_PRESENT`) |

Execution semantics: shell blocks run under `set -euo pipefail` with every `$VAR`
they reference exported; a non-zero exit fails the block; the first failure stops
the run (remaining blocks report SKIPPED) and teardown still runs per policy.

**Placeholder discipline:** the doc keeps its human-readable placeholder
(`<registration-token>`); `subst` maps it to a runtime value. The customer never
sees test machinery — check the rendered HTML if in doubt.

## Suite manifest — `docs-site/poc-test-suite.yaml`

See `templates/poc-test-suite.yaml.tmpl`. Keys: `suite`, `pages` (execution
order), `adapter_requirements.hosts` (roles) + `.env` (secret keys the adapter
must emit), `vars` (fixed), `required_vars` (passed via `--var`), and `teardown`
(`always` | `on-success` | `never`). **Destructive resource names (clusters, VMs,
edge hosts) must carry the `poctest-` prefix** — lab adapters use it as their
safety boundary for teardown.

The runner auto-provides `POC_HOST_<ROLE>_ADDR` / `POC_HOST_<ROLE>_USER` for each
adapter host, plus `POC_STDOUT` and `POC_ARTIFACTS`.

## The lab-adapter contract

One executable, four subcommands. Anyone can implement this against their own lab
(that is the seam that keeps this skill generic — lab specifics live in a private
per-person skill, never here):

```
adapter setup [--suite FILE]    Provision/prepare hosts for the suite's roles.
                                Print JSON: {"hosts": {"<role>": {"address": "...", "user": "..."}}}
adapter env                     Print KEY=VALUE lines (API keys etc). Values are
                                treated as secrets: masked in logs and reports,
                                never persisted by the runner.
adapter exec <host> <script>    Run the script file on that host role ("local"
                                never reaches the adapter). Exit code passes through.
adapter teardown [--suite FILE] Destroy everything the suite created. MUST be
                                idempotent — the runner calls it in a finally block.
```

`scripts/adapters/mock/mock-adapter.sh` is the reference implementation (all roles
execute locally); the self-tests in `tests/` run entirely against it.

## Running T2

```bash
python3 scripts/run_doc_tests.py \
  --suite <docs-site>/poc-test-suite.yaml \
  --adapter /path/to/your/lab-adapter.sh \
  --var INFRA_PROFILE_UID=... \
  [--dry-run]
```

`--dry-run` prints the execution plan and calls nothing — use it to review what a
run *would* do before touching a lab. Reports land in
`<docs-site>/.poc-test-artifacts/<timestamp>/` (`report.json` + `report.md`,
per-block stdout/stderr, secrets masked). A publish should reference the latest
PASSED report; absence of one means the site ships stamped **UNTESTED**.

**Never run T2 against production or shared-tenant resources.** Real adapters must
refuse to touch anything not created by the suite (the `poctest-` prefix rule).
