---
name: iterate-until-clean
description: Core fix/verify loop that runs until tests pass and linting is clean, or the iteration limit is hit. Use this skill whenever you need to drive code from a failing/dirty state to fully green — after writing implementation, after a user asks to "fix all issues", or as part of /tdd and /lint-fix commands. Always runs full lint (ruff + complexipy + xenon), never the fast variant. If you're fixing code and not sure when to stop, use this skill.
---

# iterate-until-clean Skill

The core fix/verify loop. Keeps trying until everything is green or the limit is hit.
See `reference.md` in this directory for detailed failure handling and fix strategies.

## Config

Read from `py-lint-driven.local.md` (defaults if missing):
- `iteration_limit` → 5
- `xenon_max_absolute` → B
- `xenon_max_modules` → A
- `xenon_max_average` → A

Prefix xenon tasks with env vars: `XENON_MAX_ABSOLUTE=<v> XENON_MAX_MODULES=<v> XENON_MAX_AVERAGE=<v>`
complexipy reads threshold from `pyproject.toml` `[tool.complexipy]` natively.

## Loop

For each iteration:

**Fix pass** (sequential — order matters):
`XENON_MAX_ABSOLUTE=<v> XENON_MAX_MODULES=<v> XENON_MAX_AVERAGE=<v> task python:tdd:fix`
→ test → ruff:fix → complexity → cyclomatic → fmt

**Verify pass** (parallel — use `quality-analyzer` agent):
Invoke the `quality-analyzer` agent with the current files and xenon env vars.
It runs test, ruff, complexipy, and xenon simultaneously and returns a combined
status: CLEAN, TEST_FAILURE, or ISSUES_FOUND.

- CLEAN → done, report success
- TEST_FAILURE with COLLECTION ERROR → stop, surface to user, do not iterate
- TEST_FAILURE or ISSUES_FOUND → fix and repeat up to `iteration_limit`
- Limit hit → report remaining issues explicitly, do not silently fail

Always full lint — never the fast variant regardless of `hooks_run_complexity` config.
Never modify test files.
Complexity/cyclomatic refactors require user confirmation before applying.
