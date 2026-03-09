---
name: update
description: Re-sync project templates to the latest plugin version. Run after upgrading the plugin to get updated Taskfiles, CI workflow, and new config settings. Never overwrites user-owned files or existing config values.
argument-hint: ""
allowed-tools:
  - Read(${CLAUDE_PLUGIN_ROOT}/templates/*)
  - Write(.github/workflows/*)
---

# /update Command

Re-sync project templates to the latest plugin version.

## What gets updated

| File | Behavior |
|---|---|
| `taskfiles/Taskfile.python.yaml` | Replaced with latest template |
| `.github/workflows/python-quality.yml` | Replaced with latest template |
| `py-lint-driven.local.md` | New keys added, existing values preserved |

## What is never touched

- `Taskfile.yaml` — root file, may have user customizations
- `pyproject.toml` — user-owned (hint shown if sections are missing)
- `conftest.py` — user code
- `src/`, `tests/` — user code

## Flow

1. **Update Taskfile**
   Read `taskfiles/Taskfile.python.yaml` and `${CLAUDE_PLUGIN_ROOT}/templates/Taskfile.python.yaml`.
   - If identical: skip with "already up to date"
   - If different: replace with the template, note what changed in one line

2. **Update CI workflow**
   Compare `.github/workflows/python-quality.yml` with
   `${CLAUDE_PLUGIN_ROOT}/templates/.github/workflows/python-quality.yml`.
   - If the project file does not exist: copy the template, report "created"
   - If identical: skip with "already up to date"
   - If different: overwrite `.github/workflows/python-quality.yml` with the template
     content, note what changed in one line

3. **Merge config**
   Read the YAML frontmatter of `py-lint-driven.local.md` and the template.
   For each key in the template that is NOT in the installed file: add it with the
   default value from the template.
   Preserve all existing keys and their current values unchanged.
   - If nothing to add: skip with "already up to date"

4. **Check pyproject.toml**
   Read `pyproject.toml` if it exists. Check for these sections:
   `[tool.ruff]`, `[tool.pytest.ini_options]`, `[tool.coverage.run]`, `[tool.complexipy]`
   For any missing, note them in the report so the user can add them manually.

5. **Report**
   ```
   Update complete:
     updated  taskfiles/Taskfile.python.yaml  (added: test:coverage tasks, MIN_COVERAGE var)
     updated  .github/workflows/python-quality.yml  (added: pip caching)
     merged   py-lint-driven.local.md  (added: xenon_max_absolute, xenon_max_modules)
     skipped  Taskfile.yaml  (not managed by /update)

   pyproject.toml — missing sections (add manually):
     [tool.complexipy]  — max-complexity-allowed = 15
     [tool.coverage.run]  — source = ["src"], omit = ["tests/*"]
     [tool.coverage.report]  — show_missing = true
   ```
