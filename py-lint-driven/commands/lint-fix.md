---
name: lint-fix
description: Fix all linting and test issues in the project or a specific path. Runs the full fix/verify loop until clean or iteration limit hit.
argument-hint: "[path — optional, defaults to current directory]"
---

# /lint-fix Command

Run the unified fix/verify quality loop on existing code.

## Arguments

`$ARGUMENTS` — optional path (file or directory). Defaults to `.` (whole project).

## Flow

1. **Iterate until clean**
   - If `$ARGUMENTS` is provided: use the `iterate-until-clean` skill on that path.
   - If no argument: use the `iterate-until-clean` skill with `scope: git` — scopes
     linting to git-changed Python files (staged, unstaged, new untracked).
     Falls back to `.` if no git changes detected.
   Repeats up to `iteration_limit` times.

2. **Report**
   Use the `report-quality` skill to display the final quality summary.
