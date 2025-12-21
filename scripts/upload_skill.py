#!/usr/bin/env python3
"""Upload skills to Anthropic API."""

import argparse
import json
import os
import sys
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError
import mimetypes

# Import from local modules
from package_skill import package_skill

try:
    import yaml
except ImportError:
    yaml = None

API_BASE = "https://api.anthropic.com/v1/skills"
API_VERSION = "2023-06-01"
API_BETA = "skills-2025-10-02"


def get_api_key() -> str:
    """Get API key from environment."""
    key = os.environ.get("ANTHROPIC_API_KEY")
    if not key:
        raise ValueError("ANTHROPIC_API_KEY environment variable not set")
    return key


def get_headers(api_key: str) -> dict:
    """Get common headers for API requests."""
    return {
        "x-api-key": api_key,
        "anthropic-version": API_VERSION,
        "anthropic-beta": API_BETA,
    }


def extract_title_from_skill(skill_path: Path) -> str:
    """Extract display title from skill SKILL.md frontmatter."""
    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        return skill_path.name.replace("-", " ").title()

    content = skill_md.read_text()
    if not content.startswith("---"):
        return skill_path.name.replace("-", " ").title()

    parts = content.split("---", 2)
    if len(parts) < 3:
        return skill_path.name.replace("-", " ").title()

    if yaml:
        try:
            frontmatter = yaml.safe_load(parts[1])
            # Use display_title if present, otherwise generate from name
            if frontmatter.get("display_title"):
                return frontmatter["display_title"]
            if frontmatter.get("name"):
                return frontmatter["name"].replace("-", " ").title()
        except Exception:
            pass

    return skill_path.name.replace("-", " ").title()


def create_multipart_body(fields: dict, files: dict) -> tuple[bytes, str]:
    """Create multipart form data body."""
    boundary = "----SkillUploadBoundary"
    body_parts = []

    # Add form fields
    for name, value in fields.items():
        body_parts.append(f"--{boundary}".encode())
        body_parts.append(f'Content-Disposition: form-data; name="{name}"'.encode())
        body_parts.append(b"")
        body_parts.append(value.encode() if isinstance(value, str) else value)

    # Add files
    for name, (filename, content) in files.items():
        mime_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"
        body_parts.append(f"--{boundary}".encode())
        body_parts.append(
            f'Content-Disposition: form-data; name="{name}"; filename="{filename}"'.encode()
        )
        body_parts.append(f"Content-Type: {mime_type}".encode())
        body_parts.append(b"")
        body_parts.append(content)

    body_parts.append(f"--{boundary}--".encode())

    body = b"\r\n".join(body_parts)
    content_type = f"multipart/form-data; boundary={boundary}"

    return body, content_type


def find_skill_by_title(display_title: str, api_key: str) -> str | None:
    """Find a skill ID by its display title."""
    try:
        skills = list_skills(api_key)
        for skill in skills:
            title = skill.get("display_title", skill.get("name", ""))
            if title == display_title:
                return skill.get("id", skill.get("skill_id"))
    except Exception:
        pass
    return None


def upload_skill(skill_path: Path, api_key: str = None, force: bool = False) -> dict:
    """Package and upload a skill to the Anthropic API.

    If force=True, deletes existing skill with same title before uploading.
    """
    if api_key is None:
        api_key = get_api_key()

    skill_path = Path(skill_path)

    # Package the skill
    print(f"Packaging {skill_path.name}...")
    package_path = package_skill(skill_path, validate=True)

    # Get display title
    display_title = extract_title_from_skill(skill_path)

    # If force mode, delete existing skill with same title
    if force:
        existing_id = find_skill_by_title(display_title, api_key)
        if existing_id:
            print(f"Deleting existing skill '{display_title}' (ID: {existing_id})...")
            try:
                delete_skill(existing_id, api_key)
            except ValueError as e:
                print(f"Warning: Could not delete existing skill: {e}")

    # Read package content
    with open(package_path, "rb") as f:
        package_content = f.read()

    # Create multipart body
    body, content_type = create_multipart_body(
        fields={"display_title": display_title},
        files={"files[]": (f"{skill_path.name}.zip", package_content)}
    )

    # Upload
    print(f"Uploading {skill_path.name} as '{display_title}'...")
    headers = get_headers(api_key)
    headers["Content-Type"] = content_type

    req = Request(API_BASE, data=body, headers=headers, method="POST")

    try:
        with urlopen(req) as response:
            result = json.loads(response.read().decode())
            return result
    except HTTPError as e:
        error_body = e.read().decode()
        try:
            error_json = json.loads(error_body)
            raise ValueError(f"API error ({e.code}): {json.dumps(error_json, indent=2)}")
        except json.JSONDecodeError:
            raise ValueError(f"API error ({e.code}): {error_body}")


