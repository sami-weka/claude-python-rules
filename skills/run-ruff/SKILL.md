---
name: run-ruff
description: Run ruff linter and formatter on Python files. Returns structured violations with file, line, rule code, and message. Supports check mode and auto-fix mode.
triggers:
  - "run ruff"
  - "check ruff violations"
  - "ruff lint"
---

# run-ruff Skill

Run ruff on a Python file or directory and return structured results.

## How to Use

Call `task python:ruff FILES=<path>` (or `task python:ruff` for the whole project).

For auto-fix mode, call `task python:ruff:fix FILES=<path>`.

## Parsing Output

Ruff outputs violations in this format:
```
path/to/file.py:10:5: E501 Line too long (92 > 88 characters)
```

Parse as: `<file>:<line>:<col>: <rule> <message>`

Ruff exits non-zero if violations are found. Exit 0 means clean.

## Return Format

Return a list of violations:
```
File: path/to/file.py
Line 10, Col 5: E501 — Line too long (92 > 88 characters)
```

If clean, return: "ruff: no violations found"

## Fix Mode

In fix mode (`task python:ruff:fix`), ruff auto-fixes what it can. Some violations
require manual fixes (complex logic issues). After fixing, always re-run check mode
to confirm the file is clean.
