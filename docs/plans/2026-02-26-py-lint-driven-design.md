# py-lint-driven: Design Document

## Overview

A Claude Code marketplace plugin that implements linter-driven and test-driven development
for Python. Linter rules act as the spec — Claude generates code that satisfies them.
TDD is built into the core loop: Claude writes tests first, then implementation, then
iterates until both tests pass and linting is clean.

**Tools:** ruff, complexipy, xenon, pytest
**Trigger:** automatic via hooks on every Write/Edit, and manual via slash commands
**Architecture:** skill-first composable — skills are atomic units, commands compose
skills into workflows, agents handle multi-step reasoning, hooks trigger automatically

---

## Plugin Structure

```
py-lint-driven/
├── plugin.json
├── skills/
│   ├── run-ruff/SKILL.md
│   ├── run-complexipy/SKILL.md
│   ├── run-pytest/SKILL.md
│   ├── write-tests/SKILL.md
│   ├── iterate-until-clean/SKILL.md
│   └── report-quality/SKILL.md
├── commands/
│   ├── lint-fix.md
│   ├── lint-check.md
│   ├── quality-report.md
│   ├── setup.md
│   ├── update.md
│   ├── tdd.md
│   └── tdd-test.md
├── agents/
│   └── lint-iterator.md
└── hooks/
    └── hooks.json
```

---

## Configuration

Single config file: `py-lint-driven.local.md`

```yaml
# plugin behavior — tool thresholds go in pyproject.toml (complexipy) or here (xenon)
xenon_max_absolute: B
xenon_max_modules: A
xenon_max_average: A
iteration_limit: 5
hooks_enabled: true
hooks_run_complexity: false
tdd_enabled: true
```

No profile management. Teams edit this file directly to change behavior and xenon thresholds.
`tdd_enabled: false` reverts hooks to lint-only behavior.
`hooks_run_complexity: false` (default) makes hooks run `task python:tdd:fast`
(tests + ruff only). Set to `true` to run full complexity checks on every write/edit.

**Tool config sources:**
- ruff: `pyproject.toml` `[tool.ruff]` — auto-discovered by ruff
- complexipy: `pyproject.toml` `[tool.complexipy]` `max-complexity-allowed` — auto-discovered by complexipy
- xenon: `py-lint-driven.local.md` fields above — passed as env vars at runtime (xenon has no config file support)
- pytest: `pyproject.toml` `[tool.pytest.ini_options]` — auto-discovered by pytest

---

## Taskfile Integration

The plugin delegates all tool invocation to Taskfile. Skills call tasks and parse
stdout — they never invoke ruff, complexipy, xenon, or pytest directly.

The Taskfile template lives at `templates/Taskfile.python.yaml` in the plugin repo and
is copied to `taskfiles/Taskfile.python.yaml` in the user project by `/setup`. Xenon
vars in that file (`XENON_MAX_ABSOLUTE`, `XENON_MAX_MODULES`, `XENON_MAX_AVERAGE`) act
as fallback defaults — hooks and skills always override them by passing values from
`py-lint-driven.local.md` as env vars at invocation time
(e.g., `XENON_MAX_ABSOLUTE=B task python:cyclomatic`).

complexipy has no Taskfile vars — it reads its threshold directly from
`pyproject.toml` `[tool.complexipy]`.

### Taskfile Ownership

`Taskfile.yaml` and `taskfiles/Taskfile.python.yaml` are user project files, not plugin
files. On first run (or via `/lint-check`), the plugin checks for their existence:
- If neither exists, the plugin generates both from templates.
- If `Taskfile.yaml` exists but lacks a `python:` include, the plugin appends the
  include entry and generates `taskfiles/Taskfile.python.yaml`.
- If `taskfiles/Taskfile.python.yaml` already exists, the plugin does not overwrite it —
  the user owns it. `py-lint-driven.local.md` is the source of truth for thresholds;
  hooks and skills pass those values as env vars at runtime, so the Taskfile var
  defaults are always overridden.

