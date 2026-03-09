---
name: quality-analyzer
description: Runs all quality checks in parallel and returns a combined report. Used by iterate-until-clean for the verify pass. Runs tests, ruff, complexipy, and xenon concurrently — all tools report even if one fails. Identifies functions and files flagged by multiple tools as combined findings. Returns a structured status: CLEAN, ISSUES_FOUND, or TEST_FAILURE.
allowed-tools:
  - Bash(ruff check*)
  - Bash(ruff format*)
  - Bash(complexipy*)
  - Bash(xenon*)
  - Bash(task python:ruff*)
  - Bash(task python:complexity*)
  - Bash(XENON_MAX_ABSOLUTE=* XENON_MAX_MODULES=* XENON_MAX_AVERAGE=* task python:cyclomatic*)
  - Bash(task --taskfile taskfiles/Taskfile.python.yaml*)
---

# quality-analyzer Agent

Parallel quality verification. Runs all four tools simultaneously, collects every
result, and returns a combined report regardless of individual tool outcomes.

## When Called

Called by `iterate-until-clean` for the verify pass, and by `/lint-check` and
`/autopilot` when a full quality picture is needed.

Receives:
- `files` — space-separated list of files to check (optional, defaults to `.`)
- `skip_tests` — when true, omit pytest entirely (optional, defaults to false)
- xenon thresholds from the caller: `XENON_MAX_ABSOLUTE`, `XENON_MAX_MODULES`, `XENON_MAX_AVERAGE`

## Execution: Run All Tools in Parallel

Run xenon directly with flags — do NOT use `task python:cyclomatic` as env vars are not
forwarded through task. Command: `xenon -b <XENON_MAX_ABSOLUTE> -m <XENON_MAX_MODULES> -a <XENON_MAX_AVERAGE> .`

When `skip_tests` is false (default), issue all four commands simultaneously:

1. `task python:test`
2. `task python:ruff FILES=<files>`
3. `task python:complexity FILES=<files>`
4. `xenon -b <XENON_MAX_ABSOLUTE> -m <XENON_MAX_MODULES> -a <XENON_MAX_AVERAGE> .`

When `skip_tests` is true, issue only the three lint commands simultaneously (omit test):

1. `task python:ruff FILES=<files>`
2. `task python:complexity FILES=<files>`
3. `xenon -b <XENON_MAX_ABSOLUTE> -m <XENON_MAX_MODULES> -a <XENON_MAX_AVERAGE> .`

Collect the stdout, stderr, and exit code from each. All four run to completion
regardless of the others' exit codes.

## Analysis: Combined Findings

After all tools complete, identify any function or file that appears in more than
one tool's failures:

- A function failing both complexipy AND xenon → one combined finding
- A file with ruff violations AND xenon module rank violation → one combined finding

Combined findings share a root cause and should be fixed together.

## Return: Structured Status

Return one of three statuses with full detail:

### CLEAN

```
Status: CLEAN
All checks passed — tests: <N> passed, ruff: clean, complexipy: clean, xenon: clean
```

### TEST_FAILURE

```
Status: TEST_FAILURE
Tests: <N> failed, <N> passed
  - tests/test_module.py::test_edge_case — AssertionError: expected 5, got 3
  [or: COLLECTION ERROR — ImportError in tests/test_module.py (stop, do not iterate)]

Lint results (informational — fix tests first):
  Ruff: <N> violations | clean
  Complexipy: <N> violations | clean
  Xenon: violations | clean
```

Lint results are shown but marked informational — test failures take priority.

### ISSUES_FOUND

```
Status: ISSUES_FOUND
Tests: <N> passed ✓

Ruff: <N> violations
  - src/module.py:45: E501 line too long
  - src/utils.py:12: F401 unused import

Complexipy: <N> violations
  - process_data in src/module.py — score: 18 (threshold: 15)

Xenon: violations
  - block src/module.py:6 process_data — rank C (max-absolute: B)
  - module src/module.py — rank B (max-modules: A)

Combined findings:
  ⚠ process_data in src/module.py — flagged by complexipy (score 18) AND xenon
    (rank C). Same root cause: function is too complex. Fix once, both clear.
```

## Important Rules

- Never modify files — this agent is read-only
- Always run all tools even if one fails
- When `skip_tests` is false: test collection errors (ImportError, SyntaxError in test files)
  must be surfaced immediately and labeled COLLECTION ERROR — do not continue iterating
- When `skip_tests` is true: TEST_FAILURE status is never returned; only CLEAN or ISSUES_FOUND
- Lint results during TEST_FAILURE are informational only
