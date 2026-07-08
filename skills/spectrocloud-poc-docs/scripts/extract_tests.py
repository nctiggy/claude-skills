#!/usr/bin/env python3
"""extract_tests.py — parse and lint `poc-test` annotations (T1), and serve as the
parsing library for run_doc_tests.py (T2).

Annotation format (an HTML comment immediately before a fenced code block — invisible
in the rendered MkDocs site, no plugin needed):

    <!-- poc-test
    id: create-token          # required; unique kebab-case id
    host: local               # required; "local" or a host role from the suite manifest
    needs: [earlier-id]       # optional; ids that must have run (and passed) first
    timeout: 300              # optional; seconds, default 600
    file: user-data           # optional; write block content to this path on the host
                              #   instead of executing it (for yaml/config blocks)
    subst:                    # optional; literal doc text -> runtime replacement
      "<registration-token>": "$TOKEN"
    capture:                  # optional; VAR: shell filter piped the block's stdout
      TOKEN: "tail -n1"
    assert: test -n "$TOKEN"  # optional; local shell cmd, exit 0 = pass.
                              #   env: captured vars, suite vars, POC_STDOUT (path to stdout file)
    until: some-poll-cmd      # optional; local shell cmd polled until exit 0
    retry:                    # optional; with until: polls the condition.
      attempts: 30            #   WITHOUT until: re-runs the whole block
      delay: 20               #   (exec+capture+assert) until it passes.
    when: GPU_PRESENT         # optional; skip unless this var is set truthy at run time
    -->

Suite manifest (docs-site/poc-test-suite.yaml):

    suite: name
    pages: [docs/phase-1.md, ...]          # executed in listed order
    adapter_requirements:
      hosts: [node]                        # roles the lab adapter must provide
      env: [PALETTE_API_KEY, PROJECT_UID]  # keys the adapter's `env` must emit
    vars: {CLUSTER_NAME: poctest-x}        # fixed vars
    required_vars: [INFRA_PROFILE_UID]     # must be passed via --var at run time
    teardown: always                       # always | on-success | never

The runner auto-provides POC_HOST_<ROLE>_ADDR and POC_HOST_<ROLE>_USER for every
adapter host role, plus POC_STDOUT and POC_ARTIFACTS.

CLI:
  extract_tests.py --suite <poc-test-suite.yaml>   # full T1 lint (exit 1 on errors)
  extract_tests.py <page.md> [--json]              # parse one page, print blocks
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import textwrap
from dataclasses import dataclass, field
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    print("pyyaml required: pip install pyyaml", file=sys.stderr)
    sys.exit(2)

ANNOT_OPEN = re.compile(r"^\s*<!--\s*poc-test\s*$")
ANNOT_CLOSE = re.compile(r"^\s*-->\s*$")
FENCE_RE = re.compile(r"^(\s*)(`{3,}|~{3,})(.*)$")
ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
VAR_REF_RE = re.compile(r"\$\{?([A-Z][A-Z0-9_]*)\}?")
SHELL_LANGS = {"bash", "sh", "shell", "console", "zsh"}
KNOWN_KEYS = {"id", "host", "needs", "timeout", "file", "subst", "capture",
              "assert", "until", "retry", "when"}
AUTO_VARS = {"POC_STDOUT", "POC_ARTIFACTS"}
DEFAULT_TIMEOUT = 600


@dataclass
class TestBlock:
    id: str
    host: str
    page: str
    line: int                      # 1-based line of the annotation open
    lang: str = ""
    code: str = ""
    needs: list[str] = field(default_factory=list)
    timeout: int = DEFAULT_TIMEOUT
    file: str | None = None
    subst: dict[str, str] = field(default_factory=dict)
    capture: dict[str, str] = field(default_factory=dict)
    assert_cmd: str | None = None
    until: str | None = None
    retry: dict = field(default_factory=lambda: {"attempts": 1, "delay": 10})
    when: str | None = None

    def as_dict(self):
        d = {k: v for k, v in self.__dict__.items()}
        return d


@dataclass
class Suite:
    name: str
    path: Path
    pages: list[str]
    hosts: list[str]
    env_keys: list[str]
    vars: dict[str, str]
    required_vars: list[str]
    teardown: str

    @property
    def root(self) -> Path:
        return self.path.parent


class ParseError(Exception):
    pass


def _parse_annotation(page: str, lines: list[str], start: int) -> tuple[dict, int]:
    """Parse annotation starting at `start` (index of the open marker).
    Returns (yaml-dict, index-after-close-marker)."""
    body: list[str] = []
    i = start + 1
    while i < len(lines):
        if ANNOT_CLOSE.match(lines[i]):
            break
        body.append(lines[i])
        i += 1
    else:
        raise ParseError(f"{page}:{start + 1}: poc-test comment never closed with -->")
    try:
        data = yaml.safe_load(textwrap.dedent("\n".join(body))) or {}
    except yaml.YAMLError as exc:
        raise ParseError(f"{page}:{start + 1}: bad YAML in poc-test annotation: {exc}") from exc
    if not isinstance(data, dict):
        raise ParseError(f"{page}:{start + 1}: poc-test annotation must be a YAML mapping")
    return data, i + 1


def _next_fenced_block(page: str, lines: list[str], i: int) -> tuple[str, str, int]:
    """Find the fenced code block starting at/after line index i (blank lines allowed).
    Returns (lang, dedented code, index-after-block)."""
    while i < len(lines) and not lines[i].strip():
        i += 1
    if i >= len(lines):
        raise ParseError(f"{page}:{i}: poc-test annotation not followed by a code block")
    m = FENCE_RE.match(lines[i])
    if not m:
        raise ParseError(f"{page}:{i + 1}: poc-test annotation must be followed by a fenced code block")
    indent, marker, info = m.group(1), m.group(2), m.group(3).strip()
    lang = info.split()[0].strip("{}. ") if info else ""
    code_lines: list[str] = []
    i += 1
    while i < len(lines):
        cm = FENCE_RE.match(lines[i])
        if cm and cm.group(2)[0] == marker[0] and len(cm.group(2)) >= len(marker) \
                and not cm.group(3).strip():
            return lang, textwrap.dedent("\n".join(code_lines)) + "\n", i + 1
        code_lines.append(lines[i])
        i += 1
    raise ParseError(f"{page}:{i}: unterminated code block after poc-test annotation")


def parse_page(path: Path, rel_name: str | None = None) -> list[TestBlock]:
    """Extract all annotated blocks from one markdown page, in document order."""
    page = rel_name or str(path)
    lines = path.read_text(encoding="utf-8").splitlines()
    blocks: list[TestBlock] = []
    i = 0
    while i < len(lines):
        if not ANNOT_OPEN.match(lines[i]):
            i += 1
            continue
        annot_line = i + 1
        data, i = _parse_annotation(page, lines, i)
        lang, code, i = _next_fenced_block(page, lines, i)
        block = TestBlock(
            id=str(data.get("id", "")),
            host=str(data.get("host", "")),
            page=page,
            line=annot_line,
            lang=lang,
            code=code,
            needs=list(data.get("needs") or []),
            timeout=int(data.get("timeout") or DEFAULT_TIMEOUT),
            file=data.get("file"),
            subst={str(k): str(v) for k, v in (data.get("subst") or {}).items()},
            capture={str(k): str(v) for k, v in (data.get("capture") or {}).items()},
            assert_cmd=data.get("assert"),
            until=data.get("until"),
            retry={"attempts": int((data.get("retry") or {}).get("attempts", 1)),
                   "delay": int((data.get("retry") or {}).get("delay", 10))},
            when=data.get("when"),
        )
        block._unknown_keys = sorted(set(data) - KNOWN_KEYS)  # type: ignore[attr-defined]
        blocks.append(block)
    return blocks


def load_suite(path: Path) -> Suite:
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    req = data.get("adapter_requirements") or {}
    return Suite(
        name=str(data.get("suite") or path.parent.name),
        path=path.resolve(),
        pages=list(data.get("pages") or []),
        hosts=[str(h) for h in (req.get("hosts") or [])],
        env_keys=[str(k) for k in (req.get("env") or [])],
        vars={str(k): str(v) for k, v in (data.get("vars") or {}).items()},
        required_vars=[str(v) for v in (data.get("required_vars") or [])],
        teardown=str(data.get("teardown") or "always"),
    )


def suite_blocks(suite: Suite) -> list[TestBlock]:
    """All annotated blocks across the suite's pages, in execution order."""
    blocks: list[TestBlock] = []
    for page in suite.pages:
        page_path = suite.root / page
        if not page_path.exists():
            raise ParseError(f"{suite.path}: page not found: {page}")
        blocks.extend(parse_page(page_path, page))
    return blocks


