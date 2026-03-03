#!/usr/bin/env bash

PLUGIN_REPO="sami-weka/claude-python-rules"
TEMPLATES="py-lint-driven/templates"
TMP_DIR="$(mktemp -d)"

echo "==> py-lint-driven setup"

# --- Check prerequisites ---

missing=()
for cmd in ruff complexipy radon pytest task gh; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
done

if [ ${#missing[@]} -gt 0 ]; then
    echo ""
    echo "Missing tools: ${missing[*]}"
    echo "Install with:"
    echo "  pip install ruff complexipy radon pytest"
    echo "  brew install go-task gh"
    echo ""
    echo "Then re-run this script."
    exit 1
fi

echo "--> Prerequisites OK"

# --- Clone plugin repo to tmp ---

gh repo clone "$PLUGIN_REPO" "$TMP_DIR" -- --depth=1 --quiet
echo "--> Plugin repo fetched"

# --- Create directories ---

mkdir -p taskfiles .github/workflows src tests
echo "--> Directories created"

# --- Copy templates ---

cp "$TMP_DIR/$TEMPLATES/Taskfile.yaml" Taskfile.yaml
cp "$TMP_DIR/$TEMPLATES/Taskfile.python.yaml" taskfiles/Taskfile.python.yaml
cp "$TMP_DIR/$TEMPLATES/py-lint-driven.local.md" py-lint-driven.local.md
cp "$TMP_DIR/$TEMPLATES/.github/workflows/python-quality.yml" .github/workflows/python-quality.yml
echo "--> Templates copied"

# --- Create conftest.py if missing ---

if [ ! -f conftest.py ]; then
    cat > conftest.py << 'EOF'
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
EOF
    echo "--> conftest.py created"
fi

# --- Cleanup ---

rm -rf "$TMP_DIR"

# --- Done ---

echo ""
echo "Setup complete. Files created:"
echo "  Taskfile.yaml"
echo "  taskfiles/Taskfile.python.yaml"
echo "  py-lint-driven.local.md"
echo "  .github/workflows/python-quality.yml"
echo "  conftest.py"
echo ""
echo "Run 'task python:tdd' to get started."
