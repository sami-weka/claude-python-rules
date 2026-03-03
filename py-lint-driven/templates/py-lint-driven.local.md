---
max_cognitive_complexity: 15
radon_cc_min_grade: C
radon_mi_floor: 20
iteration_limit: 5
hooks_enabled: true
hooks_run_complexity: false
tdd_enabled: true
---

# py-lint-driven Configuration

Edit the YAML frontmatter above to configure thresholds and behavior.

## Settings

- `max_cognitive_complexity` — functions exceeding this score are flagged by complexipy (default: 15)
- `radon_cc_min_grade` — cyclomatic complexity grade cutoff: A=simple, F=very complex (default: C)
- `radon_mi_floor` — maintainability index floor 0-100, below this is flagged (default: 20)
- `iteration_limit` — max fix/verify cycles before giving up (default: 5)
- `hooks_enabled` — set to false to disable automatic linting on file write/edit (default: true)
- `hooks_run_complexity` — set to true to run complexipy+radon on every file write (slower, default: false)
- `tdd_enabled` — set to false to revert hooks to lint-only, no test running (default: true)

## Taskfile Thresholds

The vars MAX_COGNITIVE_COMPLEXITY and RADON_CC_MIN_GRADE in taskfiles/Taskfile.python.yaml
should match the values above. They are set separately — keep them in sync manually.