def known_vars(suite: Suite, prior_captures: set[str]) -> set[str]:
    auto = set(AUTO_VARS)
    for role in suite.hosts:
        norm = re.sub(r"[^A-Z0-9]", "_", role.upper())
        auto.add(f"POC_HOST_{norm}_ADDR")
        auto.add(f"POC_HOST_{norm}_USER")
    return set(suite.vars) | set(suite.required_vars) | set(suite.env_keys) \
        | prior_captures | auto


def lint(suite: Suite, blocks: list[TestBlock]) -> list[str]:
    """T1 lint. Returns error strings (empty = clean)."""
    errors: list[str] = []
    seen_ids: set[str] = set()
    captures_so_far: set[str] = set()

    if suite.teardown not in ("always", "on-success", "never"):
        errors.append(f"{suite.path}: teardown must be always|on-success|never, got {suite.teardown!r}")
    if not blocks:
        errors.append(f"{suite.path}: no poc-test annotations found in listed pages")

    for b in blocks:
        loc = f"{b.page}:{b.line} [{b.id or '?'}]"
        for key in getattr(b, "_unknown_keys", []):
            errors.append(f"{loc}: unknown annotation key {key!r}")
        if not b.id or not ID_RE.match(b.id):
            errors.append(f"{loc}: id is required and must be kebab-case")
        elif b.id in seen_ids:
            errors.append(f"{loc}: duplicate id {b.id!r}")
        if not b.host:
            errors.append(f"{loc}: host is required ('local' or one of {suite.hosts})")
        elif b.host != "local" and b.host not in suite.hosts:
            errors.append(f"{loc}: host {b.host!r} not in adapter_requirements.hosts {suite.hosts}")
        for dep in b.needs:
            if dep not in seen_ids:
                errors.append(f"{loc}: needs {dep!r} which is not an earlier block id")
        if b.file:
            if b.capture:
                errors.append(f"{loc}: capture is invalid with file: (nothing executes)")
        elif b.lang not in SHELL_LANGS:
            errors.append(f"{loc}: language {b.lang or '(none)'!r} is not executable — "
                          f"use file: to write it out, or annotate a shell block")
        if b.retry != {"attempts": 1, "delay": 10} and not b.until and b.file:
            errors.append(f"{loc}: retry: is meaningless on a file: block")
        if b.timeout <= 0:
            errors.append(f"{loc}: timeout must be positive")

        avail = known_vars(suite, captures_so_far)
        # subst is applied BEFORE the block runs: own captures don't exist yet.
        subst_refs: set[str] = set()
        for text in b.subst.values():
            subst_refs.update(VAR_REF_RE.findall(text))
        # assert/until run AFTER capture: the block's own captures are in scope.
        post_refs: set[str] = set()
        for text in [b.assert_cmd or "", b.until or ""]:
            post_refs.update(VAR_REF_RE.findall(text))
        for ref in sorted(subst_refs):
            if ref not in avail:
                errors.append(f"{loc}: ${ref} in subst is not resolvable (not in suite vars, "
                              f"required_vars, adapter env, auto vars, or earlier captures)")
        for ref in sorted(post_refs):
            if ref not in avail | set(b.capture):
                errors.append(f"{loc}: ${ref} in assert/until is not resolvable (not in suite "
                              f"vars, required_vars, adapter env, auto vars, or captures)")
        if b.when and b.when not in avail and not re.match(r"^[A-Z][A-Z0-9_]*$", b.when):
            errors.append(f"{loc}: when: must name a variable")

        if b.id:
            seen_ids.add(b.id)
        captures_so_far.update(b.capture)

    return errors


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("page", nargs="?", type=Path, help="a single markdown page to parse")
    ap.add_argument("--suite", type=Path, help="poc-test-suite.yaml to fully lint (T1)")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    if bool(args.page) == bool(args.suite):
        ap.error("pass exactly one of: <page.md> or --suite <suite.yaml>")

    try:
        if args.suite:
            suite = load_suite(args.suite)
            blocks = suite_blocks(suite)
            errors = lint(suite, blocks)
            if args.json:
                print(json.dumps({"suite": suite.name, "blocks": [b.as_dict() for b in blocks],
                                  "errors": errors}, indent=2, default=str))
            else:
                for e in errors:
                    print(f"ERROR {e}")
                print(f"extract_tests: {len(blocks)} block(s), {len(errors)} error(s)")
            return 1 if errors else 0

        blocks = parse_page(args.page)
        if args.json:
            print(json.dumps([b.as_dict() for b in blocks], indent=2, default=str))
        else:
            for b in blocks:
                print(f"{b.page}:{b.line}  {b.id}  host={b.host}  lang={b.lang}"
                      f"{'  file=' + b.file if b.file else ''}")
            print(f"extract_tests: {len(blocks)} block(s)")
        return 0
    except ParseError as exc:
        print(f"ERROR {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
