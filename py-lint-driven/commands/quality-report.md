---
name: quality-report
description: Deep complexity and maintainability analysis. Runs complexipy and radon only (no ruff, no tests). Highlights the 5 most complex functions and files with poor maintainability. Saves a timestamped report.
argument-hint: "[path — optional, defaults to current directory]"
---

# /quality-report Command

Deep quality analysis focused on complexity and maintainability metrics.

## Arguments

`$ARGUMENTS` — optional path. Defaults to `.`.

## Flow

1. **Run complexity check**
   Call `run-complexipy` skill: `task python:complexity FILES=$ARGUMENTS`

2. **Run maintainability check**
   Call `run-radon` skill: `task python:maintainability FILES=$ARGUMENTS`
   Parse stdout to detect violations (radon always exits 0).

3. **Build deep report**
   Use the `report-quality` skill. Include:
   - Top 5 most complex functions (highest complexipy score)
   - Top 5 worst MI files (lowest radon mi score)
   - Full list of CC violations
   - Full list of MI violations

4. **Save report**
   Save to `.claude/py-lint-driven/reports/YYYY-MM-DD-HH-MM-<sanitized-path>.md`
   Create the directory if it doesn't exist.
   Inform the user where the report was saved.
