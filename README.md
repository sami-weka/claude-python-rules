# ai-python-workflow

A Claude Code plugin marketplace by [sami-weka](https://github.com/sami-weka).

## What is this?

This repository is a Claude Code plugin marketplace — a single repo that hosts multiple Claude Code plugins. Each plugin lives in its own subfolder and can be installed independently via the Claude Code marketplace.

The marketplace manifest at `.claude-plugin/marketplace.json` lists all available plugins and their source paths.

## Available plugins

| Plugin | Description |
|---|---|
| [py-lint-driven](./py-lint-driven) | Linter-driven and test-driven development for Python. Enforces ruff, complexipy, xenon, and pytest automatically on every Python file write/edit. |

## Installing a plugin

Install any plugin directly from the Claude Code marketplace using this repository URL:

```
https://github.com/sami-weka/claude-python-rules
```

## Repository structure

```
.claude-plugin/
  marketplace.json       # marketplace manifest listing all plugins
py-lint-driven/          # py-lint-driven plugin
  plugin.json
  skills/
  commands/
  agents/
  hooks/
  templates/
  README.md
```

## Adding a new plugin

1. Create a new subfolder: `<plugin-name>/`
2. Add `plugin.json`, `skills/`, `commands/`, etc. inside it
3. Register it in `.claude-plugin/marketplace.json` under `plugins` with `"source": "./<plugin-name>"`
