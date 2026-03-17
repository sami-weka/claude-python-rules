---
name: run-ruff
description: "Reference skill — defines ruff invocation patterns, output format, and parsing conventions used by lint-iterator and quality-analyzer. Use directly when you need to check or fix Python style violations, unused imports, or formatting issues, or when the user asks to 'lint', 'check style', 'fix imports', or 'clean up' Python code."
---

# run-ruff Skill

Run ruff on a Python file or directory and return structured results.

## How to Use

Check mode (read-only): `task python:ruff FILES=<path>`
Check whole project: `task python:ruff`
Auto-fix mode: `task python:ruff:fix FILES=<path>`
Format: `task python:fmt FILES=<path>`
Format check: `task python:fmt:check FILES=<path>`

Ruff picks up config automatically from `pyproject.toml` or `ruff.toml` if present.

## Parsing Output

Ruff outputs one violation per line:
```
path/to/file.py:10:5: E501 Line too long (92 > 88 characters)
```

Format: `<file>:<line>:<col>: <rule> <message>`

Exit 0 = clean. Non-zero = violations found.

## Return Format

```
File: path/to/file.py
Line 10, Col 5: E501 — Line too long (92 > 88 characters)
Line 23, Col 1: F401 — 'os' imported but unused
```

If clean: "ruff: no violations found"

## Fix Mode

`task python:ruff:fix` auto-fixes the majority of violations. A small number (complex
logic issues, ambiguous rewrites) require manual fixes. After auto-fixing, always
re-run check mode to confirm the file is clean before moving on.
