#!/usr/bin/env python3
"""run_doc_tests.py — T2 live runner for `poc-test` annotated docs (spectrocloud-poc-docs).

Executes every annotated command block in a docs-site, in document order, through a
LAB ADAPTER (one executable, four subcommands — see references/testing.md):

    adapter setup    [--suite FILE]  -> JSON {"hosts": {"<role>": {"address": .., "user": ..}}}
    adapter env                      -> KEY=VALUE lines (secrets; masked in all output)
    adapter exec <host> <script>     -> runs script on that host role; exit code passes through
    adapter teardown [--suite FILE]  -> idempotent cleanup of everything the suite created

Behaviour per block:
  - `when:` var unset/falsy -> SKIPPED
  - `subst:` literal doc placeholders are replaced (replacement values may use $VARS)
  - `file:` blocks are written to the given path on the host (base64 transport), not executed
  - shell blocks run under `set -euo pipefail` with referenced $VARS exported
  - `capture:` filters the block's stdout into new vars for later blocks
  - `assert:` / `until:` (+ `retry:`) run LOCALLY with all vars + POC_STDOUT in env
  - first FAILED block stops the run; teardown still runs per the suite's policy

The report (JSON + markdown) lands in <docs-site>/.poc-test-artifacts/<timestamp>/.
A docs-site published without a passing T2 report must be stamped UNTESTED — see
references/publishing.md.

Usage:
  run_doc_tests.py --suite <poc-test-suite.yaml> --adapter <path> \
      [--var KEY=VALUE ...] [--dry-run] [--report-dir DIR]
"""

from __future__ import annotations

import argparse
import base64
import datetime as dt
import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from extract_tests import (  # noqa: E402
    ParseError, Suite, TestBlock, lint, load_suite, suite_blocks,
)

VAR_REF_RE = re.compile(r"\$\{?([A-Z][A-Z0-9_]*)\}?")


class Masker:
    """Masks secret values in anything we print or persist."""

    def __init__(self):
        self._secrets: list[str] = []

    def add(self, value: str):
        if value and len(value) >= 6:
            self._secrets.append(value)

    def clean(self, text: str) -> str:
        for s in self._secrets:
            text = text.replace(s, "*****")
        return text


MASK = Masker()


def log(msg: str):
    print(MASK.clean(msg), flush=True)


def expand_vars(text: str, ctx: dict[str, str]) -> str:
    def repl(m: re.Match) -> str:
        return ctx.get(m.group(1), m.group(0))
    return VAR_REF_RE.sub(repl, text)


def run_adapter(adapter: str, args: list[str], *, timeout: int = 1800,
                input_text: str | None = None) -> subprocess.CompletedProcess:
    return subprocess.run([adapter, *args], capture_output=True, text=True,
                          timeout=timeout, input=input_text)


def adapter_setup(adapter: str, suite: Suite) -> dict[str, dict]:
    proc = run_adapter(adapter, ["setup", "--suite", str(suite.path)])
    if proc.returncode != 0:
        raise RuntimeError(f"adapter setup failed (rc={proc.returncode}):\n{proc.stderr}")
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"adapter setup did not print JSON: {exc}\n{proc.stdout[:500]}") from exc
    hosts = data.get("hosts") or {}
    missing = [h for h in suite.hosts if h not in hosts]
    if missing:
        raise RuntimeError(f"adapter setup missing required host roles: {missing}")
    return hosts


def adapter_env(adapter: str, suite: Suite) -> dict[str, str]:
    proc = run_adapter(adapter, ["env"])
    if proc.returncode != 0:
        raise RuntimeError(f"adapter env failed (rc={proc.returncode}):\n{proc.stderr}")
    env: dict[str, str] = {}
    for line in proc.stdout.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        env[key.strip()] = val
        MASK.add(val)
    missing = [k for k in suite.env_keys if k not in env]
    if missing:
        raise RuntimeError(f"adapter env missing required keys: {missing}")
    return env


def build_script(block: TestBlock, code: str, ctx: dict[str, str]) -> str:
    """Wrap the doc block into an executable script with referenced vars exported."""
    refs = sorted(set(VAR_REF_RE.findall(code)))
    exports = []
    for ref in refs:
        if ref in ctx:
            exports.append(f"export {ref}={shlex.quote(ctx[ref])}")
    return "#!/usr/bin/env bash\nset -euo pipefail\n" + "\n".join(exports) + "\n\n" + code


def file_write_script(dest: str, content: str) -> str:
    b64 = base64.b64encode(content.encode()).decode()
    dest_q = shlex.quote(dest)
    return (
        "#!/usr/bin/env bash\nset -euo pipefail\n"
        f"mkdir -p \"$(dirname {dest_q})\" 2>/dev/null || true\n"
        f"printf '%s' {shlex.quote(b64)} | base64 -d > {dest_q}\n"
        f"echo wrote {dest_q}\n"
    )


def run_local(cmd: str, ctx: dict[str, str], timeout: int) -> subprocess.CompletedProcess:
    env = {**os.environ, **ctx}
    return subprocess.run(["bash", "-c", cmd], capture_output=True, text=True,
                          timeout=timeout, env=env)


