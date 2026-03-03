---
name: run-radon
description: Run radon to measure cyclomatic complexity (CC) and maintainability index (MI) of Python files. Parses stdout to enforce thresholds since radon always exits 0. Returns offending functions and files.
triggers:
  - "run radon"
  - "check maintainability"
  - "cyclomatic complexity"
  - "maintainability index"
---

# run-radon Skill

Run radon to check cyclomatic complexity (CC) and maintainability index (MI).

## CRITICAL: radon Always Exits 0

Unlike ruff and complexipy, radon NEVER exits non-zero — even when thresholds are
violated. You MUST parse stdout to determine whether violations exist.

## How to Use

Call `task python:maintainability FILES=<path>`.

This runs two commands:
1. `radon cc -n <RADON_CC_MIN_GRADE> <path>` — shows functions at or below the grade
2. `radon mi <path>` — shows MI scores for all files

Read thresholds from py-lint-driven.local.md:
- `radon_cc_min_grade` — grade cutoff (A=best, F=worst). Default: C
- `radon_mi_floor` — MI floor (0-100). Below this is a violation. Default: 20

## Parsing radon cc Output

radon cc outputs functions in format:
```
src/module.py
    F process_data:10 - D (25)
    M validate:45 - B (8)
```

Grade letters: A (1-5), B (6-10), C (11-15), D (16-20), E (21-25), F (26+)
A function is a violation if its grade is WORSE than radon_cc_min_grade.
"Worse" means later in the alphabet: C is worse than A, D is worse than C.

## Parsing radon mi Output

radon mi outputs:
```
src/module.py - A (67.42)
src/utils.py - C (12.38)
```

Grade: A (>= 20 MI score), B (10-19), C (< 10)
A file is a violation if its MI score is BELOW radon_mi_floor.

## Return Format

```
Radon violations:

Cyclomatic Complexity (threshold: C or better):
- process_data in src/module.py — grade D, score 25

Maintainability Index (floor: 20):
- src/utils.py — MI 12.38 (below floor of 20)
```

If clean, return: "radon: all functions and files within thresholds"
