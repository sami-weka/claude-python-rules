# Technical Research: Workflow Improvement

## Strategic Summary

Three levers matter most: validating plugin changes against a live test-project before
pushing (currently zero), running a research→plan→implement→review pipeline consistently
(done once this session, caught 5 bugs), and using session handoff documents to avoid
context loss across sessions. The test-project validation loop is the highest-impact
change — it would have caught the orphaned `git:changed-py` task, the duplicate heading,
and the `Edit(tests/*)` contradiction before they needed a code review to surface.

---

## Context: What the Workflow Currently Is

Observed across this session:

| Step | Current behavior | Problem |
|---|---|---|
| Idea | User says what to change | No research or planning for small changes |
| Implement | Direct edits to plugin files | No validation — changes go straight to GitHub |
| Review | Code review ran once (end of session) | Caught 5 real bugs that shipped first |
| Test | test-project exists but unused | Templates diverged from test-project |
| Memory | MEMORY.md + episodic-memory available | Decisions not captured between sessions |
| Versioning | plugin.json at 1.0.0 always | No way to know what changed between installs |

---

## Approach 1: Plugin Validation Loop (Test-Project Discipline)

**How it works:**
After any change to `templates/`, run `/update` in `test-project/` to apply the
templates, then run `task python:ci` in `test-project/` to verify nothing broke.
This catches syntax errors, broken task references, and template regressions before push.

**Specifically:**
1. Change a template file (e.g., `Taskfile.python.yaml`)
2. From `test-project/`: run `/py-lint-driven:update` to pull in the new template
3. Run `task python:test` and `task python:lint` to confirm tasks still work
4. If clean → push. If broken → fix template first.

**This would have caught:**
- `git:changed-py` being orphaned (task referenced but `sh:` still inlined)
- `import re` unused in CI workflow (ruff would flag it)
- Any broken Taskfile YAML syntax

**Tools involved:**
- `test-project/` (already exists, has working calculator example)
- `/py-lint-driven:update` command
- Taskfile tasks

**Pros:**
- Zero extra tooling — everything exists today
- Catches broken templates before users see them
- Forces the update command to be tested regularly

**Cons:**
- Adds a manual step after every template change
- test-project needs occasional maintenance (keep src/calculator.py valid)

**Best when:** Any change to `templates/` or `hooks/hooks.json`
**Complexity:** S

---

## Approach 2: Research → Plan → Implement → Review Pipeline

**How it works:**
For any change larger than a one-liner, use the full pipeline:
1. `/taches-cc-resources:research:technical` — understand the problem
2. `/taches-cc-resources:create-plan` or `/superpowers:writing-plans` — write plan
3. `/superpowers:subagent-driven-development` — implement with review checkpoints
4. `/superpowers:requesting-code-review` — final review before push

This session used this pipeline once (for the big refactor) and it worked: the research
document identified 6 clean steps, the subagent execution was organized, and the code
review caught 5 bugs. For smaller changes (single-file tweaks) the pipeline is overkill
— use judgment.

**Decision heuristic:**

| Change type | Pipeline |
|---|---|
| Single allowed-tools entry | Direct edit → push |
| New feature (new task/command/skill) | Research → implement → push |
| Refactor (multiple files) | Research → plan → implement → review → push |
| Breaking change | Research → plan → implement → test-project → review → push |

**Tools involved:**
- Skills already installed: `taches-cc-resources:research:technical`,
  `superpowers:writing-plans`, `superpowers:subagent-driven-development`,
  `superpowers:requesting-code-review`

**Pros:**
- Code review already proved its value (5 bugs caught)
- Plans prevent scope creep and ad-hoc accumulation
- No new tooling needed

**Cons:**
- Adds overhead for small changes (needs judgment to skip appropriately)
- Plan writing takes time if requirements aren't clear

**Best when:** Refactors, new skills/commands, anything touching 3+ files
**Complexity:** S (process, not code)

---

## Approach 3: Session Handoff + Memory Discipline

**How it works:**
At the end of every session, run `/taches-cc-resources:whats-next` to generate a
handoff document. At the start of the next session, read it. Use
`/episodic-memory:search-conversations` for decisions made in prior sessions.

