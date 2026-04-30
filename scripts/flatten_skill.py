#!/usr/bin/env python3
"""Flatten a skill into a single self-contained Markdown file.

Inlines all references/*.md content and assets/*.svg files so the output
can be used as a prompt for any AI (Codex, ChatGPT, Gemini, etc.) without
needing file-system access.

Usage:
    python3 scripts/flatten_skill.py skills/exec-doc-generator
    python3 scripts/flatten_skill.py skills/exec-doc-generator -o dist/flattened/
    python3 scripts/flatten_skill.py --all
"""

import argparse
import os
import sys
import glob
import re

def read_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def flatten_skill(skill_dir, output_dir=None):
    skill_md = os.path.join(skill_dir, 'SKILL.md')
    if not os.path.isfile(skill_md):
        print(f"SKIP: {skill_dir} (no SKILL.md)")
        return None

    skill_name = os.path.basename(skill_dir.rstrip('/'))
    content = read_file(skill_md)

    # Strip YAML frontmatter for the flattened version (keep as comment)
    if content.startswith('---'):
        end = content.index('---', 3)
        frontmatter = content[3:end].strip()
        content = f"<!-- Skill: {skill_name} -->\n<!-- {frontmatter.replace(chr(10), ' | ')} -->\n\n" + content[end+3:].strip()

    # Replace READ references with inlined content
    refs_dir = os.path.join(skill_dir, 'references')
    if os.path.isdir(refs_dir):
        for ref_file in sorted(glob.glob(os.path.join(refs_dir, '*.md'))):
            ref_name = os.path.basename(ref_file)
            ref_content = read_file(ref_file)
            # Add section header and inline
            inline_block = f"\n\n---\n\n<!-- Inlined from references/{ref_name} -->\n\n{ref_content}\n\n---\n"
            # Replace READ references to this file
            content = re.sub(
                rf'READ\s+(?:the\s+)?`references/{re.escape(ref_name)}`[^\n]*',
                f'(See inlined content from references/{ref_name} below)',
                content
            )
            content += inline_block

    # Inline SVG assets as code blocks
    assets_dir = os.path.join(skill_dir, 'assets')
    if os.path.isdir(assets_dir):
        svg_files = sorted(glob.glob(os.path.join(assets_dir, '*.svg')))
        if svg_files:
            content += "\n\n---\n\n## Inline SVG Assets\n\n"
            for svg_file in svg_files:
                svg_name = os.path.basename(svg_file)
                svg_content = read_file(svg_file)
                content += f"### {svg_name}\n\n```html\n{svg_content.strip()}\n```\n\n"

    # Inline icon SVGs as a reference list
    icons_dir = os.path.join(assets_dir, 'icons') if os.path.isdir(assets_dir) else None
    if icons_dir and os.path.isdir(icons_dir):
        icon_files = sorted(glob.glob(os.path.join(icons_dir, '*.svg')))
        if icon_files:
            content += f"\n### Brand Icons ({len(icon_files)} available)\n\n"
            for icon_file in icon_files:
                icon_name = os.path.basename(icon_file)
                content += f"- `{icon_name}`\n"
            content += "\n(Icon SVG content available in the skill assets but omitted for brevity)\n"

    # Determine output path
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        out_path = os.path.join(output_dir, f"{skill_name}.flat.md")
    else:
        out_path = os.path.join('dist', 'flattened', f"{skill_name}.flat.md")
        os.makedirs(os.path.dirname(out_path), exist_ok=True)

    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(content)

    line_count = content.count('\n') + 1
    print(f"FLAT: {skill_name} → {out_path} ({line_count} lines)")
    return out_path


def main():
    parser = argparse.ArgumentParser(description='Flatten skills into self-contained prompts')
    parser.add_argument('skill_dir', nargs='?', help='Path to skill directory')
    parser.add_argument('-o', '--output', help='Output directory')
    parser.add_argument('--all', action='store_true', help='Flatten all skills')
    args = parser.parse_args()

    if args.all:
        skills_dir = 'skills'
        for entry in sorted(os.listdir(skills_dir)):
            skill_path = os.path.join(skills_dir, entry)
            if os.path.isdir(skill_path) and os.path.isfile(os.path.join(skill_path, 'SKILL.md')):
                flatten_skill(skill_path, args.output)
    elif args.skill_dir:
        flatten_skill(args.skill_dir, args.output)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == '__main__':
    main()
