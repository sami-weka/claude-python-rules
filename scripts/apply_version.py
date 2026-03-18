#!/usr/bin/env python3
"""Apply a version string to all plugin JSON files atomically.

Updates every 'version' key found at any depth in:
  - py-lint-driven/plugin.json
  - .claude-plugin/marketplace.json

Usage: apply_version.py <new_version>
"""
import json
import sys
from pathlib import Path


def update_version(data: dict | list, new_version: str) -> None:
    if isinstance(data, dict):
        for key, value in data.items():
            if key == "version" and isinstance(value, str):
                data[key] = new_version
            else:
                update_version(value, new_version)
    elif isinstance(data, list):
        for item in data:
            update_version(item, new_version)


def main() -> None:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <new_version>", file=sys.stderr)
        sys.exit(1)

    new_version = sys.argv[1]
    targets = [
        Path("py-lint-driven/plugin.json"),
        Path(".claude-plugin/marketplace.json"),
    ]

    for path in targets:
        if not path.exists():
            print(f"WARNING: {path} not found, skipping", file=sys.stderr)
            continue
        data = json.loads(path.read_text())
        update_version(data, new_version)
        path.write_text(json.dumps(data, indent=2) + "\n")
        print(f"Updated {path} → {new_version}")


if __name__ == "__main__":
    main()
