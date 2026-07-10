#!/usr/bin/env python3
"""Scan the shareable skills/ tree for personal-infrastructure leaks and secrets.

Skills in skills/ are published; they must never contain real lab identifiers
(IP ranges, hostnames, vault names, handles) or credential material.
private-skills/ is exempt by design and is not scanned.

Exits 1 with file:line findings if anything matches.
"""

import re
import sys
from pathlib import Path

# Only real lab identifiers and credential shapes. Generic RFC1918 examples
# (10.x, 192.168.x) are legitimate documentation placeholders and NOT flagged.
PATTERNS = [
    ("lab IP range", re.compile(r"172\.1[89]\.\d{1,3}\.\d{1,3}")),
    ("MaaS hostname", re.compile(r"\b[\w-]+\.maas\b")),
    ("internal .lan hostname", re.compile(r"\b[\w-]+\.lan\b")),
    ("lab hostname", re.compile(r"subtle-bug", re.IGNORECASE)),
    ("personal handle", re.compile(r"nctiggy", re.IGNORECASE)),
    ("tenant name", re.compile(r"\bmouser\b", re.IGNORECASE)),
    ("1Password secret reference", re.compile(r"op://[A-Za-z0-9]")),
    ("1Password vault name", re.compile(r"k8s vault", re.IGNORECASE)),
    ("Anthropic API key", re.compile(r"sk-ant-[A-Za-z0-9-]{10,}")),
    ("GitHub token", re.compile(r"\bghp_[A-Za-z0-9]{20,}")),
    ("JWT-like token", re.compile(r"\beyJ[A-Za-z0-9_-]{30,}")),
]

# Text extensions worth scanning. SVGs are skipped: path coordinate data
# false-positives on IP-like patterns and carries no prose.
SCAN_EXTS = {".md", ".py", ".sh", ".yaml", ".yml", ".json", ".txt",
             ".mjs", ".js", ".html", ".css", ".hcl", ".tf", ".toml", ".arg"}

# Deliberate exceptions: the poc-docs secret-scanner test fixtures exist to
# exercise its scanner and MUST contain dirty content.
EXEMPT_DIRS = [
    Path("skills/spectrocloud-poc-docs/tests"),
]


def is_exempt(path: Path) -> bool:
    return any(path.is_relative_to(d) for d in EXEMPT_DIRS)


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("skills")
    findings = []

    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in SCAN_EXTS:
            continue
        if is_exempt(path):
            continue
        try:
            text = path.read_text(errors="replace")
        except OSError:
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            for label, pattern in PATTERNS:
                if pattern.search(line):
                    findings.append((path, lineno, label, line.strip()[:120]))

    if findings:
        print(f"SECRET SCAN FAILED: {len(findings)} finding(s) in {root}/\n")
        for path, lineno, label, snippet in findings:
            print(f"  {path}:{lineno}  [{label}]  {snippet}")
        print("\nShareable skills must not contain lab identifiers or secrets "
              "(see CLAUDE.md Content Guidelines). Use placeholders instead.")
        return 1

    print(f"Secret scan clean: {root}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
