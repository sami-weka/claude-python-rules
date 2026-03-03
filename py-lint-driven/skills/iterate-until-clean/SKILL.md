---
name: iterate-until-clean
description: Core quality loop. Runs fix pass then verify pass, repeating until tests pass and linting is clean, or iteration_limit is hit. Always uses full lint — never the fast variant. Used by /tdd and /lint-fix commands.
triggers:
  - "iterate until clean"
  - "fix and verify loop"
  - "clean the code"
---

# iterate-until-clean Skill

The core fix/verify loop. Keeps trying until everything is green or the limit is hit.

## IMPORTANT: Always Full Lint

This skill always runs full lint (ruff + complexipy + radon). Never the fast variant.
The fast/full distinction (hooks_run_complexity) applies to hooks only, not this skill.

## Loop Structure

Read `iteration_limit` from py-lint-driven.local.md (default: 5).

For each iteration (starting at 1):

### Fix Pass
Run `task python:tdd:fix`
This runs: test → ruff:fix → complexity check → maintainability check → fmt

The lint-iterator agent handles failures:
- Test failures → agent fixes implementation logic
- ruff violations remaining after auto-fix → agent fixes manually
- Complexity violations → agent proposes refactor, waits for user confirmation
- Maintainability violations → agent flags, proposes simplification

### Verify Pass
Run `task python:tdd`
This runs: test → full lint (read-only, no fixes)

If verify pass is fully green → done, report success.
If still dirty → increment iteration counter, repeat.

## On Limit Hit

Do NOT silently fail. Report clearly:
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
