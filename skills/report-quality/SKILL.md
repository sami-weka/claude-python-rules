---
name: report-quality
description: Aggregate ruff, complexipy, and pytest results into a single quality summary with a PASS/FAIL verdict. Use this skill at the end of any quality check cycle — after /tdd, /lint-fix, /lint-check, or /quality-report commands complete. Also use it when the user asks "what's the quality like", "show me a summary", or "how clean is the code". Pulls together all tool outputs that have already been run — does not re-run tools itself.
---

# report-quality Skill

Aggregate all tool output into a single quality summary. This skill formats results —
it does not run tools. Run the relevant tasks first, then call this skill to summarize.

## Report Format

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

### Verdict
PASS ✓  |  FAIL ✗ — <N> issues remain
```

If a tool was not run, mark its section as "not checked" rather than assuming clean.

## Extracting Cognitive Complexity Scores

complexipy output format:
```
src/module.py
    process_data 18 FAILED
    helper 3 PASSED
```
Each function line: `    <name> <score> PASSED|FAILED`
Extract score (middle token) from lines ending in `FAILED`.

## Verdict Rules

- **PASS**: all tests green AND ruff clean AND complexipy clean
- **FAIL**: any tool reports a violation, or any test fails

## Saving Reports

For `/quality-report` command only, save the report to:
`.claude/py-lint-driven/reports/YYYY-MM-DD-HH-MM-<sanitized-path>.md`
Create the directory if it doesn't exist.
For all other commands, display inline only — do not save.
