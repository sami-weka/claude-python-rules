---
max_cognitive_complexity: 15
mypy_enabled: false
xenon_max_absolute: B
xenon_max_modules: A
xenon_max_average: A
iteration_limit: 5
hooks_enabled: true
hooks_run_complexity: false
tdd_enabled: true
---

# py-lint-driven Configuration

Edit the YAML frontmatter above to configure thresholds and behavior.

## Settings

- `max_cognitive_complexity` — functions exceeding this score are flagged by complexipy (default: 15)
- `mypy_enabled` — set to true to include mypy type checking in `lint:` and `tdd:` (requires mypy installed, default: false)
- `xenon_max_absolute` — worst single function cyclomatic complexity grade allowed: A–F (default: B)
- `xenon_max_modules` — worst module average grade allowed: A–F (default: A)
- `xenon_max_average` — project-wide average grade allowed: A–F (default: A)
- `iteration_limit` — max fix/verify cycles before giving up (default: 5)
- `hooks_enabled` — set to false to disable automatic linting on file write/edit (default: true)
- `hooks_run_complexity` — set to true to run complexipy+xenon on every file write (slower, default: false)
- `tdd_enabled` — set to false to revert hooks to lint-only, no test running (default: true)

## Taskfile Thresholds

The vars MAX_COGNITIVE_COMPLEXITY, XENON_MAX_ABSOLUTE, XENON_MAX_MODULES, and XENON_MAX_AVERAGE
in taskfiles/Taskfile.python.yaml should match the values above. They are set separately —
keep them in sync manually.
