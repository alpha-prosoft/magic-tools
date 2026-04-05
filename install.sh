#!/usr/bin/env bash
set -euo pipefail

# magic-ide install script
# Installs general dev tooling — nvim is handled by its own setup.sh.
# Re-runnable: shell config block is replaced in-place via markers.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="$HOME/.bashrc"
MARKER="# >>> magic-ide >>>"
SOURCE_LINE="source ~/magic-ide/shell-init.bash $MARKER"

JDK_URL="https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.tar.gz"
JAVA_INSTALL_DIR="/opt/java"

# ── Helpers ───────────────────────────────────────────────────────────

info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*"; exit 1; }

# ── System packages ──────────────────────────────────────────────────

install_packages() {
  info "Installing system packages …"
  sudo apt-get update
  sudo apt-get install -y \
    git \
    curl \
    unzip \
    nodejs \
    npm \
    python3 \
    python3-pip \
    python3-venv
  info "System packages installed"
}

# ── Amazon Corretto JDK 21 ──────────────────────────────────────────

install_jdk() {
  info "Installing Amazon Corretto JDK 21 …"
  local tmp; tmp=$(mktemp)
  curl -fSL -o "$tmp" "$JDK_URL"

  sudo rm -rf "$JAVA_INSTALL_DIR"
  sudo mkdir -p "$JAVA_INSTALL_DIR"
  sudo tar xzf "$tmp" --strip-components=1 -C "$JAVA_INSTALL_DIR"
  rm -f "$tmp"

  info "JDK installed to $JAVA_INSTALL_DIR"
  "$JAVA_INSTALL_DIR/bin/java" -version
}

# ── Shell config ─────────────────────────────────────────────────────
# Single source line in .bashrc tagged with a marker comment.
# Re-runs replace it in-place via sed; first run appends.

configure_shell() {
  local init_file="$SCRIPT_DIR/shell-init.bash"
  [[ -f "$init_file" ]] || error "shell-init.bash not found at $init_file"

  touch "$BASHRC"

  if grep -qF "$MARKER" "$BASHRC"; then
    info "Replacing magic-ide line in $BASHRC"
    sed -i "s|.*${MARKER}.*|${SOURCE_LINE}|" "$BASHRC"
  else
    info "Appending magic-ide line to $BASHRC"
    printf '\n%s\n' "$SOURCE_LINE" >> "$BASHRC"
  fi

  # shellcheck disable=SC1090
  source "$init_file"
  info "Shell configured — restart your shell or: source $BASHRC"
}

# ── Main ─────────────────────────────────────────────────────────────

main() {
  info "=== magic-ide Setup ==="
  echo
  install_packages
  install_jdk
  configure_shell
  echo
  info "=== Setup complete ==="
}

main "$@"
