# Technical Research: Plugin Refactor — py-lint-driven

## Strategic Summary

The plugin has four concrete problems: hooks.json contains two near-identical
800-character prompt strings; allowed-tools were added piecemeal (quality-analyzer
has 10 entries, lint-iterator has zero); the git-changed-files shell command is
copy-pasted in 5+ places; and run-ruff/run-complexipy/run-pytest skills are
orphaned (not called by anything, but not documented as reference-only). A
layered refactor — clear hook→agent→skill→command boundaries, one source of
truth for git scope, and consistent allowed-tools on every agent — fixes all
four without redesigning the architecture.

---

## Current Problems (Evidence)

### 1. Hooks: duplicated, long, fragile

Write hook and Edit hook are ~95% identical. The only real difference:

| | Write/test file | Edit/test file |
|---|---|---|
| Test files | run + red-state check + warn if passes + ruff | run + ruff |
| Source files | identical | identical |

Both embed the full task selection table inline. If the table changes, it must
be updated in two places. Both prompts are ~800 chars of dense logic.

### 2. Allowed-tools: inconsistent

| Component | allowed-tools |
|---|---|
| quality-analyzer | 10 entries (some redundant: `ruff check*` AND `task python:ruff*`) |
| lint-iterator | none |
| update command | 2 entries |
| setup, tdd, lint-fix, autopilot | none |

### 3. Git-scope logic: copy-pasted 5 times

```
{ git diff --name-only --diff-filter=ACMRT HEAD -- '*.py' 2>/dev/null;
  git ls-files --others --exclude-standard -- '*.py' 2>/dev/null; }
  | tr '\n' ' '
```

Appears verbatim in: `tdd:fix:git`, `lint:fix:git` (Taskfile), `iterate-until-clean`
SKILL.md, `lint-check.md`, `lint-fix.md`, `pre-commit-review` SKILL.md.

### 4. Orphaned skills

`run-ruff`, `run-complexipy`, `run-pytest` are never called by other skills or
commands. They contain useful parsing guidance but their role is undocumented.
`quality-analyzer` and `lint-iterator` re-implement the same parsing inline.

---

## Approach 1: Minimal Cleanup

**How it works:** Fix only the obvious issues without structural changes.
- Slim hooks by extracting task-selection table into a shared comment block
- Add allowed-tools to lint-iterator
- Add one Taskfile task (`git:changed-py`) to centralize the git command
- Mark run-ruff/complexipy/pytest as "reference skills" in their descriptions

**Pros:**
- Small diff, easy to review
- No risk of breaking working behavior
- Fast to implement (~1 hour)

**Cons:**
- Hooks still duplicated — same fix needed twice on any future change
- Allowed-tools still inconsistent across commands
- Does not address run-* skill orphan problem structurally

**Best when:** You want quick wins and can tolerate residual messiness.
**Complexity:** S

---

## Approach 2: Layered Refactor (Recommended)

**How it works:** Enforce a clear 4-layer contract and fix one source of
truth per concern.

### Layer contract

```
hooks.json       →  thin dispatcher (30-50 chars per hook, delegates to agent)
agents/          →  autonomous doers (lint-iterator, quality-analyzer)
skills/          →  reusable procedures called by agents and commands
commands/        →  user-facing entry points, orchestrate skills
```

### Changes

**Hooks:** Rewrite both prompts to be short. The hook invokes `lint-iterator`
directly rather than re-implementing its logic. Write-hook adds one line for
red-state check on test files; Edit-hook is identical otherwise.

```
Before (~800 chars each, logic duplicated):
  "A file was just written: {{tool.input.file_path}}\n\nIf the file path
   does not end with '.py', stop immediately...<400 more chars>"

After (~120 chars each, delegates to agent):
  "File written: {{tool.input.file_path}}. If not .py, stop.
   Otherwise invoke lint-iterator with this file path."
```

**Git scope:** Add one Taskfile task as single source of truth:

```yaml
git:changed-py:
  desc: "Space-separated git-changed Python files (staged, unstaged, new untracked)"
  vars:
    FILES:
      sh: "{ git diff --name-only --diff-filter=ACMRT HEAD -- '*.py' 2>/dev/null;
             git ls-files --others --exclude-standard -- '*.py' 2>/dev/null; }
           | tr '\n' ' '"
  cmds:
    - echo "{{.FILES}}"
```

All skills/commands that need changed files call `task python:git:changed-py`
or reference it by name — no inline shell duplication.

**Allowed-tools:** Establish a standard per component type:

