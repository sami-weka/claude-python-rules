---
name: tdd
description: Test-driven development entry point. Write a description of what to build — Claude writes failing tests first, then implementation, then iterates until both tests pass and linting is clean.
argument-hint: "<description of what to build>"
---

# /tdd Command

Given a description of what to build, run the full TDD cycle.

## Arguments

`$ARGUMENTS` — natural language description of the feature to build
Example: `/tdd a function that validates email addresses`

## Flow

1. **Determine file names**
   From `$ARGUMENTS`, determine:
   - Source file: `src/<module>.py` (or appropriate path)
   - Test file: `tests/test_<module>.py`

2. **Write failing tests** (red state)
   Use the `write-tests` skill to generate `tests/test_<module>.py`.
   Run `task python:test:file FILE=tests/test_<module>.py` to confirm tests fail.
   If tests pass before implementation exists — the tests are wrong, revise them.

3. **Write implementation**
   Write `src/<module>.py` with the minimal implementation to satisfy the tests.
   Do not over-engineer — write only what the tests require (YAGNI).

4. **Iterate until clean**
   Use the `iterate-until-clean` skill.
   It runs fix pass (`task python:tdd:fix`) then verify pass (`task python:tdd`),
   repeating up to `iteration_limit` times until everything is green.

5. **Report**
   Use the `report-quality` skill to display the final quality summary.
