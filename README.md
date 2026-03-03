# py-lint-driven

A Claude Code plugin that enforces linter-driven and test-driven development for Python projects automatically.

Every time you write or edit a Python file, Claude runs quality checks and fixes violations before moving on.

## What it enforces

- **ruff** — linting and formatting
- **complexipy** — cognitive complexity per function (default threshold: 15)
- **radon** — cyclomatic complexity and maintainability index
- **pytest** — tests must pass

## Prerequisites

```bash
pip install ruff complexipy radon pytest
brew install go-task gh
```

## Setup a new project

From your project directory:

```bash
bash <(gh api repos/sami-weka/claude-python-rules/contents/setup.sh \
  --jq '.content' | base64 -d)
```

This creates:
```
Taskfile.yaml
taskfiles/Taskfile.python.yaml
py-lint-driven.local.md
.github/workflows/python-quality.yml
conftest.py
```

## Claude Code commands

| Command | What it does |
|---|---|
| `/tdd <description>` | Write failing tests → implement → iterate until clean |
| `/tdd-test <file>` | Generate tests for an existing file, confirm red state |
| `/lint-fix [path]` | Fix all lint and test issues, iterate until clean |
| `/lint-check [path]` | Read-only audit — no files modified |
| `/quality-report [path]` | Deep complexity and maintainability analysis, saves report |

## Task runner

All tools are invoked through Taskfile tasks. You can run them directly:

```bash
task python:tdd          # tests + full lint
task python:tdd:fast     # tests + ruff only (faster)
task python:tdd:fix      # tests + ruff:fix + fmt
task python:lint         # ruff + complexipy + radon
task python:lint:fast    # ruff only
task python:check        # lint + format check (read-only)
task python:fix          # lint:fix + fmt
task python:test         # pytest only
task python:complexity   # complexipy only
task python:maintainability  # radon cc + mi
task python:ci           # CI mode: checks changed .py files only
```

## CI

The GitHub Actions workflow runs automatically on pull requests:

```yaml
# .github/workflows/python-quality.yml
on:
  pull_request:
    branches: [main]
```

It runs `task python:ci` which lints only the Python files changed in the PR and runs the full test suite.

## Configuration

Edit `py-lint-driven.local.md` in your project root:

```yaml
---
max_cognitive_complexity: 15
radon_cc_min_grade: C
radon_mi_floor: 20
iteration_limit: 5
hooks_enabled: true
hooks_run_complexity: false
tdd_enabled: true
---
```

| Setting | Description |
|---|---|
| `max_cognitive_complexity` | complexipy threshold per function |
| `radon_cc_min_grade` | cyclomatic complexity grade cutoff (A–F) |
| `radon_mi_floor` | maintainability index floor (0–100) |
| `iteration_limit` | max fix/verify cycles before giving up |
| `hooks_enabled` | disable automatic checks on file write/edit |
| `hooks_run_complexity` | include complexipy+radon in hooks (slower) |
| `tdd_enabled` | include tests in hooks |

## Plugin structure

```
py-lint-driven/
  plugin.json
  skills/       run-ruff, run-complexipy, run-radon, run-pytest,
                write-tests, iterate-until-clean, report-quality
  commands/     tdd, tdd-test, lint-fix, lint-check, quality-report
  agents/       lint-iterator
  hooks/        post-write-quality, post-edit-quality
  templates/    Taskfile.yaml, Taskfile.python.yaml,
                py-lint-driven.local.md,
                .github/workflows/python-quality.yml
```