Current state: MEMORY.md captures project facts but not decisions ("why did we
choose X over Y?"). Within-session context is lost entirely between sessions.

**Specifically:**
- End of session: `/taches-cc-resources:whats-next` → saves `docs/handoff-YYYY-MM-DD.md`
- Start of session: read latest handoff, search episodic memory for relevant context
- After significant decisions: save to `memory/` (the auto-memory system is set up)

**This would help with:**
- "Why is `quality-analyzer` allowed-tools structured this way?" → searchable
- "What's the current state of the refactor?" → handoff doc
- Not re-litigating past decisions (e.g., why `tdd_enabled` was added)

**Tools involved:**
- `taches-cc-resources:whats-next` skill
- `episodic-memory:search-conversations` skill
- `/Users/sami.shtotland/.claude/projects/.../memory/` (already configured)

**Pros:**
- Addresses the most common friction: starting a new session blind
- Memory system already exists and is configured
- Handoff docs are durable artifacts (git-committable)

**Cons:**
- Requires discipline at end of sessions (easy to skip when rushed)
- Episodic memory search is only as good as what was captured

**Best when:** Every session. Especially before: new features, continuation of prior work.
**Complexity:** S

---

## Approach 4: Plugin Versioning + CHANGELOG

**How it works:**
Bump `plugin.json` version on meaningful changes. Maintain a `CHANGELOG.md` in
`py-lint-driven/` that lists what changed per version. Users running `/update` can
see what version they're on vs what's available.

Current state: `plugin.json` has been at `1.0.0` through 15+ commits of changes.
The `marketplace.json` also shows `1.0.0`. Users who installed at any point have
no way to know they're behind.

**Versioning rules:**
- Patch (1.0.x): bug fixes, allowed-tools additions, description clarifications
- Minor (1.x.0): new commands/skills/tasks, behavioral changes to existing ones
- Major (x.0.0): breaking changes (removed commands, changed config schema)

**This session alone would have been:**
- 1.0.0 → 1.1.0 (git scope, tdd_enabled, multiple new Taskfile tasks)
- 1.1.0 → 1.1.1 (CI fix, refactor cleanup)
- 1.1.1 → 1.2.0 (full refactor: slim hooks, consistent allowed-tools)

**Pros:**
- Users know when to run `/update`
- Changelog makes the plugin professional and trustworthy
- Forces review of "is this a breaking change?" before pushing

**Cons:**
- Adds a step to every push (easy to forget)
- Changelog maintenance is ongoing work

**Best when:** Before any push to main.
**Complexity:** S

---

## Comparison

| Aspect | Validation Loop | Pipeline Discipline | Session Handoff | Versioning |
|---|---|---|---|---|
| Prevents regressions | ✅ Yes | Partially | No | No |
| Reduces bugs shipped | ✅ High | ✅ High | Low | No |
| Reduces back-and-forth | No | ✅ High | ✅ High | Low |
| Context loss | No | Partially | ✅ Yes | No |
| Effort to adopt | Low | Medium | Low | Low |
| Tooling needed | None | None | None | None |

---

## Recommendation

Adopt all four, but start with 1 and 2 — they have the highest bug-prevention value.

**Immediate (this session):**
1. Update `test-project/` to the current template versions (run `/py-lint-driven:update`
   in test-project). Commit it. Now it's a baseline for future validation.
2. Bump `plugin.json` to 1.1.0 and add `CHANGELOG.md` — retroactively for the
   significant changes made today.

**Process going forward:**
3. After any template change: run `/py-lint-driven:update` in test-project and verify tasks work.
4. For multi-file changes: run `/superpowers:requesting-code-review` before push.
5. End of session: run `/taches-cc-resources:whats-next` and commit the handoff doc.

---

## Implementation Context

<claude_context>
<chosen_approach>
- name: All four, prioritized
- tooling: All existing skills + test-project (already present)
- no new dependencies
</chosen_approach>
<architecture>
- Validation: test-project/ is the live validation environment
- Pipeline: research → plan → implement → validate → review → push
- Memory: handoff docs in docs/, decisions in memory/
- Versioning: semver in plugin.json + py-lint-driven/CHANGELOG.md
</architecture>
<files>
- update: py-lint-driven/plugin.json (bump version)
- create: py-lint-driven/CHANGELOG.md
- update: test-project/ (sync to current templates via /update)
- create: docs/handoff-YYYY-MM-DD.md (end of each session)
</files>
<implementation>
- start_with: sync test-project + bump version + CHANGELOG
- order: validation loop first (highest value), then versioning, then process habits
- gotchas: test-project/Taskfile.python.yaml is old — run /update to sync before using it as baseline
- testing: after /update in test-project, run `task python:test` and `task python:lint` to confirm
</implementation>
</claude_context>

**Next Action:** Sync test-project to current templates, bump plugin to 1.1.0, add CHANGELOG.md.
