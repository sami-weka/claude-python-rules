# Current State

**Plugin:** py-lint-driven **Version:** 1.1.0
**Branch:** main
**Last updated:** 2026-03-19

---

## Session Start Checklist

Before starting any work:
1. Read this file
2. Run `git log --oneline -10` to see recent commits
3. If continuing prior work: use `episodic-memory:search-conversations` for decisions
4. Check `py-lint-driven/plugin.json` to confirm current version

---

## What's Done

- **1.1.0 release** (2026-03-19): full refactor — slim hooks, consistent allowed-tools,
  git-scoped linting, `tdd_enabled` flag, `git:changed-py` canonical task
- **YAML fix**: echo lines with `{{.CHANGED}}` must be single-quoted in YAML
  (plain scalars treat `{` as flow indicator)
- **Workflow infrastructure** (2026-03-19):
  - Root `Taskfile.yaml` with `validate`, `validate:yaml`, `validate:sync`, `validate:test`,
    `bump:patch`, `bump:minor`, `bump:major`, `install:hooks`
  - `scripts/bump_version.py` — compute new semver
  - `scripts/apply_version.py` — update plugin.json + marketplace.json atomically
  - `scripts/pre-push-hook.sh` — validates templates + enforces version bump before push
  - `.github/workflows/plugin-validation.yml` — CI backstop for template changes
  - `CURRENT_STATE.md` (this file)
  - Pre-push hook installed at `.git/hooks/pre-push`

---

## What's In Progress

Nothing currently.

---

## Next Up

- Run `task validate` after any template change (Taskfile, Taskfile.python.yaml, etc.)
- Run `task bump:patch/minor/major` before any push that changes plugin behavior
- Keep this file updated

---

## Key Decisions (don't re-litigate)

| Decision | Reason |
|----------|--------|
| `quality-analyzer` runs xenon directly, not via `task python:cyclomatic` | Env vars (XENON_MAX_*) don't forward through Taskfile include context |
| `lint-fix` does NOT have `Edit(tests/*)` in allowed-tools | Contradicts lint-iterator's rule that tests are immutable during lint cycles |
| Echo lines with `{{.CHANGED}}` in Taskfile must be single-quoted | `{` is a YAML flow indicator in plain scalars; double-quoted YAML strings with `{{` also cause issues in some contexts |
| `bump:_do` uses `scripts/apply_version.py` (not inline Python) | Two version fields in marketplace.json (metadata.version + plugins[0].version); script walks full tree |
| Pre-push hook calls `task validate`, not inline logic | DRY — one place to update sync/test logic |
| test-project is NOT auto-committed by the hook | Sync is for validation only; committing test-project is a separate deliberate step |

---

## Tools Reference

```bash
task validate          # Validate all templates before pushing
task validate:yaml     # YAML parse only
task validate:sync     # Sync templates to test-project only
task validate:test     # Run tests + lint in test-project only
task bump:patch        # Bug fix, allowed-tools addition
task bump:minor        # New command/skill/task/behavior
task bump:major        # Breaking change
task install:hooks     # Install .git/hooks/pre-push
```
