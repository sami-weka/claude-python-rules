---
name: run-complexipy
description: Run complexipy to measure cognitive complexity of Python functions. Use this skill whenever you've written or refactored a function and want to check its complexity, when the user mentions "too complex", "hard to read", "deeply nested", or "refactor this function", or when the iterate-until-clean loop reports complexity violations. Always use this before claiming a refactor reduced complexity — verify with the tool.
---

# run-complexipy Skill

Run complexipy to detect functions with excessive cognitive complexity.

## How to Use

Check a file or directory: `task python:complexity FILES=<path>`
Check whole project: `task python:complexity`
Show only failures: `complexipy -f -mx <threshold> <path>`

The threshold comes from `py-lint-driven.local.md` (`max_cognitive_complexity`, default: 15),
which must match `MAX_COGNITIVE_COMPLEXITY` in `taskfiles/Taskfile.python.yaml`.

## Exit Codes Matter

complexipy exits non-zero when ANY function exceeds the threshold. This stops task
chains like `task python:lint` immediately — so a complexity failure will prevent
radon from running in the same chain.

## Parsing Output

complexipy outputs one block per file, with each function on its own line:

```
src/module.py
    process_data 18 FAILED
    helper 3 PASSED

Failed functions:
 - src/module.py: process_data
```

The format is `    <function_name> <score> PASSED|FAILED`. The score is the cognitive
complexity number. To find scores for failed functions, match names from the
`Failed functions:` section back to the per-file block above it.

## Return Format

```
Complexity violations (threshold: 15):
- process_data in src/module.py — score: 18 (exceeds by 3)
- validate_input in src/utils.py — score: 22 (exceeds by 7)
```

If clean: "complexipy: all functions within threshold"

## Fixing Complexity Violations

Complexity cannot be auto-fixed. Common reduction strategies:
- Extract nested blocks into named helper functions
- Replace deeply nested conditionals with early returns
- Split a function that does multiple things into focused pieces

Always propose the refactor and wait for user confirmation before restructuring logic.
