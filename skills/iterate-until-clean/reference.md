# iterate-until-clean — Reference

Detailed failure handling and fix strategies for the fix/verify loop.

## Failure Types and Handling

### Test failures

**Collection errors** (ImportError, SyntaxError in test files):
- Surface immediately to the user
- Do NOT attempt to fix — the test file is broken and requires manual intervention
- Stop the iteration

**Assertion failures** (tests run but fail):
- Fix the implementation in the source file
- Never modify the test file — tests are the spec
- Group related fixes: fix all failures in the same module together

### Ruff violations

Run `task python:ruff:fix` first — handles most violations automatically.
Remaining violations after auto-fix need manual changes. Common ones:
- E501 (line too long) → break with parentheses, not backslash
- F401 (unused import) → remove the import
- B006 (mutable default argument) → replace `def f(x=[])` with `def f(x=None): x = x or []`

### Complexity violations (complexipy)

Cannot be auto-fixed. Before applying any refactor:
1. Identify the specific function and its score
2. Propose a concrete refactor strategy (see strategies below)
3. **Wait for user confirmation**
4. Apply only after confirmation

Reduction strategies:
- Extract nested blocks into named helper functions
- Replace deeply nested conditionals with early returns (`if not x: return`)
- Split a function doing multiple things into focused single-purpose functions
- Replace repeated conditional branches with a dispatch dict or polymorphism

### Cyclomatic violations (xenon)

Same protocol as complexipy: propose → confirm → apply.
Xenon reports at block and module level. A module violation usually means
one or more functions need refactoring — identify the worst offender first.

## Grouping Rule

Do not fix one violation at a time. Group all violations of the same type in the
same file and fix them together. For example, fix all E501 violations in
`src/module.py` in a single Edit call.

## Output Formats

### On success

```
Clean after <N> iteration(s):
- Tests fixed: <N>
- Ruff violations fixed: <N>
- Format issues fixed: <N>
All checks passing ✓
```

### On limit hit

```
Iteration limit (5) reached. Remaining issues:
- Tests: 1 still failing — tests/test_module.py::test_edge_case
- Ruff: 2 violations — src/module.py:45, src/utils.py:12
- Complexity (complexipy): 1 function still above threshold — process_data (score: 18)
- Cyclomatic (xenon): grade B exceeded in src/module.py

Action required: fix these manually before proceeding.
```

## Task Reference

| Pass | Execution |
|---|---|
| Fix pass | `XENON_MAX_ABSOLUTE=<v> XENON_MAX_MODULES=<v> XENON_MAX_AVERAGE=<v> task python:tdd:fix` (sequential) |
| Verify pass | `quality-analyzer` agent (parallel) |

`tdd:fix` runs sequentially: test → ruff:fix → complexity → cyclomatic → fmt
Order matters in the fix pass: ruff:fix changes files before complexity is checked.

`quality-analyzer` runs in parallel: test + ruff + complexipy + xenon simultaneously.
All tools report even if one fails. Returns CLEAN, TEST_FAILURE, or ISSUES_FOUND.
