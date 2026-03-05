---
name: quality-report
description: Deep complexity analysis. Runs ruff and complexipy only (no tests). Highlights the 5 most complex functions. Saves a timestamped report.
argument-hint: "[path — optional, defaults to current directory]"
---

# /quality-report Command

Deep quality analysis focused on complexity metrics.

## Arguments

`$ARGUMENTS` — optional path. Defaults to `.`.

## Flow

1. **Run lint check**
   Run `task python:ruff FILES=$ARGUMENTS` — collect ruff violations.

2. **Run complexity check**
   Call `run-complexipy` skill: `task python:complexity FILES=$ARGUMENTS`

3. **Build deep report**
   Use the `report-quality` skill. Include:
   - Top 5 most complex functions (highest complexipy score)
   - Full list of ruff violations

4. **Save report**
   Save to `.claude/py-lint-driven/reports/YYYY-MM-DD-HH-MM-<sanitized-path>.md`
   Create the directory if it doesn't exist.
   Inform the user where the report was saved.
