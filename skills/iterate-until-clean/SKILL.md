---
name: iterate-until-clean
description: Core fix/verify loop that runs until tests pass and linting is clean, or the iteration limit is hit. Use this skill whenever you need to drive code from a failing/dirty state to fully green — after writing implementation, after a user asks to "fix all issues", or as part of /tdd and /lint-fix commands. Always runs full lint (ruff + complexipy + radon), never the fast variant. If you're fixing code and not sure when to stop, use this skill.
---

# iterate-until-clean Skill

The core fix/verify loop. Keeps trying until everything is green or the limit is hit.

## Config

Read `iteration_limit` from `py-lint-driven.local.md` if it exists. If the file is
missing, use the default: `iteration_limit = 5`.

## Always Full Lint

This skill always runs full lint (ruff + complexipy + radon). The fast/full distinction
(`hooks_run_complexity`) applies only to hooks — never to this skill.

## Loop Structure

For each iteration (starting at 1):

### Fix Pass
Run `task python:tdd:fix`
This runs: test → ruff:fix → complexity check → maintainability check → fmt

Handle each failure type:
- **Test failures** → fix implementation logic in source files. Never modify test files.
- **ruff violations after auto-fix** → fix manually. ruff:fix handles most cases; remaining ones need code changes.
- **Complexity violations** → propose a specific refactor strategy, wait for user confirmation, then apply.
- **Maintainability violations** → flag to the user and suggest simplification options.

### Verify Pass
Run `task python:tdd`
This runs: test → ruff → complexipy → radon (read-only, no fixes)

If fully green → done. Report success and stop.
If still dirty → increment counter, repeat.

## On Limit Hit

Report clearly, do not silently fail:
```
Iteration limit (5) reached. Remaining issues:
- Tests: 1 still failing — tests/test_module.py::test_edge_case
- Ruff: 2 violations — src/module.py:45, src/utils.py:12
- Complexity: 1 function still above threshold — process_data (score: 18)

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
