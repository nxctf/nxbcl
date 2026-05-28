#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${NXBCL_BIN_DIR:-$HOME/.local/bin}"
COMMAND="${1:-help}"

ensure_node22() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
  fi

  if ! command -v nvm >/dev/null 2>&1; then
    command -v curl >/dev/null 2>&1 || {
      echo "curl is required. Install it first: sudo apt install -y curl" >&2
      exit 1
    }

    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    if [ -s "$NVM_DIR/nvm.sh" ]; then
      . "$NVM_DIR/nvm.sh"
    else
      echo "nvm installation failed: $NVM_DIR/nvm.sh not found" >&2
      exit 1
    fi
  fi

  echo "Installing/using Node.js 22..."
  nvm install 22
  nvm alias default 22
  nvm use 22

  echo "Node: $(node -v)"
  echo "npm: $(npm -v)"
}

case "$COMMAND" in
  install)
    ensure_node22

    python3 -m pip install -r "$PROJECT_DIR/requirements.txt"

    mkdir -p "$BIN_DIR"
    cat > "$BIN_DIR/nxbcl" <<EOF
#!/usr/bin/env bash
set -euo pipefail

export NVM_DIR="\${NVM_DIR:-\$HOME/.nvm}"
if [ -s "\$NVM_DIR/nvm.sh" ]; then
  . "\$NVM_DIR/nvm.sh"
  nvm use 22 >/dev/null 2>&1 || true
fi

cd "$PROJECT_DIR"
exec python3 app.py "\$@"
EOF

    chmod +x "$BIN_DIR/nxbcl"

    echo "Installed nxbcl command to $BIN_DIR/nxbcl"
    echo "Frontend source is in nxbcl/src/frontend."
    echo "Build it with: bash $PROJECT_DIR/setup.sh frontend-install && bash $PROJECT_DIR/setup.sh frontend-build"

    case ":$PATH:" in
      *":$BIN_DIR:"*) ;;
      *)
        echo
        echo "Add this to your shell if nxbcl is not found:"
        echo "  export PATH=\"$BIN_DIR:\$PATH\""
        ;;
    esac
    ;;

  node-install)
    ensure_node22
    ;;

  frontend-install)
    ensure_node22
    cd "$PROJECT_DIR/src/frontend"
    npm install
    ;;

  frontend-build)
    ensure_node22
    cd "$PROJECT_DIR/src/frontend"
    npm run build
    ;;

  uninstall)
    rm -f "$BIN_DIR/nxbcl"
    echo "Removed $BIN_DIR/nxbcl"
    ;;

  help|--help|-h)
    echo "Usage: bash nxbcl/setup.sh install|node-install|frontend-install|frontend-build|uninstall"
    echo
    echo "After install:"
    echo "  nxbcl init-db"
    echo "  nxbcl sync --dry-run"
    echo "  nxbcl challenges"
    echo "  nxbcl up"
    echo "  nxbcl ps"
    echo "  nxbcl down"
    echo "  nxbcl ps --kill"
    echo "  nxbcl serve --port 8080"
    echo
    echo "Frontend:"
    echo "  bash nxbcl/setup.sh frontend-install"
    echo "  bash nxbcl/setup.sh frontend-build"
    echo
    echo "Node:"
    echo "  bash nxbcl/setup.sh node-install"
    ;;

  *)
    echo "Unknown command: $COMMAND" >&2
    echo "Usage: bash nxbcl/setup.sh install|node-install|frontend-install|frontend-build|uninstall" >&2
    exit 1
    ;;
esac
