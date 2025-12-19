#!/usr/bin/env python3
"""Initialize a new skill from template."""

import argparse
import os
import re
import sys
from pathlib import Path

SKILL_TEMPLATE = '''---
name: {name}
description: {description}
---

# {title}

Brief description of what this skill does.

## When to Use

Describe the trigger conditions for this skill.

## Usage

How to invoke and use this skill.
'''


def validate_skill_name(name: str) -> bool:
    """Validate skill name is kebab-case and max 64 chars."""
    if len(name) > 64:
        return False
    return bool(re.match(r'^[a-z][a-z0-9]*(-[a-z0-9]+)*$', name))


def init_skill(name: str, description: str = "", base_dir: Path = None) -> Path:
    """Create a new skill directory with template SKILL.md."""
    if base_dir is None:
        base_dir = Path(__file__).parent.parent / "skills"

    if not validate_skill_name(name):
        raise ValueError(
            f"Invalid skill name '{name}'. Must be kebab-case, "
            "start with letter, max 64 chars."
        )

    skill_dir = base_dir / name
    if skill_dir.exists():
        raise FileExistsError(f"Skill directory already exists: {skill_dir}")

    skill_dir.mkdir(parents=True)

    # Generate title from name
    title = name.replace("-", " ").title()

    # Use provided description or generate default
    if not description:
        description = f"A skill for {title.lower()}. TODO: Update this description."

    # Ensure description doesn't exceed 1024 chars
    if len(description) > 1024:
        description = description[:1021] + "..."

    skill_md = skill_dir / "SKILL.md"
    skill_md.write_text(SKILL_TEMPLATE.format(
        name=name,
        description=description,
        title=title
    ))

    return skill_dir


def main():
    parser = argparse.ArgumentParser(
        description="Initialize a new Claude skill from template"
    )
    parser.add_argument(
        "name",
        help="Skill name in kebab-case (e.g., my-skill-name)"
    )
    parser.add_argument(
        "-d", "--description",
        default="",
        help="Short description (max 1024 chars)"
    )
    parser.add_argument(
        "--base-dir",
        type=Path,
        default=None,
        help="Base directory for skills (default: skills/)"
    )

    args = parser.parse_args()

    try:
        skill_dir = init_skill(args.name, args.description, args.base_dir)
        print(f"Created skill: {skill_dir}")
        print(f"Edit {skill_dir}/SKILL.md to customize your skill")
    except (ValueError, FileExistsError) as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
