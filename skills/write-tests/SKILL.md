---
name: write-tests
description: Generate a failing pytest test file for a source file or feature description. Use this skill at the START of any new feature or function — before writing implementation. Also use it when the user says "write tests for", "add test coverage", "test this module", or "TDD". The goal is always a red state: tests must fail before implementation exists. If you're tempted to look at the implementation first, don't — tests are written against the spec (type annotations, docstrings, function names), not the code.
---

# write-tests Skill

Generate a failing pytest test file for a given source file or description.

## Rules

1. Write tests BEFORE looking at the implementation body — treat it as a black box
2. Base tests on the public API: function names, type annotations, docstrings
3. Tests must fail initially — this confirms the red state
4. One test per logical behavior (happy path, edge case, error case)
5. Test file goes in `tests/test_<module_name>.py`

## What to Generate

For each public function or class:
- **Happy path**: normal inputs, expected output
- **Edge cases**: empty input, zero, None, boundary values, empty collections
- **Error cases**: invalid types or values that should raise exceptions

If there are no type annotations or docstrings, infer behavior from the function name
and parameter names. Write the most reasonable contract you can, then confirm the red
state — if tests pass unexpectedly, they may be too permissive.

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

For classes, test construction, key methods, and state transitions.

## After Writing

Run `task python:test:file FILE=tests/test_<module>.py` to confirm the red state.

- Tests fail with `ImportError` or `ModuleNotFoundError` → module doesn't exist yet, red state confirmed
- Tests fail with `AssertionError` → module exists but implementation is wrong, red state confirmed
- Tests PASS → the tests are not testing the right behavior — revise them

## Return

```
Tests written: tests/test_module.py
Red state confirmed: 3 tests, 0 passed, 3 failed ✓
```
