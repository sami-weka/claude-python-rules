# Changelog

## [1.1.0] - 2026-03-19

### Added
- `git:changed-py` canonical task: computes git-changed Python files (staged, unstaged, new untracked). Single definition consumed by all git-scoped tasks.
- `lint:fix:git` task: lint fix cycle scoped to git-changed Python files only.
- `tdd:fix:git` task: TDD fix cycle scoped to git-changed Python files only.
- `tdd_enabled` config flag in `py-lint-driven.local.md`: set to `false` to skip tests in all hook and skill loops.
- `scope: git` option in `iterate-until-clean` skill: linting runs only on changed files; tests always run on full suite.
- `allowed-tools` frontmatter to all commands and agents: `tdd`, `lint-fix`, `lint-check`, `setup`, `update`, `autopilot`, `quality-report`, `tdd-test`, `lint-iterator`, `quality-analyzer`.

### Changed
- Marketplace name: `py-lint-driven` → `ai-python-workflow`.
- Plugin files moved to `py-lint-driven/` subfolder to support multi-plugin marketplace layout.
- Hooks prompts reduced from ~800 chars to ~200 chars each; source-file processing delegates to `lint-iterator` agent.
- Hook prompts now name xenon variables explicitly: `xenon_max_absolute`, `xenon_max_modules`, `xenon_max_average`.
- `lint-fix` command defaults to `scope: git` when no path argument is given.
- `lint-check` command defaults to `scope: git` when no path argument is given.
- `tdd` command step 4 uses `scope: git` for the iterate-until-clean skill.
- `quality-analyzer` agent runs xenon directly (`xenon -b <v> -m <v> -a <v> .`) to forward threshold variables correctly.
- Reference skills (`run-ruff`, `run-complexipy`, `run-pytest`) descriptions updated to clarify they are reference skills.

### Fixed
- Removed unused `import re` from `.github/workflows/python-quality.yml` inline Python script (CI failure).
- Removed duplicate empty `## Rules` heading from `lint-iterator.md`.
- Removed `Edit(tests/*)` from `lint-fix` command allowed-tools (contradicted lint-iterator's test-immutability rule).
- Fixed YAML parse error in `Taskfile.python.yaml`: converted inline flow mappings `vars: {FILES: "{{.CHANGED}}"}` to block style, and single-quoted echo commands containing `{{.CHANGED}}`.

## [1.0.0] - initial release

- PostToolUse hooks for Write and Edit on `.py` files.
- `lint-iterator` agent: iterates ruff + complexipy + xenon + pytest until clean.
- `quality-analyzer` agent: analyzes overall project quality.
- Commands: `setup`, `update`, `tdd`, `tdd-test`, `lint-fix`, `lint-check`, `autopilot`, `quality-report`.
- Skills: `iterate-until-clean`, `write-tests`, `report-quality`, `run-ruff`, `run-complexipy`, `run-pytest`.
- Taskfile template with ruff, complexipy, xenon, and pytest tasks.
- GitHub Actions workflow for CI quality checks on changed Python files.
