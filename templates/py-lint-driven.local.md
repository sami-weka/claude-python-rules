---
xenon_max_absolute: B
xenon_max_modules: A
xenon_max_average: A
iteration_limit: 5
hooks_enabled: true
hooks_run_complexity: false
tdd_enabled: true
---

# py-lint-driven Configuration

Edit the YAML frontmatter above to configure plugin behavior and xenon thresholds.

## Settings

- `xenon_max_absolute` — worst single function cyclomatic complexity grade allowed: A–F (default: B)
- `xenon_max_modules` — worst module average grade allowed: A–F (default: A)
- `xenon_max_average` — project-wide average grade allowed: A–F (default: A)
- `iteration_limit` — max fix/verify cycles before giving up (default: 5)
- `hooks_enabled` — set to false to disable automatic linting on file write/edit (default: true)
- `hooks_run_complexity` — set to true to run complexipy+xenon on every file write (slower, default: false)
- `tdd_enabled` — set to false to revert hooks to lint-only, no test running (default: true)

## complexipy threshold

Configure in `pyproject.toml` under `[tool.complexipy]`:

```toml
[tool.complexipy]
max-complexity-allowed = 15
```

complexipy reads this natively — no plugin wiring needed.

## Xenon thresholds

Xenon has no config file support. The values above are passed as env vars to task
invocations at runtime: `XENON_MAX_ABSOLUTE=<value> ... task python:cyclomatic`
