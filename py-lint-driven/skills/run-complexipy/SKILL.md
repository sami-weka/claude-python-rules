---
name: run-complexipy
description: Run complexipy to measure cognitive complexity of Python functions. Exits non-zero when any function exceeds the configured threshold. Returns a list of offending functions with name, file, line, and score.
triggers:
  - "run complexipy"
  - "check cognitive complexity"
  - "complexity violations"
---

# run-complexipy Skill

Run complexipy to detect functions with excessive cognitive complexity.

## How to Use

Call `task python:complexity FILES=<path>` (or `task python:complexity` for whole project).

The threshold is configured via MAX_COGNITIVE_COMPLEXITY in taskfiles/Taskfile.python.yaml
(default: 15). Read the current value from py-lint-driven.local.md (max_cognitive_complexity).

## Key Fact: Exit Codes

complexipy exits non-zero when ANY function exceeds the threshold. This means task chains
(like `task python:lint`) will stop and fail when complexity violations are found.

## Parsing Output

complexipy outputs one block per file. Each function shows name, score, and PASSED/FAILED.
Violations are also listed in a summary section:

```
src/module.py
    process_data 18 FAILED
    helper 3 PASSED

Failed functions:
 - src/module.py: process_data
```

Exit code is non-zero when any function fails. Parse the `Failed functions:` section
to extract violating functions and their scores from the per-file block above it.

Use `complexipy -f <path>` to show only failing functions (cleaner output for iteration).

## Return Format

```
Complexity violations (threshold: 15):
- process_data in src/module.py — score: 18 (exceeds by 3)
- validate_input in src/utils.py — score: 22 (exceeds by 7)
```

If clean, return: "complexipy: all functions within threshold"

## Fixing Complexity Violations

Complexity violations cannot be auto-fixed. The lint-iterator agent must propose a
refactor strategy and get user confirmation before restructuring logic.
