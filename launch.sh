#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== hypr-vault launch ==="
echo "Script dir : $SCRIPT_DIR"
echo "shell.qml  : $SCRIPT_DIR/scripts/shell.qml"

# Check shell.qml exists in scripts/
if [ ! -f "$SCRIPT_DIR/scripts/shell.qml" ]; then
    echo "ERROR: shell.qml not found in scripts/"
    exit 1
fi
echo "shell.qml found ✓"

# Check quickshell
if ! command -v quickshell &>/dev/null; then
    echo "ERROR: quickshell not found in PATH"
    echo "PATH=$PATH"
    exit 1
fi
echo "quickshell: $(command -v quickshell) ✓"

# Check node
if ! command -v node &>/dev/null; then
    echo "ERROR: node not found in PATH"
    echo "PATH=$PATH"
    exit 1
fi
echo "node      : $(command -v node) ✓"

# Kill any existing instance
pkill -f "quickshell.*hypr_vault" 2>/dev/null && echo "Killed old instance" || echo "No existing instance"

echo ""
echo "Running: quickshell -c $SCRIPT_DIR/scripts"
echo "-------------------------------"
exec quickshell -c "$SCRIPT_DIR/scripts"
