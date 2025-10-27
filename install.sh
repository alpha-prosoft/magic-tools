#!/usr/bin/env bash
set -euo pipefail

# magic-ide install script
# Installs general dev tooling — nvim is handled by its own setup.sh.
# Re-runnable: shell config block is replaced in-place via markers.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="$HOME/.bashrc"
MARKER_BEGIN="# >>> magic-ide >>>"
MARKER_END="# <<< magic-ide <<<"

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
# Sources shell-init.bash from .bashrc via a marker block.
# Re-runs replace the block in-place (awk -> tmp -> mv = atomic).

configure_shell() {
  local init_file="$SCRIPT_DIR/shell-init.bash"
  [[ -f "$init_file" ]] || error "shell-init.bash not found at $init_file"

  local block
  block="$(printf '%s\n' "$MARKER_BEGIN" "source \"$init_file\"" "$MARKER_END")"

  touch "$BASHRC"

  if grep -qF "$MARKER_BEGIN" "$BASHRC"; then
    info "Replacing magic-ide block in $BASHRC"
    local tmp; tmp=$(mktemp)
    awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" -v new="$block" '
      $0 == begin { print new; skip=1; next }
      skip && $0 == end { skip=0; next }
      !skip { print }
    ' "$BASHRC" > "$tmp" && mv "$tmp" "$BASHRC"
  else
    info "Appending magic-ide block to $BASHRC"
    printf '\n%s\n' "$block" >> "$BASHRC"
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
