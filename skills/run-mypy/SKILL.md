---
name: run-mypy
description: Run mypy type checking on Python files and interpret the results. Use this skill when the user asks to "check types", "run mypy", "find type errors", or "type check this". Also use it when mypy_enabled is true in py-lint-driven.local.md and the iterate-until-clean loop encounters type errors. This skill is opt-in — do not run mypy automatically unless mypy_enabled is true in config.
---

# run-mypy Skill

Run mypy type checking and interpret the output.

## When to use

Only run mypy when one of these is true:
- User explicitly asks to check types or run mypy
- `mypy_enabled: true` is set in `py-lint-driven.local.md`

Do not add mypy to the standard lint/tdd loop unless it is explicitly enabled.

## Running mypy

```bash
task python:mypy
# or for specific files:
task python:mypy FILES=src/module.py
```

## Interpreting output

mypy errors follow this format:
```
src/module.py:42: error: Item "None" of "User | None" has no attribute "name"  [union-attr]
```

Fields: `file:line: error: message  [error-code]`

Common error codes and fixes:

| Code | Meaning | Fix |
|---|---|---|
| `union-attr` | Accessed attribute on a type that could be None | Add `if x is not None:` guard |
| `arg-type` | Wrong argument type passed to function | Fix the call site or the type annotation |
| `return-value` | Return type doesn't match annotation | Fix implementation or annotation |
| `import-untyped` | Importing a package with no type stubs | Add `ignore_missing_imports = true` to pyproject.toml or install stubs (`pip install types-<pkg>`) |
| `no-untyped-def` | Function missing type annotations | Add annotations (only if `strict = true` is set) |

## Config (pyproject.toml)

Uncomment the mypy section in pyproject.toml and adjust:

```toml
[tool.mypy]
python_version = "3.11"
ignore_missing_imports = true   # silence errors for third-party libs without stubs
# strict = true                 # enable all checks — only for fully-annotated codebases
```

## First-time setup

If mypy is not installed:
```bash
pip install mypy
```

For common third-party libraries, install type stubs:
```bash
pip install types-requests types-PyYAML
```

## On violation

Report each error with file, line, and a one-sentence explanation of the fix. If there are more than 10 errors, group them by error code and summarize the pattern rather than listing every line.
