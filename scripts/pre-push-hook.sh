#!/bin/bash
# Pre-push hook for ai-python-rules.
#
# Install:
#   cp scripts/pre-push-hook.sh .git/hooks/pre-push
#   chmod +x .git/hooks/pre-push
#
# What it does:
#   1. If templates changed: runs `task validate` (YAML + sync + test/lint in test-project)
#   2. If plugin files changed: enforces version bump and plugin.json/marketplace.json sync

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

TEMPLATE_CHANGED=0
PLUGIN_CHANGED=0

while IFS=' ' read -r local_ref local_sha remote_ref remote_sha; do
    if [ "$local_sha" = "0000000000000000000000000000000000000000" ]; then
        # Branch being deleted — skip
        continue
    fi

    if [ "$remote_sha" = "0000000000000000000000000000000000000000" ]; then
        # New branch — compare against empty tree
        BASE=$(git hash-object -t tree /dev/null)
    else
        BASE="$remote_sha"
    fi

    if git diff --name-only "$BASE".."$local_sha" -- py-lint-driven/templates/ 2>/dev/null | grep -q .; then
        TEMPLATE_CHANGED=1
    fi

    if git diff --name-only "$BASE".."$local_sha" -- \
        py-lint-driven/templates/ \
        py-lint-driven/hooks/ \
        py-lint-driven/commands/ \
        py-lint-driven/skills/ \
        py-lint-driven/agents/ \
        2>/dev/null | grep -q .; then
        PLUGIN_CHANGED=1
    fi

    # Capture BASE for version check below (last ref wins, sufficient for single-branch pushes)
    PUSH_BASE="$BASE"
done

# --- 1. Template validation ---
if [ "$TEMPLATE_CHANGED" -eq 1 ]; then
    echo "==> Template changes detected. Running task validate..."
    if ! task validate; then
        echo "ERROR: Plugin validation failed. Fix before pushing."
        exit 1
    fi
fi

# --- 2. Version enforcement ---
if [ "$PLUGIN_CHANGED" -eq 1 ] && [ -n "${PUSH_BASE:-}" ]; then
    CURRENT=$(python3 -c "import json; print(json.load(open('py-lint-driven/plugin.json'))['version'])")
    REMOTE=$(git show "${PUSH_BASE}:py-lint-driven/plugin.json" 2>/dev/null \
        | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])" 2>/dev/null \
        || echo "0.0.0")

    if [ "$CURRENT" = "$REMOTE" ]; then
        echo "ERROR: Plugin files changed but version is still $CURRENT."
        echo "  task bump:patch   — bug fixes, allowed-tools additions"
        echo "  task bump:minor   — new commands, skills, tasks"
        echo "  task bump:major   — breaking changes"
        exit 1
    fi

    # Check plugin.json and marketplace.json agree
    MARKETPLACE=$(python3 -c \
        "import json; d=json.load(open('.claude-plugin/marketplace.json')); print(d['metadata']['version'])")
    if [ "$CURRENT" != "$MARKETPLACE" ]; then
        echo "ERROR: Version mismatch: plugin.json=$CURRENT, marketplace.json=$MARKETPLACE"
        echo "  Run task bump:patch/minor/major to sync both files atomically."
        exit 1
    fi
fi

exit 0
