# py-lint-driven

A Claude Code plugin that enforces linter-driven and test-driven development for Python projects automatically.

Every time you write or edit a Python file, Claude runs quality checks and fixes violations before moving on.

## What it enforces

- **ruff** — linting and formatting
- **complexipy** — cognitive complexity per function (default threshold: 15, configured in `pyproject.toml`)
- **xenon** — cyclomatic complexity (default: max-absolute B, max-modules A, max-average A)
- **pytest** — tests must pass (configurable via `tdd_enabled`)

## Prerequisites

```bash
pip install ruff complexipy xenon pytest pytest-cov
brew install go-task
```

## Setup

Install the plugin from the Claude Code marketplace, then run in your project:

```
/py-lint-driven:setup
```

This creates all required files in your project:

```
Taskfile.yaml
taskfiles/Taskfile.python.yaml
py-lint-driven.local.md
pyproject.toml
.github/workflows/python-quality.yml
```

## Claude Code commands

| Command | What it does |
|---|---|
| `/py-lint-driven:setup` | Bootstrap a new project with all tooling |
| `/py-lint-driven:update` | Re-sync templates to the latest plugin version |
| `/py-lint-driven:tdd <description>` | Write failing tests → implement → iterate until clean |
| `/py-lint-driven:tdd-test <file>` | Generate tests for an existing file, confirm red state |
| `/py-lint-driven:lint-fix [path]` | Fix all lint issues on git-changed files (or given path) |
| `/py-lint-driven:lint-check [path]` | Read-only audit — no files modified |
| `/py-lint-driven:quality-report [path]` | Deep complexity and maintainability analysis, saves report |

## Task runner

All tools are invoked through Taskfile tasks. You can run them directly:

```bash
# Full cycles
task python:tdd              # tests + full lint (ruff + complexipy + xenon)
task python:tdd:fast         # tests + ruff only (faster)
task python:tdd:fix          # tests + ruff:fix + complexipy + xenon + fmt
task python:tdd:fix:git      # tdd:fix scoped to git-changed Python files

# Lint only
task python:lint             # ruff + complexipy + xenon
task python:lint:fast        # ruff only
task python:lint:fix         # ruff:fix + complexipy + xenon
task python:lint:fix:git     # lint:fix scoped to git-changed Python files
task python:check            # lint + format check (read-only)
task python:fix              # lint:fix + fmt

# Tests only
task python:test                    # pytest
task python:test:coverage           # pytest + coverage report
task python:test:coverage:check     # pytest + coverage, fail if below MIN_COVERAGE (80%)

# Individual tools
task python:ruff             # ruff check
task python:ruff:fix         # ruff check --fix
task python:fmt              # ruff format
task python:fmt:check        # ruff format --check (read-only)
task python:complexity       # complexipy
task python:cyclomatic       # xenon

# CI and git-scoped
task python:ci               # check changed .py files vs base branch, run full test suite
task python:git:changed-py   # print space-separated git-changed Python files
```

## CI

The GitHub Actions workflow (created by `/py-lint-driven:setup`) runs automatically on pull requests:

```yaml
on:
  pull_request:
    branches: [main]
```

It lints only the Python files changed in the PR and runs the full test suite.

## Configuration

Edit `py-lint-driven.local.md` in your project root:

```yaml
---
xenon_max_absolute: B
xenon_max_modules: A
xenon_max_average: A
iteration_limit: 5
hooks_enabled: true
hooks_run_complexity: false
tdd_enabled: true
---
```

| Setting | Default | Description |
|---|---|---|
| `xenon_max_absolute` | B | Worst single function cyclomatic complexity grade allowed (A–F) |
| `xenon_max_modules` | A | Worst module average grade allowed (A–F) |
| `xenon_max_average` | A | Project-wide average grade allowed (A–F) |
| `iteration_limit` | 5 | Max fix/verify cycles before giving up |
| `hooks_enabled` | true | Set to false to disable automatic checks on file write/edit |
| `hooks_run_complexity` | false | Include complexipy+xenon in hooks (slower, off by default) |
| `tdd_enabled` | true | Set to false to skip tests in hooks and lint loops |

To configure the complexipy threshold, edit `pyproject.toml`:

```toml
[tool.complexipy]
max-complexity-allowed = 15
```

## Plugin structure

```
py-lint-driven/
  plugin.json
  CHANGELOG.md
  skills/       run-ruff, run-complexipy, run-pytest,
                write-tests, iterate-until-clean, report-quality,
                pre-commit-review, documentation
  commands/     setup, update, tdd, tdd-test, lint-fix, lint-check,
                autopilot, quality-report
  agents/       lint-iterator, quality-analyzer
  hooks/        hooks.json
  templates/    Taskfile.yaml, Taskfile.python.yaml,
                py-lint-driven.local.md, pyproject.toml,
                .github/workflows/python-quality.yml
```
