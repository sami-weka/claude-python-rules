---
name: write-tests
description: Given a source file path or function description, generate a failing pytest test file in tests/. Tests are written before implementation (TDD red state). Confirms tests fail after writing.
triggers:
  - "write tests"
  - "generate tests"
  - "create test file"
---

# write-tests Skill

Generate a failing pytest test file for a given source file or description.

## Rules

1. Write tests BEFORE looking at implementation (if implementation exists, ignore it)
2. Tests must fail initially — this is the TDD red state
3. One test per logical behavior, not one per line of code
4. Test file goes in `tests/test_<module_name>.py`

## What to Generate

For each public function/class in the source:
- One happy path test (normal inputs, expected output)
- One or two edge case tests (empty input, boundary values, None, etc.)
- Base tests on type annotations and docstrings — not on implementation

## Test File Structure

```python
import pytest
from <module> import <function>


def test_<function>_happy_path():
    result = <function>(<normal_input>)
    assert result == <expected_output>


def test_<function>_edge_case():
    result = <function>(<edge_input>)
    assert result == <edge_expected>


def test_<function>_invalid_input():
    with pytest.raises(<ExceptionType>):
        <function>(<invalid_input>)
```

## After Writing

Run `task python:test:file FILE=tests/test_<module>.py` to confirm tests fail.

Expected output: FAILED (one or more tests)

If tests PASS before implementation exists, the tests are wrong — revise them.

## Return

Confirm the red state:
```
Tests written: tests/test_module.py
Red state confirmed: 3 tests, 0 passed, 3 failed ✓
```
