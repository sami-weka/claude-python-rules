# Project Assessment: py-lint-driven

Date: 2026-03-08

---

## Strategic Summary

The idea is good and worth finishing. "Linter rules as spec, Claude iterates to green" is a
real use case with clear value. The architecture is clean — skill-first composition,
Taskfile delegation, and hook-driven automation all make sense together. The implementation
is largely complete but has three concrete gaps that would affect daily use:
(1) design doc is stale post-radon→xenon pivot,
(2) config and Taskfile thresholds can silently drift out of sync,
(3) `quality-report` command is missing xenon.

---

## Part 1: Idea Validation

**Verdict: Yes, worth finishing.**

The core thesis — "enforce quality gates on every Claude write/edit so bad code never
accumulates" — is sound. Ruff, complexipy, and xenon all exit non-zero on violations,
so they compose naturally into fail-fast CI-style gates. The Taskfile-as-single-truth
pattern means the same tasks work locally, in Claude hooks, and in GitHub Actions CI.
That consistency is valuable and not easy to achieve without this structure.

The TDD loop (`write-tests → confirm red → implement → iterate-until-clean`) maps
directly to how disciplined Python development should work. Encoding it into a plugin
that runs automatically removes the "I'll write tests later" failure mode.

What could go wrong with the idea: users who work on large files with complex business
logic will hit complexity violations that require architecture changes, not auto-fix.
The current design handles this correctly (complexity refactors require user
confirmation before applying), but it means the hook loop won't fully auto-resolve on
every file. That's the right trade-off, but users should expect it.

---

## Part 2: Architecture Assessment

### What's solid

**Taskfile delegation** is the best architectural decision in this project. Skills never
invoke ruff, complexipy, or xenon directly — they call `task python:*` tasks and parse
stdout. This means:
- One place to change a tool invocation (Taskfile), not N skills
- CI uses the exact same tasks as hooks and commands
- Users can run `task python:tdd` in the terminal and get identical behavior to what
  Claude runs

**Skill-first composition** — skills are atomic (run-ruff, run-complexipy, run-pytest,
write-tests), commands are workflows composed from skills, agents own multi-step
reasoning. This is a clean layering that makes each component testable in isolation.

**Tests-first, tests-immutable** — `lint-iterator` agent is correctly scoped: it writes
and edits source files only. Test files are the spec. The three failure-type taxonomy
(collection errors, assertion failures, lint violations) with different handling for
each is the right design.

**Hook complexity table** — the `hooks_run_complexity × tdd_enabled` 2x2 matrix
is explicit and covers all cases. Good.

**Xenon over radon** — xenon exits non-zero, which means it composes naturally into
task chains without needing a skill to parse stdout for threshold enforcement. radon
always exits 0, which required the `run-radon` skill to do threshold enforcement
itself. Xenon is the right call.

### What has problems

**Problem 1: Config/Taskfile sync is manual and can silently drift** (medium risk)

`py-lint-driven.local.md` has `max_cognitive_complexity`, `xenon_max_absolute`,
`xenon_max_modules`, `xenon_max_average`. The Taskfile has `MAX_COGNITIVE_COMPLEXITY`,
`XENON_MAX_ABSOLUTE`, `XENON_MAX_MODULES`, `XENON_MAX_AVERAGE`. These are separate
values that "should be kept in sync manually."

The hooks read `py-lint-driven.local.md` and tell Claude what config values to use, but
the *tasks themselves* use the Taskfile vars. So if a user changes only the `.local.md`
config (the documented interface), the tasks will run with different thresholds than
what the config file says. The report-quality skill will say "threshold: 15" while
the task enforces 20. This is a real consistency hazard.

Fix path: either (a) have the tasks read the config file directly, or (b) make `/setup`
and the hooks prompt always pass the config values as CLI vars to override Taskfile
defaults (e.g., `task python:complexity MAX_COGNITIVE_COMPLEXITY=15`).

**Problem 2: Design doc is stale** (low risk, but confusing)

`docs/plans/2026-02-26-py-lint-driven-design.md` still says radon throughout —
`run-radon` skill, `radon_cc_min_grade`, `radon_mi_floor`, radon tasks in the Taskfile
snippet. The actual implementation is xenon-based and consistent. The doc is misleading
for anyone reading it as a reference.

