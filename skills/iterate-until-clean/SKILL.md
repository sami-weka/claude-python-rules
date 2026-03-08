---
name: iterate-until-clean
description: Core fix/verify loop that runs until tests pass and linting is clean, or the iteration limit is hit. Use this skill whenever you need to drive code from a failing/dirty state to fully green — after writing implementation, after a user asks to "fix all issues", or as part of /tdd and /lint-fix commands. Always runs full lint (ruff + complexipy + xenon), never the fast variant. If you're fixing code and not sure when to stop, use this skill.
---

# iterate-until-clean Skill

The core fix/verify loop. Keeps trying until everything is green or the limit is hit.

## Config

Read these values from `py-lint-driven.local.md` if it exists. Use defaults if missing:

- `iteration_limit` → default: 5
- `xenon_max_absolute` → default: B
- `xenon_max_modules` → default: A
- `xenon_max_average` → default: A

Set the xenon values as env vars before every task invocation that includes xenon:
`XENON_MAX_ABSOLUTE=<value> XENON_MAX_MODULES=<value> XENON_MAX_AVERAGE=<value>`

complexipy reads its threshold from `pyproject.toml` `[tool.complexipy]` natively —
no env var needed.

## Always Full Lint

This skill always runs full lint (ruff + complexipy + xenon). The fast/full distinction
(`hooks_run_complexity`) applies only to hooks — never to this skill.

## Loop Structure

For each iteration (starting at 1):

### Fix Pass
Run with xenon thresholds as env vars:
`XENON_MAX_ABSOLUTE=<value> XENON_MAX_MODULES=<value> XENON_MAX_AVERAGE=<value> task python:tdd:fix`

This runs: test → ruff:fix → complexity check → cyclomatic check → fmt

Handle each failure type:
- **Test failures** → fix implementation logic in source files. Never modify test files.
- **ruff violations after auto-fix** → fix manually. ruff:fix handles most cases; remaining ones need code changes.
- **Complexity violations (complexipy)** → propose a specific refactor strategy, wait for user confirmation, then apply.
- **Cyclomatic violations (xenon)** → same as complexity: propose a refactor, confirm with user, then apply.

### Verify Pass
Run with the same xenon env var prefix:
`XENON_MAX_ABSOLUTE=<value> XENON_MAX_MODULES=<value> XENON_MAX_AVERAGE=<value> task python:tdd`

This runs: test → ruff → complexipy → xenon (read-only, no fixes)

If fully green → done. Report success and stop.
If still dirty → increment counter, repeat.

## On Limit Hit

Report clearly, do not silently fail:
```
Iteration limit (5) reached. Remaining issues:
- Tests: 1 still failing — tests/test_module.py::test_edge_case
- Ruff: 2 violations — src/module.py:45, src/utils.py:12
- Complexity (complexipy): 1 function still above threshold — process_data (score: 18)
- Cyclomatic (xenon): grade B exceeded in src/module.py

Action required: fix these manually before proceeding.
```

## Return on Success

```
Clean after <N> iteration(s):
- Tests fixed: <N>
- Ruff violations fixed: <N>
- Format issues fixed: <N>
All checks passing ✓
```