### CI Notes

- `GITHUB_BASE_REF` is set automatically by GitHub Actions on `pull_request` events.
  Falls back to `main` for local runs.
- `--diff-filter=ACMRT` excludes deleted files — no point linting removed code.
- Lint tools (ruff, complexipy) run on **changed files only** for speed. xenon always
  runs on the full project (no file scoping).
- pytest runs on **full `tests/`** — a source change can break unrelated tests,
  so scoping pytest to changed files is unsafe.
- Do NOT use `tj-actions/changed-files` — compromised in a supply chain attack
  (CVE-2025-30066, March 2025). Use native git diff as shown above.
- Within `taskfiles/Taskfile.python.yaml`, sibling tasks are referenced by short name
  (e.g. `task: lint`, `task: ruff`). Taskfile v3 resolves these to the full namespaced
  name (`python:lint`, `python:ruff`) at runtime via the `includes` directive.
- **Exit codes**: both `complexipy` and `xenon` exit non-zero on violations — task
  chains (`task python:lint`, `task python:ci`) will correctly fail when thresholds are
  exceeded. No stdout parsing required for threshold enforcement.

### Skill-to-Task Mapping

| Skill | Task |
|---|---|
| `run-ruff` | `task python:ruff` |
| `run-complexipy` | `task python:complexity` |
| `run-pytest` | `task python:test` |
| `write-tests` | writes file, then `task python:test:file` |
| `iterate-until-clean` (fix pass) | `task python:tdd:fix` |
| `iterate-until-clean` (verify pass) | `task python:tdd` |
| full check | `task python:check` |
| full auto-fix | `task python:fix` |
| CI | `task python:ci` |
| hooks (fast) | `task python:tdd:fast` or `task python:lint:fast` — hooks only, not skills |

---

## Skills

### `run-ruff`
Calls `task python:ruff`. Returns structured output: file, line, rule code, message.
Supports fix mode via `task python:ruff:fix` for auto-fixable violations.

### `run-complexipy`
Calls `task python:complexity`. Returns functions/classes exceeding the configured
cognitive complexity threshold. Output includes function name, file, line, score.

### `run-pytest`
Calls `task python:test`. Returns structured output: test count, pass/fail per test,
failure messages with file and line. Distinguishes collection errors (broken imports,
syntax) from assertion failures — collection errors are surfaced immediately, not
iterated on.

### `write-tests`
Given a target source file or function signature, generates a `tests/test_<module>.py`
file with pytest test cases. Writes tests that are initially failing (red) — does not
peek at the implementation first. Generates:
- Happy path tests
- Edge cases based on type annotations and docstrings
- One test per logical behavior, not one per line

Runs `task python:test:file` after writing to confirm the red state.

### `iterate-until-clean`
The core unified quality loop. Always runs full lint — never the fast variant.

Each iteration:
1. **Fix pass**: run `task python:tdd:fix` (test → ruff:fix → complexity → maintainability → fmt)
2. **Verify pass**: run `task python:tdd` (test → full lint) to confirm clean state
3. If still dirty, repeat up to `iteration_limit`

Stops when verify pass is fully green, or iteration limit is hit. Reports two separate
counts: tests fixed, violations fixed. On limit hit, surfaces remaining failures and
violations explicitly — never silently fails.

Note: the fast/full distinction (`hooks_run_complexity`) applies to hooks only.
This skill always uses full lint regardless of that config value.

### `report-quality`
Aggregates output from all tools into a single quality summary: test pass/fail counts,
violation counts by category, complexity hotspots, maintainability scores, and a
pass/fail verdict against configured thresholds.

---

## Slash Commands

### `/tdd <description>`
The primary TDD entry point. Accepts a natural language description of what to build.

Flow:
1. Invoke `write-tests` skill — generates `tests/test_<module>.py` (red)
2. Run `task python:test:file` to confirm tests fail
3. Write implementation to satisfy the tests
4. Invoke `iterate-until-clean` — each iteration runs `task python:tdd:fix` (fix pass)
   then `task python:tdd` (verify pass), repeating until both are green or limit hit
