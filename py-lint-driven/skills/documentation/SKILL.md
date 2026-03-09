---
name: documentation
description: Audit and write Python documentation — module docstrings, function/class docstrings, and type annotations. Use when the user asks to "add docs", "document this", "write docstrings", "add type hints", or "clean up documentation". Also use at the end of the /autopilot command after code is clean. Focuses on public APIs only — private helpers and trivial getters are low priority.
---

# documentation Skill

Audit and write documentation for Python source files. Focuses on public APIs.

## What Gets Documented

### Module-level docstring
Every `src/*.py` file should have a module docstring describing its purpose.
```python
"""
User authentication and session management.

Handles login, logout, token validation, and session expiry.
"""
```

### Public functions and methods
Any function or method without a leading `_` that has non-obvious behavior.
Skip trivial getters/setters and one-liners where the signature is self-documenting.

Use Google-style docstrings:
```python
def validate_email(email: str) -> bool:
    """Check whether a string is a valid email address.

    Args:
        email: The string to validate.

    Returns:
        True if the email is valid, False otherwise.
    """
```

For functions that raise exceptions, document them:
```python
    Raises:
        ValueError: If email is an empty string.
```

### Public classes
Class docstring describing the purpose. Document `__init__` parameters if the
class has more than 2.

### Type annotations
Every public function parameter and return type should be annotated.
Use `from __future__ import annotations` at the top of the file if needed for
forward references. Use `Optional[X]` or `X | None` consistently (match the
existing file style).

## What NOT to Document

- Private functions (`_name`) — skip unless they have complex logic
- Trivial properties (e.g., `@property def name(self) -> str: return self._name`)
- Test files — test function names should be self-documenting
- One-line functions where the signature + name fully describe the behavior

## Audit Mode

When called without a write instruction ("check docs", "audit documentation"):
1. List every public function/class missing a docstring
2. List every public function missing type annotations
3. Report as a checklist — do not write docs unless asked

## Write Mode

When asked to write documentation:
1. Read the function body and existing tests to infer intent
2. Write the docstring — do not pad with obvious information
3. Add missing type annotations
4. Do not change any logic

## Report Format

```
Documentation complete: src/users.py

Added docstrings:
  - module docstring
  - UserService class
  - UserService.create_user
  - UserService.find_by_email

Added type annotations:
  - create_user: email: str, role: UserRole -> User
  - find_by_email: email: str -> User | None

Skipped (trivial or private):
  - _hash_password (private)
  - name property (self-documenting)
```
