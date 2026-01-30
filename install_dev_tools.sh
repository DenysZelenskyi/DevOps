#!/usr/bin/env bash
set -euo pipefail

log()  { echo -e "\033[1;32m[+] $*\033[0m"; }
warn() { echo -e "\033[1;33m[!] $*\033[0m"; }
err()  { echo -e "\033[1;31m[✗] $*\033[0m"; }

TARGET_USER="${SUDO_USER:-$USER}"
APT_UPDATED=0

apt_update_once() {
  if [ "$APT_UPDATED" -eq 0 ]; then
    log "Updating apt index..."
    sudo apt-get update -y
    APT_UPDATED=1
  fi
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker is already installed: $(docker --version)"
    return
  fi

  log "Installing Docker Engine..."
  sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

  apt_update_once
  sudo apt-get install -y ca-certificates curl gnupg

  # Add Docker's official GPG key
  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg" \
      | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  # Set up the Docker repository
  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
$(. /etc/os-release; echo "$VERSION_CODENAME") stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  fi

  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker

  # Add user to docker group for running without sudo
  if id -nG "$TARGET_USER" | grep -qw docker; then
    log "User $TARGET_USER is already in docker group"
  else
    sudo usermod -aG docker "$TARGET_USER"
    warn "Added $TARGET_USER to docker group. Please re-login or run: newgrp docker"
  fi

  log "Docker installed: $(docker --version)"
}

install_docker_compose() {
  if docker compose version >/dev/null 2>&1; then
    log "Docker Compose (plugin) is already installed: $(docker compose version)"
  else
    warn "Docker compose plugin not found. Installing..."
    apt_update_once
    sudo apt-get install -y docker-compose-plugin
  fi

  # Backward-compatible shim for docker-compose command
  if ! command -v docker-compose >/dev/null 2>&1; then
    log "Creating compatibility shim 'docker-compose' -> 'docker compose'..."
    echo '#!/usr/bin/env bash
exec docker compose "$@"' | sudo tee /usr/local/bin/docker-compose >/dev/null
    sudo chmod +x /usr/local/bin/docker-compose
  fi
}

install_python() {
  if command -v python3 >/dev/null 2>&1; then
    PYV="$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')"
    if python3 - <<'PY' 2>/dev/null; then
import sys
raise SystemExit(0 if sys.version_info >= (3,9) else 1)
PY
      log "Python3 is already OK (>=3.9): $PYV"
      return
    else
      warn "Current Python version: $PYV (<3.9). Installing python3/pip/venv from apt..."
    fi
  else
    log "Python3 not found. Installing..."
  fi

  apt_update_once
  sudo apt-get install -y python3 python3-pip python3-venv
  log "Python3 installed: $(python3 --version 2>/dev/null || echo 'ok')"
}

install_django() {
  # If Django is already importable (either system or user site-packages) - OK
  if python3 -c "import django; print(django.get_version())" >/dev/null 2>&1; then
    DJV="$(python3 -c 'import django; print(django.get_version())')"
    log "Django is already installed: $DJV"
    return
  fi

  # macOS/Homebrew: pip may be blocked by PEP 668 → install Django in a venv
  if [ "$(uname -s)" = "Darwin" ]; then
    VENV_DIR="$HOME/.venvs/django"
    mkdir -p "$HOME/.venvs"

    if [ -x "$VENV_DIR/bin/python" ] && "$VENV_DIR/bin/python" -c "import django" >/dev/null 2>&1; then
      DJV="$("$VENV_DIR/bin/python" -c 'import django; print(django.get_version())')"
      log "Django already installed in venv ($VENV_DIR): $DJV"
      return
    fi

    log "macOS detected. Creating venv at $VENV_DIR and installing Django..."
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install --upgrade pip
    "$VENV_DIR/bin/pip" install "Django>=4.2"
    log "Django installed in venv: $("$VENV_DIR/bin/python" -m django --version)"
    warn "To use Django now run: source \"$VENV_DIR/bin/activate\""
    return
  fi

  # Ubuntu/Debian: install via pip in user scope
  if ! command -v pip3 >/dev/null 2>&1; then
    apt_update_once
    sudo apt-get install -y python3-pip
  fi

  log "Installing Django via pip (user scope)..."
  pip3 install --user "Django>=4.2"

  if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    warn 'Added $HOME/.local/bin to PATH (~/.bashrc). Open a new shell for "django-admin" to be available.'
  fi

  log "Django installed: $(python3 -c 'import django; print(django.get_version())')"
}

main() {
  if [ -f /etc/os-release ]; then
    if ! grep -qiE 'ubuntu|debian' /etc/os-release; then
      warn "This script is designed for Ubuntu/Debian. Continuing at your own risk :)"
    fi
  else
    warn "/etc/os-release not found. You are likely not on Linux (Ubuntu/Debian). Some steps may not work."
  fi

  install_docker
  install_docker_compose
  install_python
  install_django

  log "Done. Quick check commands:"
  echo "  docker --version"
  echo "  docker compose version"
  echo "  python3 --version"
  echo "  python3 -m django --version"
}

main "$@"
