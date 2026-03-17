---
name: autopilot
description: Full development lifecycle for a Python feature — from design through implementation, tests, linting, documentation, and advisory design review. Use when building something new end-to-end. Covers everything /tdd covers plus a design phase, documentation, and pre-commit review.
argument-hint: "<description of what to build>"
allowed-tools:
  - Write(src/*)
  - Write(tests/*)
  - Edit(src/*)
  - Edit(tests/*)
  - Bash(task python:*)
---

# /autopilot Command

Full lifecycle for building a Python feature. Covers design → tests → implement →
clean → document → review.

## Arguments

`$ARGUMENTS` — natural language description of the feature to build.
Example: `/autopilot a service that validates and stores user email preferences`

## Flow

### Phase 1: Design

Before writing any code, think through:
- What types/dataclasses are needed? Any primitive obsession to avoid?
- What module does this belong in? What are the public vs private functions?
- What are the failure modes? How should errors be surfaced?
- What does the public API look like?

Output a brief design summary (5–10 lines) and ask the user to confirm or adjust
before proceeding. Do not skip this step.

### Phase 2: Write failing tests (red state)

Use the `write-tests` skill to generate `tests/test_<module>.py`.
Run `task python:test:file FILE=tests/test_<module>.py` to confirm red state.
If tests pass before implementation exists — revise them.

### Phase 3: Write implementation

Write `src/<module>.py` with the minimal implementation to satisfy the tests.
Follow the design from Phase 1. Do not over-engineer.

### Phase 4: Iterate until clean

Use the `iterate-until-clean` skill.
Runs fix pass + verify pass up to `iteration_limit` times.

### Phase 5: Documentation

Use the `documentation` skill on the new file(s).
Write module docstring, function docstrings, and fill any missing type annotations.

### Phase 6: Advisory design review

Use the `pre-commit-review` skill on the new file(s).
This is advisory — surface findings to the user, who decides what to address.
If there are 🔴 Design Debt findings, discuss with the user before finishing.

### Phase 7: Final report

Use the `report-quality` skill for the final quality summary.

```
Autopilot complete: src/<module>.py

Phase 1 — Design:       confirmed
Phase 2 — Tests:        3 tests written, red state confirmed
Phase 3 — Implement:    src/<module>.py written
Phase 4 — Clean:        2 iterations, all checks passing ✓
Phase 5 — Docs:         module + 3 function docstrings added
Phase 6 — Review:       1 readability finding (advisory, noted)
Phase 7 — Quality:      PASS ✓
```
