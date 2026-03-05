---
name: setup
description: Bootstrap a new project with py-lint-driven. Copies Taskfiles, GitHub Actions workflow, and config into the current project. Run once when starting a new Python project.
argument-hint: ""
---

# /setup Command

Bootstrap the current project with all py-lint-driven tooling.

## What it creates

- `Taskfile.yaml` — root Taskfile with python namespace
- `taskfiles/Taskfile.python.yaml` — all python tasks (lint, test, tdd, ci, etc.)
- `py-lint-driven.local.md` — configuration file (edit to change thresholds)
- `pyproject.toml` — ruff and pytest configuration
- `.github/workflows/python-quality.yml` — CI workflow for pull requests
- `conftest.py` — adds project root to sys.path so pytest can find modules

## Flow

1. **Check prerequisites**
   Run each of the following and report any that are missing:
   - `ruff --version`
   - `complexipy --version`
   - `pytest --version`
   - `task --version`

   If any are missing, show install instructions and stop:
   ```
   pip install ruff complexipy pytest
   brew install go-task
   ```

2. **Create directories**
   Create `taskfiles/`, `.github/workflows/`, `src/`, `tests/` if they don't exist.

3. **Copy templates**
   For each file below, copy from the plugin templates directory only if the
   file does not already exist in the project (never overwrite):
   - `${CLAUDE_PLUGIN_ROOT}/templates/Taskfile.yaml` → `Taskfile.yaml`
   - `${CLAUDE_PLUGIN_ROOT}/templates/Taskfile.python.yaml` → `taskfiles/Taskfile.python.yaml`
   - `${CLAUDE_PLUGIN_ROOT}/templates/py-lint-driven.local.md` → `py-lint-driven.local.md`
   - `${CLAUDE_PLUGIN_ROOT}/templates/pyproject.toml` → `pyproject.toml`
   - `${CLAUDE_PLUGIN_ROOT}/templates/.github/workflows/python-quality.yml` → `.github/workflows/python-quality.yml`

4. **Create conftest.py**
   If `conftest.py` does not exist, create it:
   ```python
   import sys
   from pathlib import Path

   sys.path.insert(0, str(Path(__file__).parent))
   ```

5. **Report**
   List every file created. For any file that already existed and was skipped,
   note it as "already exists, skipped".

   ```
   Setup complete:
     created  Taskfile.yaml
     created  taskfiles/Taskfile.python.yaml
     created  py-lint-driven.local.md
     created  pyproject.toml
     created  .github/workflows/python-quality.yml
     created  conftest.py

   Next steps:
     - Edit py-lint-driven.local.md to configure thresholds
     - Run /tdd to start building with TDD
     - Open a PR to trigger the GitHub Actions CI check
   ```
