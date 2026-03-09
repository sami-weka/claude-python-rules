---
name: report-quality
description: Aggregate ruff, complexipy, xenon, and pytest results into a single quality summary with a PASS/FAIL verdict. Use this skill at the end of any quality check cycle — after /tdd, /lint-fix, /lint-check, or /quality-report commands complete. Also use it when the user asks "what's the quality like", "show me a summary", or "how clean is the code". Pulls together all tool outputs that have already been run — does not re-run tools itself.
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

### Cyclomatic Complexity (xenon, max-absolute: <grade>, max-modules: <grade>, max-average: <grade>)
<N> violations  |  or: clean ✓

### Combined Findings
<see below>

### Verdict
PASS ✓  |  FAIL ✗ — <N> issues remain
```

If a tool was not run, mark its section as "not checked" rather than assuming clean.

## Combined Findings

After collecting all tool outputs, identify functions or files flagged by MORE than
one tool. Surface these as combined findings — they share a root cause and should be
fixed together.

```
### Combined Findings

⚠ process_data in src/module.py — flagged by both complexipy (score: 18) AND xenon
  (rank C). Both violations point to the same root cause: this function is too
  complex and needs refactoring. Fix once, both checks will clear.

⚠ src/utils.py — ruff violations (3) AND xenon module rank B. Cleaning up the ruff
  violations may reduce complexity indirectly; refactor after ruff is clean.
```

If no function or file appears in more than one tool's output, omit this section.

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

- **PASS**: all tests green AND ruff clean AND complexipy clean AND xenon clean
- **FAIL**: any tool reports a violation, or any test fails

## Saving Reports

For `/quality-report` command only, save the report to:
`.claude/py-lint-driven/reports/YYYY-MM-DD-HH-MM-<sanitized-path>.md`
Create the directory if it doesn't exist.
For all other commands, display inline only — do not save.