5. Output `report-quality`

### `/tdd-test <path>`
Generates tests for an existing source file without writing implementation. Useful for
adding test coverage to legacy code. Runs `task python:test:file` to show the initial
failure state, then stops — does not write implementation.

### `/lint-fix [path]`
Runs the unified quality loop:
1. `iterate-until-clean` skill — fix/verify loop until clean or iteration limit hit
2. `report-quality`

### `/lint-check [path]`
Read-only audit including test results:
1. `task python:tdd` (tests + full lint, read-only)
2. `report-quality` with test pass/fail counts included

### `/quality-report [path]`
Runs `task python:complexity` + `task python:maintainability` only. Produces a deep
quality report focused on complexity and maintainability. Highlights top 5 most complex
functions and files with poor MI scores. Saves a timestamped markdown report to
`.claude/py-lint-driven/reports/`.

---

## Agents

### `lint-iterator`
Owns the full unified quality loop — test failures and lint violations in one agent.

Key behaviors:
- **Tests run first, always** — each iteration starts with `task python:test`. If tests
  fail, Claude fixes the implementation before touching lint violations.
- **Distinguishes failure types** — assertion failures (fix logic), collection errors
  (fix imports/syntax, surfaced immediately), lint violations (fix style/complexity).
- **Never modifies test files** — scoped to Write and Edit on implementation files only.
  Test files written by `write-tests` are treated as the spec and are immutable during
  iteration.
- **Complexity violations still require confirmation** — proposes a refactor strategy
  before restructuring logic, never applies silently.
- **Unified summary on limit hit** — reports tests passing/failing, violations
  fixed/remaining, files touched. Clear signal on what remains for the developer.

---

## Hooks

### `post-write-quality` (PostToolUse — Write)
Fires after every Write call on a `.py` file.

Branching logic:
- **Test file** (`tests/` path) → run `task python:test:file` to confirm red state.
  Does not invoke `lint-iterator` — a failing test after `write-tests` is correct
  behavior. Then runs `task python:ruff` for style checks only.
- **Source file** → run `task python:tdd:fast` or `task python:tdd` depending on
  `hooks_run_complexity` config. If failures or violations → invoke `lint-iterator`
  agent. Re-run to verify. Report remaining issues if iteration limit hit.

### `post-edit-quality` (PostToolUse — Edit)
Same logic as `post-write-quality`, scoped to the specific edited file.

Both hooks are **blocking** — Claude does not proceed until tests pass and linting is
clean, or the iteration limit is hit. Controlled by `hooks_enabled` in config.
`tdd_enabled: false` reverts to lint-only behavior.

Hook task selection based on config:

| `hooks_run_complexity` | `tdd_enabled` | Hook runs |
|---|---|---|
| `false` (default) | `true` | `task python:tdd:fast` (test + ruff only) |
| `true` | `true` | `task python:tdd` (test + full lint) |
| `false` | `false` | `task python:lint:fast` (ruff only) |
| `true` | `false` | `task python:lint` (full lint, no tests) |

---

## Data Flow

```
/tdd <description>
    │
    ├─ write-tests skill → tests/test_<module>.py (RED)
    ├─ task python:test:file → confirm failing
    ├─ Claude writes implementation
    └─ iterate-until-clean skill
            │
            ├─ fix pass:    task python:tdd:fix
            │               (test → ruff:fix → complexity → maintainability → fmt)
            │               lint-iterator agent fixes failures/violations
            │
            ├─ verify pass: task python:tdd
            │               (test → full lint)
            │
            ├─ still dirty? → repeat up to iteration_limit
            │
            └─ green → report-quality → done


Hook (Write/Edit on .py file)
    │
    ├─ source file → hook task (per config table) → lint-iterator if needed → re-verify
    └─ test file   → task python:test:file (confirm red, no iteration)
                     task python:ruff (style check only)
```
