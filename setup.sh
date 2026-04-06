#!/usr/bin/env bash
set -euo pipefail

# tools install script
# Installs general dev tooling.
# Re-runnable: shell config block is replaced in-place via markers.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="$HOME/.bashrc"
MARKER="# >>> tools >>>"
SOURCE_LINE="source ~/.config/tools/shell-init.bash $MARKER"

JDK_URL="https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.tar.gz"
JAVA_INSTALL_DIR="/opt/java"

# ── Helpers ───────────────────────────────────────────────────────────

info() { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
error() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$*"
  exit 1
}

# ── System packages ──────────────────────────────────────────────────

install_packages() {
  info "Installing system packages …"
  sudo apt-get update
  sudo apt-get install -y \
    git \
    curl \
    unzip \
    nodejs \
    maven \
    net-tools \
    direnv npm \
    python3 \
    python3-pip \
    python3-venv \
    rlwrap
  info "System packages installed"
}

# ── Amazon Corretto JDK 21 ──────────────────────────────────────────

install_jdk() {
  info "Installing Amazon Corretto JDK 21 …"
  local tmp
  tmp=$(mktemp)
  curl -fSL -o "$tmp" "$JDK_URL"

  sudo rm -rf "$JAVA_INSTALL_DIR"
  sudo mkdir -p "$JAVA_INSTALL_DIR"
  sudo tar xzf "$tmp" --strip-components=1 -C "$JAVA_INSTALL_DIR"
  rm -f "$tmp"

  info "JDK installed to $JAVA_INSTALL_DIR"
  "$JAVA_INSTALL_DIR/bin/java" -version
}

# ── Clojure ──────────────────────────────────────────────────────────

install_clojure() {
  info "Installing Clojure …"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  curl -fSL -O --output-dir "$tmp_dir" \
    https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh
  chmod +x "$tmp_dir/linux-install.sh"
  sudo "$tmp_dir/linux-install.sh"
  rm -rf "$tmp_dir"
  info "Clojure installed — $(clojure --version 2>&1 | head -1)"
}

# ── Shell config ─────────────────────────────────────────────────────
# Single source line in .bashrc tagged with a marker comment.
# Re-runs replace it in-place via sed; first run appends.

configure_shell() {
  local init_file="$SCRIPT_DIR/shell-init.bash"
  [[ -f "$init_file" ]] || error "shell-init.bash not found at $init_file"

  touch "$BASHRC"

  if grep -qF "$MARKER" "$BASHRC"; then
    info "Replacing tools line in $BASHRC"
    sed -i "s|.*${MARKER}.*|${SOURCE_LINE}|" "$BASHRC"
  else
    info "Appending tools line to $BASHRC"
    printf '\n%s\n' "$SOURCE_LINE" >>"$BASHRC"
  fi

  # shellcheck disable=SC1090
  source "$init_file"
  info "Shell configured — restart your shell or: source $BASHRC"
}

# ── Main ─────────────────────────────────────────────────────────────

main() {
  info "=== Tools Setup ==="
  echo
  install_packages
  install_jdk
  install_clojure
  configure_shell
  echo
  info "=== Setup complete ==="
}

main "$@"
