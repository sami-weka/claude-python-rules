# py-lint-driven: Design Document

## Overview

A Claude Code marketplace plugin that implements linter-driven and test-driven development
for Python. Linter rules act as the spec — Claude generates code that satisfies them.
TDD is built into the core loop: Claude writes tests first, then implementation, then
iterates until both tests pass and linting is clean.

**Tools:** ruff, complexipy, radon, pytest
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
│   ├── run-radon/SKILL.md
│   ├── run-pytest/SKILL.md
│   ├── write-tests/SKILL.md
│   ├── iterate-until-clean/SKILL.md
│   └── report-quality/SKILL.md
├── commands/
│   ├── lint-fix.md
│   ├── lint-check.md
│   ├── quality-report.md
│   ├── tdd.md
│   └── tdd-test.md
├── agents/
│   └── lint-iterator.md
└── hooks/
    ├── post-write-quality.json
    └── post-edit-quality.json
```

---

## Configuration

Single config file: `py-lint-driven.local.md`

```yaml
max_cognitive_complexity: 15
radon_cc_min_grade: C
radon_mi_floor: 20
iteration_limit: 5
hooks_enabled: true
hooks_run_complexity: false
tdd_enabled: true
```

No profile management. Teams edit this file directly to change thresholds.
`tdd_enabled: false` reverts hooks to lint-only behavior.
`hooks_run_complexity: false` (default) makes hooks run `task python:tdd:fast`
(tests + ruff only). Set to `true` to run full complexity and maintainability
checks on every write/edit.

Threshold values (`max_cognitive_complexity`, `radon_cc_min_grade`, `radon_mi_floor`)
are mirrored as defaults in `taskfiles/Taskfile.python.yaml` vars. Ruff configuration
lives in `pyproject.toml` or `ruff.toml` and is auto-discovered by ruff — no separate
plugin config needed for ruff rules.

---

## Taskfile Integration

The plugin delegates all tool invocation to Taskfile. Skills call tasks and parse
stdout — they never invoke ruff, complexipy, radon, or pytest directly.

```yaml
# Taskfile.yaml
version: '3'

includes:
  python: ./taskfiles/Taskfile.python.yaml
```

```yaml
# taskfiles/Taskfile.python.yaml
# NOTE: tasks here have NO 'python:' prefix — the includes directive adds it.
# Invoke as: task python:lint, task python:test, etc.
# Within this file, tasks reference siblings by short name (e.g. task: lint).
version: '3'

vars:
  MAX_COGNITIVE_COMPLEXITY: "15"
  RADON_CC_MIN_GRADE: "C"

tasks:

  # --- Leaf tasks: direct tool invocations ---

  ruff:
    desc: "Run ruff check (config auto-discovered from pyproject.toml or ruff.toml)"
    cmds:
      - ruff check {{.FILES | default "."}}

  ruff:fix:
    desc: "Run ruff check with auto-fix"
    cmds:
      - ruff check --fix {{.FILES | default "."}}

  complexity:
    desc: "Run complexipy with configured max cognitive complexity threshold"
    cmds:
      - complexipy -C {{.MAX_COGNITIVE_COMPLEXITY}} {{.FILES | default "."}}

  maintainability:
    desc: "Run radon cc and mi (output parsed by run-radon skill for threshold enforcement)"
    cmds:
      - radon cc -n {{.RADON_CC_MIN_GRADE}} {{.FILES | default "."}}
      - radon mi {{.FILES | default "."}}

  fmt:
    desc: "Run ruff format"
    cmds:
      - ruff format {{.FILES | default "."}}

  fmt:check:
    desc: "Run ruff format check (no changes applied)"
    cmds:
      - ruff format --check {{.FILES | default "."}}

  # --- Composite tasks ---

  lint:fast:
    desc: "Run ruff only (fast, for hooks)"
    cmds:
      - task: ruff
      - echo "--> Ruff check passed"

  lint:
    desc: "Run all linters (ruff + complexity + maintainability)"
    cmds:
      - task: ruff
      - task: complexity
      - task: maintainability
      - echo "--> All Python linters passed"

  lint:fix:
    desc: "Run ruff auto-fix, then check complexity and maintainability (only ruff violations are auto-fixable)"
    cmds:
      - task: ruff:fix
      - task: complexity
      - task: maintainability
      - echo "--> Ruff auto-fix applied, linters checked"

  check:
    desc: "Run all checks (lint + format check)"
    cmds:
      - task: lint
      - task: fmt:check
      - echo "--> All Python checks passed"

  fix:
    desc: "Auto-fix and format"
    cmds:
      - task: lint:fix
      - task: fmt
      - echo "--> Auto-fix and format complete"

  test:
    desc: "Run pytest on the tests/ directory"
    cmds:
      - pytest tests/ -v

  test:file:
    desc: "Run pytest on a specific test file"
    cmds:
      - pytest {{.FILE}} -v

  test:watch:
    desc: "Run pytest in watch mode (requires pytest-watch, local use only)"
    cmds:
      - ptw tests/

  tdd:fast:
    desc: "Tests + ruff only (fast, used by hooks when hooks_run_complexity is false)"
    cmds:
      - task: test
      - task: lint:fast
      - echo "--> Tests passed and ruff clean"

  tdd:
    desc: "Full TDD + lint cycle (tests + ruff + complexity + maintainability)"
    cmds:
      - task: test
      - task: lint
      - echo "--> All tests passed and linting clean"

  tdd:fix:
    desc: "Full TDD + lint cycle with auto-fix"
    cmds:
      - task: test
      - task: lint:fix
      - task: fmt
      - echo "--> TDD cycle complete with fixes applied"

  ci:
    desc: "Run all checks for CI on changed Python files only"
    vars:
      CHANGED_PY_FILES:
        sh: "git fetch origin ${GITHUB_BASE_REF:-main} --quiet && git diff --name-only --diff-filter=ACMRT origin/${GITHUB_BASE_REF:-main}...HEAD -- '*.py' | tr '\n' ' '"
    # status: exits 0 when no files changed → Taskfile skips all cmds cleanly (exit 0)
    # This is correct CI behavior: no changed files = pass, not error
    status:
      - '[ -z "{{.CHANGED_PY_FILES}}" ]'
    cmds:
      - task: ruff
        vars: { FILES: "{{.CHANGED_PY_FILES}}" }
      - task: complexity
        vars: { FILES: "{{.CHANGED_PY_FILES}}" }
      - task: maintainability
        vars: { FILES: "{{.CHANGED_PY_FILES}}" }
      - task: test
      - echo "--> CI checks passed"
