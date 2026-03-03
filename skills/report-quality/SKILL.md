---
name: report-quality
description: Aggregate output from ruff, complexipy, radon, and pytest into a single quality summary with pass/fail verdict against configured thresholds.
triggers:
  - "quality report"
  - "summarize quality"
  - "report results"
---

# report-quality Skill

Aggregate all tool output into a single quality summary.

## What to Include

```
## Quality Report — <path> — <timestamp>

### Tests
<N> passed, <N> failed

### Ruff
<N> violations  |  or: clean ✓

### Cognitive Complexity (complexipy, threshold: <N>)
<N> violations  |  or: clean ✓
Top offenders:
  - <function> in <file> — score <N>

### Cyclomatic Complexity (radon cc, threshold: <grade>)
<N> violations  |  or: clean ✓

### Maintainability Index (radon mi, floor: <N>)
<N> files below floor  |  or: clean ✓
Worst:
  - <file> — MI <score>

### Verdict
PASS ✓  |  FAIL ✗ — <N> issues remain
```

## Extracting Cognitive Complexity Scores

complexipy output format (one block per file):
```
src/module.py
    process_data 18 FAILED
    helper 3 PASSED
```

Each function line is `    <name> <score> PASSED|FAILED`.
Extract the score (middle token) from lines ending in `FAILED`.

## Verdict Rules

- PASS: all tests green AND ruff clean AND complexipy clean AND radon within thresholds
- FAIL: any of the above is violated

## Saving Reports

For `/quality-report` command only, save the report to:
`.claude/py-lint-driven/reports/YYYY-MM-DD-HH-MM-<path>.md`

For other commands, display inline only.
