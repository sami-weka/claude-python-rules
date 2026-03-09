---
name: pre-commit-review
description: Advisory design review of Python code before committing. Detects design debt (primitive obsession, missing type annotations, bare excepts, mixed abstraction levels, validation in wrong layer) and readability debt. Use this skill after tests pass and linting is clean — it looks beyond mechanical checks at semantic quality. Also use when the user asks to "review this code", "check code quality", "is this well designed", or "give me feedback before I commit". Never blocks — findings are advisory only.
---

# pre-commit-review Skill

Advisory design review. Reports findings — never blocks, never makes changes.
The user decides what to fix.

## When to Run

After tests pass and linting is clean. This skill looks at things ruff, complexipy,
and xenon cannot: design quality, abstraction clarity, type modeling, error handling
patterns.

## What to Look For

### 🔴 Design Debt — recommend fixing

**Primitive obsession**
Using `str`, `int`, `dict` where a named type, dataclass, or TypedDict would make
the intent explicit and the interface self-documenting.
```python
# red flag
def create_user(name: str, email: str, role: str) -> dict: ...

# better
@dataclass
class User:
    name: str
    email: Email
    role: UserRole
```

**Missing type annotations on public functions**
Any public function (no leading `_`) without full parameter and return type
annotations. Private helpers are lower priority.

**Bare `except:` or `except Exception:` swallowing errors**
Catching broad exceptions without logging or re-raising means failures disappear
silently. Flag any broad catch that doesn't log and re-raise.

**Validation in the wrong layer**
Input validation buried deep in business logic instead of at the system boundary
(API handler, CLI entry point, constructor). Logic functions should be able to
trust their inputs.

**Mixed abstraction levels in one function**
A function that both orchestrates high-level steps AND does low-level work (string
parsing, file I/O, arithmetic) in the same body. Each function should operate at
one level of abstraction.

### 🟡 Readability Debt — suggest improving

**God functions**
Functions that do more than one logical thing — identifiable by "and" in the
description of what they do, or multiple distinct phases of work.

**Inconsistent error handling**
Some paths raise, some return `None`, some return empty collections — no clear
contract. Flag when the same module uses multiple incompatible error strategies.

**Mutable default arguments**
`def fn(items: list = [])` — Python gotcha, always flag.

**Long parameter lists**
More than 4 parameters suggests the function is doing too much or the parameters
should be grouped into a dataclass.

### 🟢 Polish — note if relevant

- Docstrings missing on public classes/functions that have non-obvious behavior
- Magic numbers/strings that could be named constants
- Commented-out code left in

## Report Format

```
## Pre-Commit Design Review — <path>

### 🔴 Design Debt
- `create_user` in src/users.py — primitive obsession: `name`, `email`, `role` as
  plain strings. Consider a `UserRequest` dataclass to make the interface explicit.
- `process_payment` in src/payments.py — bare `except Exception: pass` on line 42.
  Silent failure on payment errors is dangerous.

### 🟡 Readability Debt
- `handle_request` in src/api.py — mixed abstraction levels: parses raw bytes AND
  applies business rules in the same function. Extract parsing into a helper.

### 🟢 Polish
- `calculate_total` in src/cart.py — magic number `0.15` (tax rate?) should be a
  named constant.

### Summary
3 findings: 2 design debt, 1 readability debt, 1 polish
These are advisory — fix what makes sense for your context.
```

If no findings: output "Design review: no issues found ✓"

## Scope

Default: all files changed since last commit (`git diff --name-only HEAD`).
If a path is provided, scope to that path only.
Never review test files for design debt — test code has different standards.
