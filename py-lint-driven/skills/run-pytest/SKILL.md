---
name: run-pytest
description: "Reference skill — defines pytest invocation, output format, and the critical collection-error vs assertion-failure distinction used by lint-iterator and quality-analyzer. Use directly when you need to run tests, verify a TDD red state, or when the user says 'run tests', 'do the tests pass', or 'verify my changes'."
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
→ Stop immediately and surface to the user. Do NOT iterate on collection errors.
  The test file is broken and must be fixed before anything else can run.

**Assertion failures** (tests run but fail):
```
FAILED tests/test_module.py::test_process - AssertionError: assert 0 == 1
```
→ Expected in TDD red state. Fix the implementation (never the test) and re-run.

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

## Coverage

To see which lines are not covered by tests:
```bash
task python:test:coverage
```

To enforce a minimum coverage threshold (fails if below MIN_COVERAGE, default 80%):
```bash
task python:test:coverage:check
```

Change the threshold by editing `MIN_COVERAGE` in `taskfiles/Taskfile.python.yaml`.

## Conftest and Import Path

If pytest can't find modules (ModuleNotFoundError), check that `conftest.py` exists
at the project root with `sys.path.insert(0, str(Path(__file__).parent))`.
The `/setup` command creates this automatically — run it if missing.
