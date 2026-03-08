# Technical Research: py-lint-driven — Full Project Review

## Strategic Summary

The project concept is strong and the plugin architecture is well-suited to its goal: making quality enforcement automatic and invisible for Python developers using Claude Code. The core idea — hooking into Claude's Write/Edit events to run linters and tests on every change — is the right approach for this platform. The tool choices are mostly solid, with one notable gap (no type checking) and one reliability concern (complexipy is a small, relatively new project). There are five concrete issues worth addressing before declaring the project production-ready.

---

## Requirements (as built)

- Claude Code plugin: auto-enforces ruff, complexipy, xenon, pytest on every file write/edit
- Taskfile-based tasks runnable independently of Claude
- GitHub Actions CI: inline PR review comments + blocking checks job
- Per-project config via `py-lint-driven.local.md`
- Marketplace distribution via `.claude-plugin/marketplace.json`

---

## Evaluation: Tool Choices

### ruff
**Verdict: excellent choice.**

Fast, actively maintained (Astral), replaces flake8 + isort + pyupgrade in one tool. Also handles formatting (replaces black). Community adoption is very high and accelerating. No issues.

### complexipy (cognitive complexity)
**Verdict: acceptable, but watch the maintenance risk.**

Cognitive complexity is a better metric than cyclomatic for "how hard is this to read" — it was designed specifically to address cyclomatic complexity's weaknesses with modern language constructs. The choice is defensible. However:

- Small project, low bus factor
- Less battle-tested than alternatives
- If it breaks or goes unmaintained, the plugin breaks with it

**Alternative worth knowing:** `flake8-cognitive-complexity` — a flake8 plugin implementing the same metric, more integrated with the ruff/flake8 ecosystem. Not a blocker to switch now, but worth monitoring.

### xenon (cyclomatic complexity)
**Verdict: good choice for what it does.**

Xenon wraps radon and adds proper exit codes, solving exactly the reason radon was dropped. The three-threshold system (absolute, module, average) is expressive. The one genuine limitation — it does not accept individual file paths, only directories — means it always scans the full project. This is acceptable for small projects but will slow down CI on large codebases.

### pytest
**Verdict: correct, standard choice.** No issues.

### Missing tools

| Tool | What it covers | Severity |
|---|---|---|
| mypy / pyright | Type checking | High — type errors are a major class of bugs |
| pytest-cov | Coverage reporting | Medium — valuable signal, widely expected |
| pre-commit | Local hook integration | Low — the Claude hooks partially replace this, but teams expect `.pre-commit-config.yaml` |

---

## Evaluation: Plugin Architecture

### Hooks (PostToolUse on Write/Edit)

**Issue — hooks fire on ALL file writes, not just Python files.**

The `matcher: "Write"` and `matcher: "Edit"` match any tool use of those names, regardless of file path. The hook prompt opens with "A Python file was just written" — but this fires equally when Claude writes a YAML file, a markdown file, or any other non-Python file. Claude then reads the path and can check the extension, but this wastes tokens on every non-Python write.

The prompt should start with an explicit check: if the file does not end in `.py`, stop immediately. Currently this check is absent.

**Issue — `hooks_run_complexity` default is false.**

With the default config, hooks run `task python:tdd:fast` (tests + ruff only). Complexipy and xenon are silently skipped on every write. This means a developer can write highly complex functions all day and never see a warning until they manually run `task python:lint` or `/lint-check`. The default behavior is inconsistent with the plugin's stated goal of "runs quality checks automatically".

This is a design tradeoff: complexity checks are slower, so they're off by default to avoid slowing every write. But the consequence is that the most differentiating checks (complexity) are invisible in the default experience.

### Taskfile design
**Verdict: solid.**

The Taskfile abstraction is one of the best decisions in the project. Users can run `task python:tdd` or `task python:lint` independently of Claude, in their own terminal, in CI, or from any other tool. The split between fast (ruff only) and full (ruff + complexipy + xenon) maps cleanly to hooks vs manual runs.

The `ci:` task that detects changed Python files via `git diff` is smart and efficient — ruff and complexipy only scan what changed. The one gap: xenon still scans the full project in CI (unavoidable given its API).

### /setup command and template management
**Two issues.**

First, `pyproject.toml` is copied only if it doesn't exist. In practice, most real Python projects already have a `pyproject.toml`. When it exists, setup skips it silently, and the user ends up without ruff/pytest config unless they manually add it. The command should detect an existing `pyproject.toml` and offer to merge the `[tool.ruff]` and `[tool.pytest.ini_options]` sections.

Second, once templates are copied, they never update. If the plugin releases a new version of `Taskfile.python.yaml` with a better `ci:` task or a new tool, existing projects don't get it. There is no `/update` command. This is a long-term maintenance gap.

### CI workflow
**Verdict: well-designed.**

The split into two jobs is the right call:
- `review` job: posts inline PR comments via reviewdog, never blocks — pure signal
- `checks` job: runs `task python:ci`, fails the PR on real violations

