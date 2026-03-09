---
name: lint-check
description: Read-only quality audit. Runs tests and full linting with no fixes applied. Safe to run before a pull request. Displays a quality report.
argument-hint: "[path — optional, defaults to current directory]"
---

# /lint-check Command

Read-only audit — no files are modified.

## Arguments

`$ARGUMENTS` — optional path. Defaults to `.`.

## Flow

1. **Run full quality check (parallel, read-only)**
   Invoke the `quality-analyzer` agent with `$ARGUMENTS` (or `.`) and xenon env vars
   from `py-lint-driven.local.md`. It runs tests, ruff, complexipy, and xenon in
   parallel and returns a combined status with all findings including combined findings.

2. **Also check Taskfile setup**
   If `Taskfile.yaml` or `taskfiles/Taskfile.python.yaml` do not exist, generate
   them from `py-lint-driven/templates/` now.
   If `py-lint-driven.local.md` does not exist in the project root, copy the
   template from `py-lint-driven/templates/py-lint-driven.local.md`.
   If `.github/workflows/python-quality.yml` does not exist, copy it from
   `py-lint-driven/templates/.github/workflows/python-quality.yml`.

3. **Report**
   Use the `report-quality` skill to display results.
   Report is read-only — clearly state that no fixes were applied.
