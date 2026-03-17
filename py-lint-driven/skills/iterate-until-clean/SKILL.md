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
- `tdd_enabled` → true

Prefix xenon tasks with env vars: `XENON_MAX_ABSOLUTE=<v> XENON_MAX_MODULES=<v> XENON_MAX_AVERAGE=<v>`
complexipy reads threshold from `pyproject.toml` `[tool.complexipy]` natively.

## Scope (optional)

When called with `scope: git`, restrict linting to git-changed files only.
Compute changed files once before the loop by running `task python:git:changed-py`.
If the result is empty, fall back to `.` (no git changes detected).
Tests always run on the full suite regardless of scope.

## Loop

For each iteration:

**Fix pass** (sequential — order matters):

Task selection based on `tdd_enabled` and `scope`:

| tdd_enabled | scope | fix task |
|---|---|---|
| true | default | `task python:tdd:fix` |
| true | git | `task python:tdd:fix:git` |
| false | default | `task python:lint:fix` |
| false | git | `task python:lint:fix:git` |

Prefix with xenon env vars: `XENON_MAX_ABSOLUTE=<v> XENON_MAX_MODULES=<v> XENON_MAX_AVERAGE=<v> <task>`

**Verify pass** (parallel — use `quality-analyzer` agent):
Invoke the `quality-analyzer` agent with xenon env vars and:
- Default scope: `files: .`
- `scope: git`: `files: <changed files computed above>`

When `tdd_enabled: false`, pass `skip_tests: true` to `quality-analyzer` so it skips pytest.

It returns a combined status: CLEAN, TEST_FAILURE (only when tdd_enabled), or ISSUES_FOUND.

- CLEAN → done, report success
- TEST_FAILURE with COLLECTION ERROR → stop, surface to user, do not iterate
- TEST_FAILURE or ISSUES_FOUND → fix and repeat up to `iteration_limit`
- Limit hit → report remaining issues explicitly, do not silently fail

Always full lint — never the fast variant regardless of `hooks_run_complexity` config.
Never modify test files.
Complexity/cyclomatic refactors require user confirmation before applying.