Pip installs are repeated per-job without caching. On every PR, GitHub spins up a fresh runner and re-downloads ruff, complexipy, xenon, pytest. Adding `actions/cache` for pip would meaningfully reduce CI time on busy repos.

### Skills and commands
**Verdict: clean decomposition.**

The skill → command → hook layering is well done. Skills (`run-ruff`, `run-complexipy`, `iterate-until-clean`, etc.) are composable building blocks; commands (`/tdd`, `/lint-fix`) orchestrate them; hooks call commands automatically. The `iterate-until-clean` loop with a configurable limit is smart.

One weakness: skills reference other skills by name in their descriptions (`call run-complexipy skill`, `call run-radon skill`). When a skill is deleted (as run-radon was), references can be left dangling. The deletion was caught manually this time; in a larger plugin this becomes a maintenance hazard.

---

## Comparison: Current vs Alternative Approaches

| Aspect | Current | Alternative |
|---|---|---|
| Linting | ruff | flake8 + plugins (slower, more config) |
| Cognitive complexity | complexipy | flake8-cognitive-complexity (more stable) |
| Cyclomatic complexity | xenon | lizard (multi-language, individual file support) |
| Type checking | not included | mypy or pyright |
| Coverage | not included | pytest-cov |
| Task runner | Taskfile | Makefile (universal, no install needed) or just npm/tox scripts |
| Local hooks | Claude PostToolUse | pre-commit (standard, language-agnostic) |

---

## Issues Summary

### Bug
**Hooks fire on non-Python files without an early exit.**
The prompt assumes it's a Python file before checking the extension. Add a check at the top: if the file path does not end in `.py`, stop immediately.

### Design gap
**No type checking.**
mypy or pyright is the most significant missing enforcement. Type errors are a real and common class of bugs, and professional Python projects are increasingly typed. This is the biggest gap.

### Design tradeoff (acceptable but worth documenting)
**`hooks_run_complexity` defaults to false** — meaning complexipy and xenon are not checked on every write by default. Users who never change this setting get ruff + tests only, not the full tool stack.

### Maintenance gap
**No `/update` command** — templates copied by `/setup` never get updated when the plugin releases new versions.

### Scalability gap
**pyproject.toml setup doesn't handle existing files** — merge logic is missing.

---

## Recommendation

The project is production-ready for its stated scope, with two things worth fixing:

**Fix immediately:**
1. Add early exit to hooks when the written file is not a `.py` file
2. Add mypy as an optional task (off by default, opt-in via config)

**Fix soon:**
3. Add `actions/cache` for pip in the CI workflow
4. Add a note in `/setup` about manual pyproject.toml merging when the file already exists

**Consider later:**
5. Add `/update` command that re-copies templates without overwriting user changes
6. Add `pytest-cov` task and optional coverage threshold config
7. Monitor complexipy maintenance — if it stalls, migrate to `flake8-cognitive-complexity`

---

## Implementation Context

<claude_context>
<chosen_approach>
- name: Current architecture (Taskfile + Claude hooks + GitHub Actions)
- libraries: ruff, complexipy, xenon, pytest, reviewdog
- install: pip install ruff complexipy xenon pytest && brew install go-task
</chosen_approach>

<architecture>
- pattern: hook → task → tool (PostToolUse fires hook prompt, hook calls task, task invokes tool)
- components: skills (composable), commands (orchestrate skills), hooks (auto-trigger commands), Taskfile (tool invocation layer)
- data_flow: file write → PostToolUse hook → config read → task selection → tool run → violations → lint-iterator agent → re-verify
</architecture>

<files>
- hooks/hooks.json: add .py extension check before processing
- commands/setup.md: add pyproject.toml merge guidance
- templates/.github/workflows/python-quality.yml: add pip cache
- skills/run-mypy/SKILL.md: new skill to add (optional)
- templates/Taskfile.python.yaml: add mypy task (optional, off by default)
</files>

<implementation>
- start_with: fix the hooks.json non-Python file check (quickest win, correctness bug)
- order: hooks fix → CI caching → mypy task → pyproject.toml merge guidance
- gotchas: xenon cannot take individual file paths — always runs on '.', unavoidable
- gotchas: complexipy -mx flag, not -C (already fixed, documented in MEMORY.md)
- testing: create a test project, run /setup, write a non-Python file, verify hook exits early
</implementation>
</claude_context>

---

## Sources

- xenon docs: https://xenon.readthedocs.io — cyclomatic complexity thresholds and CLI
- complexipy: https://github.com/rohaquinlop/complexipy — cognitive complexity for Python
- ruff: https://docs.astral.sh/ruff — linting and formatting
- Claude Code plugin architecture: verified against cached plugins (superpowers, taches-cc-resources)
- reviewdog: https://github.com/reviewdog/reviewdog — inline PR annotation tool
