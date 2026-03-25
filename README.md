# ai-python-workflow

A Claude Code plugin marketplace by [sami-weka](https://github.com/sami-weka).

## What is this?

This repository is a Claude Code plugin marketplace — a single repo that hosts multiple Claude Code plugins. Each plugin lives in its own subfolder and can be installed independently via the Claude Code marketplace.

The marketplace manifest at `.claude-plugin/marketplace.json` lists all available plugins and their source paths.

## Available plugins

| Plugin | Version | Description |
|---|---|---|
| [py-lint-driven](./py-lint-driven) | 1.1.0 | Linter-driven and test-driven development for Python. Enforces ruff, complexipy, xenon, and pytest automatically on every Python file write/edit. |

## Installing a plugin

Install any plugin directly from the Claude Code marketplace using this repository URL:

```
https://github.com/sami-weka/claude-python-rules
```

## Repository structure

```
.claude-plugin/
  marketplace.json              # marketplace manifest listing all plugins
.github/
  workflows/
    plugin-validation.yml       # CI: validates templates against test-project on change
py-lint-driven/                 # py-lint-driven plugin (v1.1.0)
  plugin.json
  CHANGELOG.md
  skills/
  commands/
  agents/
  hooks/
  templates/
  README.md
scripts/
  bump_version.py               # compute new semver (patch/minor/major)
  apply_version.py              # atomically update plugin.json + marketplace.json
  pre-push-hook.sh              # pre-push hook: validates templates + enforces version bump
test-project/                   # live validation environment for templates
Taskfile.yaml                   # repo-level tasks: validate, bump:*, install:hooks
CURRENT_STATE.md                # session handoff: current status and key decisions
```

## Development workflow

```bash
task validate          # validate templates against test-project before pushing
task bump:patch        # bump patch version (bug fixes)
task bump:minor        # bump minor version (new features)
task bump:major        # bump major version (breaking changes)
task install:hooks     # install pre-push hook into .git/hooks/
```

Run `task validate` after any change to `py-lint-driven/templates/`.
Run `task bump:*` before any push that changes plugin behavior.

## Adding a new plugin

1. Create a new subfolder: `<plugin-name>/`
2. Add `plugin.json`, `skills/`, `commands/`, etc. inside it
3. Register it in `.claude-plugin/marketplace.json` under `plugins` with `"source": "./<plugin-name>"`
4. Add a validation step for it in `Taskfile.yaml` if it has templates