```

### Taskfile Ownership

`Taskfile.yaml` and `taskfiles/Taskfile.python.yaml` are user project files, not plugin
files. On first run (or via `/lint-check`), the plugin checks for their existence:
- If neither exists, the plugin generates both from templates.
- If `Taskfile.yaml` exists but lacks a `python:` include, the plugin appends the
  include entry and generates `taskfiles/Taskfile.python.yaml`.
- If `taskfiles/Taskfile.python.yaml` already exists, the plugin does not overwrite it —
  the user owns it. Threshold defaults in the file should be kept in sync manually
  with `py-lint-driven.local.md`.

### CI Notes

- `GITHUB_BASE_REF` is set automatically by GitHub Actions on `pull_request` events.
  Falls back to `main` for local runs.
- `--diff-filter=ACMRT` excludes deleted files — no point linting removed code.
- Lint tools (ruff, complexipy, radon) run on **changed files only** for speed.
- pytest runs on **full `tests/`** — a source change can break unrelated tests,
  so scoping pytest to changed files is unsafe.
- Do NOT use `tj-actions/changed-files` — compromised in a supply chain attack
  (CVE-2025-30066, March 2025). Use native git diff as shown above.
- Within `taskfiles/Taskfile.python.yaml`, sibling tasks are referenced by short name
  (e.g. `task: lint`, `task: ruff`). Taskfile v3 resolves these to the full namespaced
  name (`python:lint`, `python:ruff`) at runtime via the `includes` directive.
- **Exit code asymmetry**: `complexipy` exits non-zero when violations exceed the
  threshold — `task python:lint` and `task python:ci` will correctly fail on complexity
  violations. `radon cc` and `radon mi` always exit 0 regardless of results. Radon
  enforcement is handled exclusively by the `run-radon` skill parsing stdout and
  comparing scores against `radon_cc_min_grade` and `radon_mi_floor`. Task chains will
  not fail on radon violations alone.
- `radon mi` runs without a `--min` filter — the full output is returned for the
  `run-radon` skill to parse. Filtering with `--min` would hide below-floor files,
  defeating the purpose.

### Skill-to-Task Mapping

| Skill | Task |
|---|---|
| `run-ruff` | `task python:ruff` |
| `run-complexipy` | `task python:complexity` |
| `run-radon` | `task python:maintainability` (stdout parsed for threshold enforcement) |
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

### `run-radon`
Calls `task python:maintainability`. Since radon always exits 0 regardless of results,
this skill parses stdout directly to detect violations. It compares CC grades against
`radon_cc_min_grade` and MI scores against `radon_mi_floor` from config, then returns
a structured list of offending functions and files.

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
