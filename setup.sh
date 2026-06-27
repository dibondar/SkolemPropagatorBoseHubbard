#!/usr/bin/env bash
#
# Reproducible environment setup for the Skolem Propagator Bose-Hubbard project.
#
# Creates a local Python virtual environment in ./.venv, installs the pinned
# dependencies (QuSpin + Jupyter + matplotlib), and registers a Jupyter kernel
# so the demo notebooks can be run from VS Code / JupyterLab.
#
# Usage:
#   ./setup.sh
#
# Then either:
#   source .venv/bin/activate        # use from the terminal
# or select the "Python (.venv SkolemPropagator)" kernel in your notebook.

set -euo pipefail

# Resolve the directory this script lives in, so it works from anywhere.
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

VENV_DIR=".venv"
PYTHON="${PYTHON:-python3}"

echo "==> Using Python: $("$PYTHON" --version)"

# QuSpin 1.0.1 only ships PyPI wheels for CPython 3.12. Guard against other
# versions so users get a clear message instead of a confusing build failure.
PY_VER="$("$PYTHON" -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
if [ "$PY_VER" != "3.12" ]; then
    echo "ERROR: QuSpin 1.0.1 requires Python 3.12, but '$PYTHON' is $PY_VER." >&2
    echo "       Install Python 3.12 and re-run with, e.g.:" >&2
    echo "         PYTHON=python3.12 ./setup.sh" >&2
    exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
    echo "==> Creating virtual environment in $VENV_DIR"
    "$PYTHON" -m venv "$VENV_DIR"
else
    echo "==> Reusing existing virtual environment in $VENV_DIR"
fi

# Use the venv's interpreter directly (no need to activate).
VENV_PY="$VENV_DIR/bin/python"

echo "==> Upgrading pip"
"$VENV_PY" -m pip install --upgrade pip

echo "==> Installing dependencies from requirements.txt"
"$VENV_PY" -m pip install -r requirements.txt

echo "==> Registering Jupyter kernel"
"$VENV_PY" -m ipykernel install --user \
    --name skolem-venv \
    --display-name "Python (.venv SkolemPropagator)"

echo
echo "==> Verifying QuSpin import"
"$VENV_PY" -c "import quspin; print('QuSpin', quspin.__version__, 'imported successfully')"

echo
echo "Done. To use the environment:"
echo "  source $VENV_DIR/bin/activate          # terminal"
echo "  or select the 'Python (.venv SkolemPropagator)' kernel in your notebook."
