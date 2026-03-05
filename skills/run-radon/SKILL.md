---
name: run-radon
description: Run radon to measure cyclomatic complexity (CC) and maintainability index (MI) of Python files. Use this skill when the user asks about "maintainability", "cyclomatic complexity", "code health", or "technical debt", or as part of the iterate-until-clean loop. Critical: radon always exits 0 even on violations — you must parse stdout, never rely on exit code. Always use this skill rather than running radon directly.
---

# run-radon Skill

Run radon to check cyclomatic complexity (CC) and maintainability index (MI).

## CRITICAL: radon Always Exits 0

Unlike ruff and complexipy, radon NEVER exits non-zero — even when thresholds are
violated. Parse stdout to detect violations. Do not treat exit 0 as "clean".

## How to Use

`task python:maintainability FILES=<path>` runs two commands back-to-back:
1. `radon cc -n <RADON_CC_MIN_GRADE> <path>` — lists functions at the threshold grade or worse
2. `radon mi <path>` — lists MI scores for all files

Thresholds from `py-lint-driven.local.md` (defaults if file missing):
- `radon_cc_min_grade` — worst acceptable CC grade (default: C). Functions graded D, E, F are violations.
- `radon_mi_floor` — minimum acceptable MI score 0–100 (default: 20). Files below this are violations.

## Parsing radon cc Output

`radon cc -n C` lists functions graded C or worse (C, D, E, F). Each line shows:
```
src/module.py
    F process_data:10 - D (25)
    M validate:45 - B (8)
```
Format: `<type> <name>:<line> - <grade> (<score>)`
Types: F=function, M=method, C=class

Grade scale: A (1–5), B (6–10), C (11–15), D (16–20), E (21–25), F (26+)
A function is a violation if its grade is worse than `radon_cc_min_grade` (i.e., later in alphabet).

## Parsing radon mi Output

```
src/module.py - A (67.42)
src/utils.py - C (12.38)
```
MI score is the number in parentheses (0–100, higher is better).
A file is a violation if its MI score is below `radon_mi_floor`.

## Return Format

```
Radon violations:

Cyclomatic Complexity (threshold: C or better):
- process_data in src/module.py — grade D, score 25

Maintainability Index (floor: 20):
- src/utils.py — MI 12.38 (below floor of 20)
```

If clean: "radon: all functions and files within thresholds"
