---
name: quality-report
description: Deep complexity analysis. Runs ruff, complexipy, and xenon (no tests). Highlights the 5 most complex functions. Saves a timestamped report.
argument-hint: "[path — optional, defaults to current directory]"
allowed-tools:
  - Bash(task python:*)
  - Bash(ruff check*)
  - Bash(complexipy*)
  - Bash(xenon*)
  - Write(.claude/py-lint-driven/reports/*)
---

# /quality-report Command

Deep quality analysis focused on complexity metrics.

## Arguments

`$ARGUMENTS` — optional path. Defaults to `.`.

## Flow

1. **Read config**
   Read `py-lint-driven.local.md` for xenon threshold values. Defaults:
   `xenon_max_absolute=B, xenon_max_modules=A, xenon_max_average=A`

2. **Run lint check**
   Run `task python:ruff FILES=$ARGUMENTS` — collect ruff violations.

3. **Run cognitive complexity check**
   Run `task python:complexity FILES=$ARGUMENTS`
   complexipy reads its threshold from `pyproject.toml` `[tool.complexipy]` automatically.
   Use the `run-complexipy` skill to parse and format output.

4. **Run cyclomatic complexity check**
   Run `XENON_MAX_ABSOLUTE=<value> XENON_MAX_MODULES=<value> XENON_MAX_AVERAGE=<value> task python:cyclomatic`
   (xenon always analyzes the full project, `$ARGUMENTS` is not applied here)

5. **Build deep report**
   Use the `report-quality` skill. Include:
   - Top 5 most complex functions (highest complexipy score)
   - Cyclomatic complexity grade summary (xenon output)
   - Full list of ruff violations

6. **Save report**
   Save to `.claude/py-lint-driven/reports/YYYY-MM-DD-HH-MM-<sanitized-path>.md`
   Create the directory if it doesn't exist.
   Inform the user where the report was saved.
