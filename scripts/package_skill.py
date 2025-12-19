#!/usr/bin/env python3
"""Package a skill directory into a .skill (zip) file."""

import argparse
import os
import sys
import zipfile
from pathlib import Path

# Import validation from quick_validate
from quick_validate import validate_skill


def package_skill(skill_path: Path, output_dir: Path = None, validate: bool = True) -> Path:
    """Package a skill directory into a .skill file."""
    skill_path = Path(skill_path)

    if not skill_path.is_dir():
        raise ValueError(f"Not a directory: {skill_path}")

    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        raise ValueError(f"Missing SKILL.md in {skill_path}")

    # Validate if requested
    if validate:
        errors = validate_skill(skill_path)
        if errors:
            raise ValueError(f"Validation failed:\n" + "\n".join(f"  - {e}" for e in errors))

    # Determine output path
    skill_name = skill_path.name
    if output_dir is None:
        output_dir = Path(__file__).parent.parent / "dist"

    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{skill_name}.skill"

    # Create zip file
    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(skill_path):
            # Skip hidden directories and __pycache__
            dirs[:] = [d for d in dirs if not d.startswith('.') and d != '__pycache__']

            for file in files:
                # Skip hidden files and .pyc
                if file.startswith('.') or file.endswith('.pyc'):
                    continue

                file_path = Path(root) / file
                arcname = file_path.relative_to(skill_path)
                zf.write(file_path, arcname)

    return output_path


def main():
    parser = argparse.ArgumentParser(
        description="Package a skill directory into a .skill file"
    )
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        help="Skill directories to package (default: all in skills/)"
    )
    parser.add_argument(
        "-o", "--output-dir",
        type=Path,
        default=None,
        help="Output directory (default: dist/)"
    )
    parser.add_argument(
        "--no-validate",
        action="store_true",
        help="Skip validation before packaging"
    )

    args = parser.parse_args()

    # If no paths specified, package all skills
    paths = args.paths
    if not paths:
        skills_dir = Path(__file__).parent.parent / "skills"
        paths = [p for p in skills_dir.iterdir() if p.is_dir() and (p / "SKILL.md").exists()]

    if not paths:
        print("No skills found to package", file=sys.stderr)
        sys.exit(1)

    success = True
    packaged = []

    for path in paths:
        try:
            output = package_skill(
                path,
                output_dir=args.output_dir,
                validate=not args.no_validate
            )
            print(f"Packaged: {output}")
            packaged.append(output)
        except ValueError as e:
            print(f"Error packaging {path}: {e}", file=sys.stderr)
            success = False

    if packaged:
        print(f"\nPackaged {len(packaged)} skill(s)")

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
