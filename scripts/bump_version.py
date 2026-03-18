#!/usr/bin/env python3
"""Compute a new semver from the current version and a bump type.

Usage: bump_version.py <current_version> <patch|minor|major>
Prints the new version to stdout.
"""
import sys


def main() -> None:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <version> <patch|minor|major>", file=sys.stderr)
        sys.exit(1)

    version, bump_type = sys.argv[1], sys.argv[2]

    try:
        major, minor, patch = (int(x) for x in version.split("."))
    except ValueError:
        print(f"Invalid version: {version}", file=sys.stderr)
        sys.exit(1)

    if bump_type == "major":
        major, minor, patch = major + 1, 0, 0
    elif bump_type == "minor":
        major, minor, patch = major, minor + 1, 0
    elif bump_type == "patch":
        patch += 1
    else:
        print(f"Unknown bump type: {bump_type} (use patch, minor, or major)", file=sys.stderr)
        sys.exit(1)

    print(f"{major}.{minor}.{patch}")


if __name__ == "__main__":
    main()