def list_skills(api_key: str = None) -> list:
    """List all skills from the Anthropic API."""
    if api_key is None:
        api_key = get_api_key()

    headers = get_headers(api_key)
    req = Request(API_BASE, headers=headers, method="GET")

    try:
        with urlopen(req) as response:
            result = json.loads(response.read().decode())
            return result.get("data", result)
    except HTTPError as e:
        error_body = e.read().decode()
        raise ValueError(f"API error ({e.code}): {error_body}")


def delete_skill(skill_id: str, api_key: str = None) -> bool:
    """Delete a skill from the Anthropic API."""
    if api_key is None:
        api_key = get_api_key()

    headers = get_headers(api_key)
    url = f"{API_BASE}/{skill_id}"
    req = Request(url, headers=headers, method="DELETE")

    try:
        with urlopen(req) as response:
            return response.status == 200 or response.status == 204
    except HTTPError as e:
        if e.code == 404:
            raise ValueError(f"Skill not found: {skill_id}")
        error_body = e.read().decode()
        raise ValueError(f"API error ({e.code}): {error_body}")


def main():
    parser = argparse.ArgumentParser(
        description="Upload skills to Anthropic API"
    )
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        help="Skill directories to upload"
    )
    parser.add_argument(
        "--list",
        action="store_true",
        dest="list_skills",
        help="List all skills from the API"
    )
    parser.add_argument(
        "--delete",
        metavar="SKILL_ID",
        help="Delete a skill by ID"
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Upload all skills in skills/ directory"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Delete existing skill with same title before uploading"
    )

    args = parser.parse_args()

    try:
        api_key = get_api_key()
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    # Handle --list
    if args.list_skills:
        try:
            skills = list_skills(api_key)
            if not skills:
                print("No skills found")
            else:
                print(f"Found {len(skills)} skill(s):\n")
                for skill in skills:
                    skill_id = skill.get("id", skill.get("skill_id", "unknown"))
                    title = skill.get("display_title", skill.get("name", "Untitled"))
                    created = skill.get("created_at", "")
                    print(f"  {skill_id}")
                    print(f"    Title: {title}")
                    if created:
                        print(f"    Created: {created}")
                    print()
        except ValueError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
        return

    # Handle --delete
    if args.delete:
        try:
            delete_skill(args.delete, api_key)
            print(f"Deleted skill: {args.delete}")
        except ValueError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
        return

    # Handle upload
    paths = args.paths
    if args.all or not paths:
        skills_dir = Path(__file__).parent.parent / "skills"
        paths = [p for p in skills_dir.iterdir() if p.is_dir() and (p / "SKILL.md").exists()]

    if not paths:
        print("No skills found to upload. Use --list to view existing skills.")
        sys.exit(0)

    success = True
    uploaded = []

    for path in paths:
        try:
            result = upload_skill(path, api_key, force=args.force)
            skill_id = result.get("id", result.get("skill_id", "unknown"))
            print(f"Success! Skill ID: {skill_id}")
            uploaded.append((path.name, skill_id))
        except ValueError as e:
            print(f"Error uploading {path}: {e}", file=sys.stderr)
            success = False
        except URLError as e:
            print(f"Network error uploading {path}: {e}", file=sys.stderr)
            success = False

    if uploaded:
        print(f"\nUploaded {len(uploaded)} skill(s):")
        for name, skill_id in uploaded:
            print(f"  {name}: {skill_id}")

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
