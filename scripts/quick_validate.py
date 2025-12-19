#!/usr/bin/env python3
"""Validate SKILL.md frontmatter and structure."""

import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("Error: pyyaml required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


def extract_frontmatter(content: str) -> tuple[dict, str]:
    """Extract YAML frontmatter from markdown content."""
    if not content.startswith("---"):
        return {}, content

    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}, content

    try:
        frontmatter = yaml.safe_load(parts[1])
        body = parts[2].strip()
        return frontmatter or {}, body
    except yaml.YAMLError as e:
        raise ValueError(f"Invalid YAML frontmatter: {e}")


def validate_name(name: str) -> list[str]:
    """Validate skill name."""
    errors = []

    if not name:
        errors.append("Missing required field: name")
        return errors

    if len(name) > 64:
        errors.append(f"Name exceeds 64 characters: {len(name)}")

    if not re.match(r'^[a-z][a-z0-9]*(-[a-z0-9]+)*$', name):
        errors.append(
            f"Name must be kebab-case, start with letter: '{name}'"
        )

    return errors


def validate_description(description: str) -> list[str]:
    """Validate skill description."""
    errors = []

    if not description:
        errors.append("Missing required field: description")
        return errors

    if len(description) > 1024:
        errors.append(f"Description exceeds 1024 characters: {len(description)}")

    if "<" in description or ">" in description:
        errors.append("Description cannot contain angle brackets (< or >)")

    return errors


def validate_skill(skill_path: Path) -> list[str]:
    """Validate a skill directory."""
    errors = []

    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        errors.append(f"Missing SKILL.md in {skill_path}")
        return errors

    content = skill_md.read_text()

    try:
        frontmatter, body = extract_frontmatter(content)
    except ValueError as e:
        errors.append(str(e))
        return errors

    if not frontmatter:
        errors.append("Missing YAML frontmatter (must start with ---)")
        return errors

    # Validate required fields
    errors.extend(validate_name(frontmatter.get("name", "")))
    errors.extend(validate_description(frontmatter.get("description", "")))

    # Check line count
    lines = content.count("\n") + 1
    if lines > 500:
        errors.append(
            f"SKILL.md exceeds 500 lines ({lines}). "
            "Consider splitting into references/"
        )

    # Check body word count (soft limit)
    words = len(body.split())
    if words > 5000:
        errors.append(
            f"SKILL.md body exceeds 5000 words ({words}). "
            "Consider splitting into references/"
        )

    return errors


def main():
    parser = argparse.ArgumentParser(
        description="Validate SKILL.md frontmatter and structure"
    )
    parser.add_argument(
        "paths",
        nargs="+",
        type=Path,
        help="Skill directories to validate"
    )
    parser.add_argument(
        "-q", "--quiet",
        action="store_true",
        help="Only output errors"
    )

    args = parser.parse_args()

    all_valid = True

    for path in args.paths:
        skill_path = Path(path)

        # Handle both directory and SKILL.md path
        if skill_path.name == "SKILL.md":
            skill_path = skill_path.parent

        if not skill_path.is_dir():
            print(f"Error: Not a directory: {skill_path}", file=sys.stderr)
            all_valid = False
            continue

        errors = validate_skill(skill_path)

        if errors:
            all_valid = False
            print(f"INVALID: {skill_path}")
            for error in errors:
                print(f"  - {error}")
        elif not args.quiet:
            print(f"VALID: {skill_path}")

    sys.exit(0 if all_valid else 1)


if __name__ == "__main__":
    main()