def apply_subst(block: TestBlock, ctx: dict[str, str]) -> str:
    code = block.code
    for literal, replacement in block.subst.items():
        code = code.replace(literal, expand_vars(replacement, ctx))
    return code


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--suite", type=Path, required=True)
    ap.add_argument("--adapter", required=True,
                    help="path to the lab-adapter executable (mock: scripts/adapters/mock/mock-adapter.sh)")
    ap.add_argument("--var", action="append", default=[], metavar="KEY=VALUE",
                    help="supply a required_var (repeatable)")
    ap.add_argument("--dry-run", action="store_true",
                    help="print the execution plan; call nothing")
    ap.add_argument("--report-dir", type=Path, default=None)
    args = ap.parse_args()

    try:
        suite = load_suite(args.suite)
        blocks = suite_blocks(suite)
    except (ParseError, OSError) as exc:
        print(f"ERROR {exc}", file=sys.stderr)
        return 2

    lint_errors = lint(suite, blocks)
    if lint_errors:
        for e in lint_errors:
            print(f"T1-ERROR {e}", file=sys.stderr)
        return 2

    provided: dict[str, str] = {}
    for pair in args.var:
        if "=" not in pair:
            print(f"--var expects KEY=VALUE, got {pair!r}", file=sys.stderr)
            return 2
        k, _, v = pair.partition("=")
        provided[k] = v
    missing_req = [v for v in suite.required_vars if v not in provided and v not in os.environ]
    if missing_req and not args.dry_run:
        print(f"missing required_vars (pass with --var): {missing_req}", file=sys.stderr)
        return 2
    for v in suite.required_vars:
        if v not in provided and v in os.environ:
            provided[v] = os.environ[v]

    if args.dry_run:
        print(f"suite: {suite.name}  ({len(blocks)} blocks)  teardown={suite.teardown}")
        print(f"adapter (not called): {args.adapter}")
        for b in blocks:
            mode = f"write file:{b.file}" if b.file else f"exec [{b.lang}]"
            extras = []
            if b.needs:
                extras.append(f"needs={b.needs}")
            if b.capture:
                extras.append(f"capture={list(b.capture)}")
            if b.until:
                extras.append(f"until (x{b.retry['attempts']} every {b.retry['delay']}s)")
            if b.when:
                extras.append(f"when={b.when}")
            print(f"  {b.id:32s} host={b.host:12s} {mode}  {' '.join(extras)}")
        print("dry-run: no adapter calls made")
        return 0

    adapter = args.adapter
    report_dir = args.report_dir or (
        suite.root / ".poc-test-artifacts" /
        dt.datetime.now().strftime("%Y%m%d-%H%M%S"))
    report_dir.mkdir(parents=True, exist_ok=True)

    results: list[dict] = []
    overall = "PASSED"
    passed_ids: set[str] = set()
    ctx: dict[str, str] = {}
    teardown_ran = False

    try:
        log(f"== adapter setup ({adapter})")
        hosts = adapter_setup(adapter, suite)
        env = adapter_env(adapter, suite)
        ctx.update(suite.vars)
        ctx.update(provided)
        ctx.update(env)
        ctx["POC_ARTIFACTS"] = str(report_dir)
        for role, info in hosts.items():
            norm = re.sub(r"[^A-Z0-9]", "_", role.upper())
            ctx[f"POC_HOST_{norm}_ADDR"] = str(info.get("address", ""))
            ctx[f"POC_HOST_{norm}_USER"] = str(info.get("user", ""))

        stopped = False
        for block in blocks:
            entry = {"id": block.id, "page": block.page, "line": block.line,
                     "host": block.host, "status": "NOTRUN", "detail": ""}
            results.append(entry)
            if stopped:
                entry["status"], entry["detail"] = "SKIPPED", "earlier block failed"
                continue
            if block.when and not ctx.get(block.when, os.environ.get(block.when, "")):
                entry["status"], entry["detail"] = "SKIPPED", f"when: {block.when} not set"
                log(f"-- {block.id}: SKIPPED ({block.when} not set)")
                continue
            if any(dep not in passed_ids for dep in block.needs):
                entry["status"], entry["detail"] = "SKIPPED", "dependency did not pass"
                log(f"-- {block.id}: SKIPPED (dependency did not pass)")
                continue

            log(f"-- {block.id} (host={block.host})")
            started = time.monotonic()
            try:
                code = apply_subst(block, ctx)
                script = (file_write_script(expand_vars(block.file, ctx), expand_vars(code, ctx))
                          if block.file else build_script(block, code, ctx))

                def attempt_once() -> dict[str, str]:
                    """Run the block once: exec + capture + assert. Raises on failure."""
                    with tempfile.NamedTemporaryFile("w", suffix=".sh", delete=False) as fh:
                        fh.write(script)
                        script_path = fh.name
                    os.chmod(script_path, 0o700)
                    try:
                        if block.host == "local":
                            # "local" runs on the runner box; it never reaches the adapter.
                            proc = subprocess.run(["bash", script_path], capture_output=True,
                                                  text=True, timeout=block.timeout)
                        else:
                            proc = run_adapter(adapter, ["exec", block.host, script_path],
                                               timeout=block.timeout)
                    finally:
                        os.unlink(script_path)

                    stdout_file = report_dir / f"{block.id}.stdout"
                    stdout_file.write_text(MASK.clean(proc.stdout))
                    (report_dir / f"{block.id}.stderr").write_text(MASK.clean(proc.stderr))
                    if proc.returncode != 0:
                        raise RuntimeError(
                            f"block exited {proc.returncode}; stderr tail: "
                            f"{MASK.clean(proc.stderr.strip()[-400:])}")

                    lctx = {**ctx, "POC_STDOUT": str(stdout_file)}
                    for var, filt in block.capture.items():
                        cap = subprocess.run(["bash", "-c", filt], input=proc.stdout,
                                             capture_output=True, text=True, timeout=60,
                                             env={**os.environ, **lctx})
                        if cap.returncode != 0:
                            raise RuntimeError(
                                f"capture {var} filter failed: {cap.stderr.strip()[:200]}")
                        ctx[var] = cap.stdout.strip()
                        lctx[var] = ctx[var]
                        if not ctx[var]:
                            log(f"   warn: capture {var} is empty")

                    if block.assert_cmd:
                        a = run_local(block.assert_cmd, lctx, timeout=120)
                        if a.returncode != 0:
                            raise RuntimeError(
                                f"assert failed (rc={a.returncode}): "
                                f"{MASK.clean((a.stderr or a.stdout).strip()[:300])}")
                    return lctx

                # retry without until: re-run the whole block until it passes.
                block_attempts = 1 if block.until else block.retry["attempts"]
                local_ctx: dict[str, str] = {}
                for attempt in range(1, block_attempts + 1):
                    try:
                        local_ctx = attempt_once()
                        break
                    except RuntimeError:
                        if attempt >= block_attempts:
                            raise
                        log(f"   attempt {attempt}/{block_attempts} failed — "
                            f"retrying in {block.retry['delay']}s")
                        time.sleep(block.retry["delay"])

                if block.until:
                    attempts, delay = block.retry["attempts"], block.retry["delay"]
                    ok = False
                    for attempt in range(1, attempts + 1):
                        u = run_local(block.until, local_ctx, timeout=120)
                        if u.returncode == 0:
                            ok = True
                            break
                        if attempt < attempts:
                            time.sleep(delay)
                    if not ok:
                        raise RuntimeError(
                            f"until: condition never met after {attempts} attempts")

                entry["status"] = "PASSED"
                passed_ids.add(block.id)
                log(f"   PASSED ({time.monotonic() - started:.1f}s)")
            except subprocess.TimeoutExpired:
                entry["status"], entry["detail"] = "FAILED", f"timed out after {block.timeout}s"
                overall, stopped = "FAILED", True
                log(f"   FAILED (timeout {block.timeout}s)")
            except RuntimeError as exc:
                entry["status"], entry["detail"] = "FAILED", MASK.clean(str(exc))
                overall, stopped = "FAILED", True
                log(f"   FAILED: {exc}")
            entry["duration_s"] = round(time.monotonic() - started, 1)

    except (RuntimeError, subprocess.TimeoutExpired) as exc:
        overall = "FAILED"
        log(f"FATAL: {exc}")
    finally:
        want_teardown = (suite.teardown == "always"
                         or (suite.teardown == "on-success" and overall == "PASSED"))
        if want_teardown:
            log("== adapter teardown")
            try:
                td = run_adapter(adapter, ["teardown", "--suite", str(suite.path)])
                teardown_ran = td.returncode == 0
                if not teardown_ran:
                    log(f"teardown FAILED (rc={td.returncode}): {td.stderr.strip()[:400]}")
            except (OSError, subprocess.TimeoutExpired) as exc:
                log(f"teardown FAILED: {exc}")

    report = {
        "suite": suite.name,
        "result": overall,
        "ran_at": dt.datetime.now().isoformat(timespec="seconds"),
        "adapter": os.path.basename(adapter),
        "teardown": {"policy": suite.teardown, "ran": teardown_ran},
        "blocks": results,
    }
    (report_dir / "report.json").write_text(MASK.clean(json.dumps(report, indent=2)))
    md = [f"# POC doc test report — {suite.name}", "",
          f"**Result: {overall}** — {report['ran_at']} via `{report['adapter']}`", "",
          "| block | page | status | detail |", "|---|---|---|---|"]
    for r in results:
        md.append(f"| `{r['id']}` | {r['page']}:{r['line']} | {r['status']} | {r['detail']} |")
    (report_dir / "report.md").write_text(MASK.clean("\n".join(md) + "\n"))

    log(f"== {overall} — report: {report_dir}")
    return 0 if overall == "PASSED" else 1


if __name__ == "__main__":
    sys.exit(main())
