---
name: tdd-test
description: Generate tests for an existing source file without writing implementation. Useful for adding test coverage to legacy code. Shows failing state and stops.
argument-hint: "<path to source file>"
---

# /tdd-test Command

Generate tests for an existing source file. Does not write implementation.

## Arguments

`$ARGUMENTS` — path to the source file to generate tests for
Example: `/tdd-test src/utils.py`

## Flow

1. **Read the source file** at `$ARGUMENTS`
   Identify all public functions and classes.

2. **Write failing tests**
   Use the `write-tests` skill to generate `tests/test_<module>.py`.
   Write tests based on function signatures, type annotations, and docstrings.
   Do NOT look at the implementation body — treat it as a black box.

3. **Confirm red state**
   Run `task python:test:file FILE=tests/test_<module>.py`.
   Expected: tests fail (the implementation may exist but tests are written
   against the spec, not the current behavior).

4. **Stop**
   Do not write or modify any implementation.
   Inform the user: "Tests written. Run `/lint-fix` to iterate until clean,
   or fix the implementation manually."
