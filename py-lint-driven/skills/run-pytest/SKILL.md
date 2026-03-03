---
name: run-pytest
description: Run pytest on the tests/ directory or a specific test file. Returns structured pass/fail results. Distinguishes collection errors (broken imports) from assertion failures.
triggers:
  - "run pytest"
  - "run tests"
  - "check tests"
---

# run-pytest Skill

Run pytest and return structured test results.

## How to Use

Full suite: `task python:test`
Single file: `task python:test:file FILE=tests/test_module.py`

pytest exits non-zero on any failure or collection error.

## Two Types of Failures — Handle Differently

**Collection errors** (broken imports, syntax errors in test files):
```
ERROR collecting tests/test_module.py
ImportError: cannot import name 'process' from 'module'
```
→ Surface immediately to the user. Do NOT iterate on collection errors —
  the test file itself is broken and needs a fix before anything else.

**Assertion failures** (tests run but fail):
```
FAILED tests/test_module.py::test_process - AssertionError: assert 0 == 1
```
→ These are expected in TDD red state. Iterate on these by fixing implementation.

## Return Format

On failure:
```
Tests: 2 passed, 1 failed

FAILED: tests/test_module.py::test_process
  AssertionError: assert result == expected
  File: tests/test_module.py, line 12
```

On pass:
```
Tests: 3 passed, 0 failed ✓
```

On collection error:
```
COLLECTION ERROR — tests cannot run:
  tests/test_module.py: ImportError: cannot import name 'process'
  Fix the import before iterating.
```