The doc should be updated to reflect the current state (xenon, not radon; no run-radon
skill; xenon config vars). Not a blocker, but it's currently the authoritative design
reference and it's wrong.

**Problem 3: `quality-report` command omits xenon** (minor)

`/quality-report` runs ruff + complexipy only. The `report-quality` skill has a xenon
section that will show "not checked". A "deep complexity analysis" that skips cyclomatic
complexity is incomplete. If users are debugging "why is my code hard to maintain" they
want both cognitive (complexipy) and cyclomatic (xenon) data in one place.

---

## Part 3: Implementation Completeness

### What exists

| Component | Status |
|---|---|
| Skills: run-ruff, run-complexipy, run-pytest | Complete |
| Skills: write-tests, iterate-until-clean, report-quality | Complete |
| Commands: tdd, tdd-test, lint-fix, lint-check | Complete |
| Commands: quality-report, setup, update | Complete |
| Agent: lint-iterator | Complete |
| Hooks: Write + Edit PostToolUse | Complete |
| Templates: Taskfile.yaml, Taskfile.python.yaml | Complete |
| Templates: py-lint-driven.local.md | Complete |

### What's missing or incomplete

| Gap | Severity | Notes |
|---|---|---|
| Design doc not updated for xenon | Low | Misleading but doesn't break anything |
| Config/Taskfile threshold sync | Medium | Values can drift silently |
| quality-report missing xenon | Low | Incomplete picture for complexity audits |
| No `run-xenon` standalone skill | Info | Not needed — xenon exits non-zero, handled by tasks |
| Templates: pyproject.toml, github workflow | Unknown | Not verified in this review |

---

## Part 4: Workflow Assessment

### Core TDD loop
```
/tdd <description>
  → write-tests skill → RED confirmed
  → Claude writes implementation
  → iterate-until-clean skill
      fix pass: task python:tdd:fix (test → ruff:fix → complexity → cyclomatic → fmt)
      verify pass: task python:tdd (test → full lint)
      repeat up to iteration_limit
  → report-quality
```
This loop is correct. Tests-first, fix-then-verify, explicit limit with clear failure
report. No silent failures.

### Hook behavior
Hooks fire after every Write/Edit on `.py` files. Default is `tdd:fast` (tests + ruff
only). Full complexity via `tdd` only if `hooks_run_complexity: true`.

One expected tension: a file can be "hook-green" (passes `tdd:fast`) but "command-red"
(fails `task python:tdd` with complexity violations). This is documented and intentional
— users who want full gates on every edit can set `hooks_run_complexity: true`. This is
the right default; full complexity on every write would be slow and noisy.

### Blocking behavior
Hooks are blocking — Claude waits for the loop to finish before proceeding. This is
correct for a quality gate. The iteration limit prevents infinite loops. Good.

### What the workflow lacks
- No "explain why" mode — when complexity refactor requires confirmation, the user just
  sees a prompt. There's no skill that explains *why* a function is complex and what
  the refactor trade-offs are. This would make the confirmation step more useful.
- No way to skip quality gates for a single write (e.g., "just write this draft, don't
  lint it yet"). Users can disable hooks globally via config, but not per-operation.
  Minor UX gap for exploratory coding.

---

## Recommendation

Finish it. The three gaps to fix before calling it production-ready:

1. **Fix config/Taskfile sync** — highest priority. Options:
   - Pass config values as CLI vars in hook prompts: `task python:complexity MAX_COGNITIVE_COMPLEXITY={{config.max_cognitive_complexity}}`
   - Or document clearly that the Taskfile is the source of truth and the `.local.md`
     config values are advisory only (not preferred — confusing)

2. **Add xenon to `quality-report` command** — one line change: add
   `task python:cyclomatic` to the flow.

3. **Update design doc** — update or archive `docs/plans/2026-02-26-py-lint-driven-design.md`
   to reflect the xenon migration.

The plugin architecture is sound enough to build on. The Taskfile delegation pattern
in particular will age well — adding a new tool means adding one task and one skill,
not rewiring hooks and commands.