| Component | Standard allowed-tools |
|---|---|
| agents (autonomous) | Bash(task python:*), Read(*), Write(src/*), Edit(src/*) |
| commands (setup/update) | Write(*), Read(*), Bash(task python:*) |
| quality-analyzer | Bash(task python:*), Bash(ruff*), Bash(complexipy*), Bash(xenon*) |

**run-* skills:** Rename descriptions to explicitly say "reference skill — provides
parsing guidance and output format spec for agents and commands." No behavior
change, just clarity.

**Pros:**
- Hooks become trivially maintainable (one change needed, not two)
- Single source of truth for git scope
- Consistent allowed-tools across all components
- run-* skills have a clear documented role

**Cons:**
- More files to touch (~8-10 files)
- Hook refactor changes runtime behavior — needs testing

**Best when:** You want the plugin to be clean enough to add to without accumulating
more debt. This is the right default.
**Complexity:** M

---

## Approach 3: Architectural Consolidation

**How it works:** Merge overlapping commands and collapse the skill layer.

- Merge `/lint-check` + `/quality-report` → one command with `--deep` flag
- Merge `/tdd` + `/autopilot` → one command with `--full` flag
- Remove `run-ruff`, `run-complexipy`, `run-pytest` skills (fold into agents)
- Single `python-quality` agent replaces both `lint-iterator` and `quality-analyzer`

**Pros:**
- Fewer files, fewer concepts for users to learn
- No orphaned components

**Cons:**
- Breaking change for users already familiar with the commands
- Loses the clean TDD-only path that `/tdd` provides
- Single large agent is harder to prompt correctly than two focused ones
- High risk for uncertain gain

**Best when:** Starting over with lessons learned. Not now.
**Complexity:** L

---

## Comparison

| Aspect | Approach 1 | Approach 2 | Approach 3 |
|--------|------------|------------|------------|
| Hooks duplication | Partially fixed | Fixed | Fixed |
| Allowed-tools consistency | Partially fixed | Fixed | Fixed |
| Git scope duplication | Fixed (Taskfile) | Fixed (Taskfile) | Fixed |
| Orphaned skills | Documented only | Documented | Removed |
| Breaking changes | None | None | Yes |
| Implementation effort | S | M | L |

---

## Recommendation

**Approach 2.** It fixes all four problems cleanly without breaking anything.
The hook refactor is the highest-value change — two 800-char prompts that
duplicate logic → two 120-char prompts that delegate to lint-iterator. The
Taskfile git:changed-py task eliminates the copy-paste. Consistent allowed-tools
make the plugin's permissions transparent and auditable.

---

## Implementation Plan

Execute in this order (each step is independently shippable):

### Step 1 — Taskfile: add git:changed-py task
Add `git:changed-py` task. Update `tdd:fix:git` and `lint:fix:git` to use it.
Reference it by name in `iterate-until-clean` SKILL.md, `lint-check.md`,
`lint-fix.md`, `pre-commit-review` SKILL.md.

### Step 2 — Allowed-tools: lint-iterator
Add to lint-iterator frontmatter:
```yaml
allowed-tools:
  - Bash(task python:*)
  - Write(src/*)
  - Edit(src/*)
```

### Step 3 — Allowed-tools: commands
Add to setup.md, tdd.md, lint-fix.md, autopilot.md, tdd-test.md:
```yaml
allowed-tools:
  - Bash(task python:*)
  - Write(*)
  - Edit(*)
```

### Step 4 — quality-analyzer: consolidate allowed-tools
Remove redundant entries. Keep task-based variants (they go through the Taskfile
which provides consistent env/config). Remove direct `ruff check*`, `complexipy*`,
`xenon*` entries that duplicate task equivalents — or keep both and document why.

### Step 5 — Hooks: slim down
Rewrite both prompts. Delegate source-file processing to lint-iterator.
Keep only: .py filter, config read, file-type detection, red-state check (Write only).

### Step 6 — run-* skills: document role
Update descriptions of run-ruff, run-complexipy, run-pytest to state explicitly:
"Reference skill — defines output format and parsing conventions used by
lint-iterator and quality-analyzer. Not invoked directly in the loop."

---

## Gotchas

- Hooks cannot reference skill files by path — the prompt IS the instruction.
  "Invoke lint-iterator" works because agents are available in context.
- Taskfile `vars.sh:` captures stdout including trailing newline — use `xargs`
  or `tr -d '\n'` to clean output for use as FILE args.
- `allowed-tools` on commands is enforced per-invocation. Write(*) on a command
  allows writes during that command's execution only.
- quality-analyzer `skip_tests: true` path must still be tested — it was added
  without a test project to validate against.
