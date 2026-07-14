#!/usr/bin/env bash
# Linux / WSL setup: reads manifest.yaml and installs each tool via apt.
# Assumes a Debian/Ubuntu-based distro. Adapt the apt-specific bits below
# if you're on something else.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if ! command -v apt-get &>/dev/null; then
  warn "This script assumes apt (Debian/Ubuntu). Adapt it for your distro."
  exit 1
fi

sudo apt-get update -y
ensure_yq

install_apt_package() {
  local pkg="$1"
  if dpkg -s "$pkg" &>/dev/null; then
    log "$pkg already installed, skipping"
  else
    log "Installing $pkg via apt"
    sudo apt-get install -y "$pkg"
  fi
}

install_docker_engine() {
  if is_wsl; then
    warn "WSL detected: skipping Docker Engine install."
    warn "Install Docker Desktop on the Windows host and enable WSL integration for this distro instead."
    return
  fi
  if command -v docker &>/dev/null; then
    log "docker already installed, skipping"
    return
  fi
  log "Installing Docker Engine via Docker's official apt repo"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER"
  log "Added $USER to the docker group. Log out/in for it to take effect."
}

install_vscode() {
  if command -v code &>/dev/null; then
    log "vscode already installed, skipping"
    return
  fi
  log "Installing VS Code via Microsoft's apt repo"
  sudo apt-get install -y wget gpg
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
  rm -f /tmp/packages.microsoft.gpg
  sudo apt-get update -y
  sudo apt-get install -y code
}

install_rider() {
  if command -v rider &>/dev/null || snap list rider &>/dev/null 2>&1; then
    log "rider already installed, skipping"
    return
  fi
  if command -v snap &>/dev/null; then
    log "Installing Rider via snap"
    sudo snap install rider --classic
  else
    warn "snap not available; install Rider manually via JetBrains Toolbox: https://www.jetbrains.com/toolbox-app/"
  fi
}

count=$(manifest_tool_count)
for ((i = 0; i < count; i++)); do
  name=$(manifest_field "$i" .name)
  special=$(manifest_field "$i" .apt.special)
  pkg=$(manifest_field "$i" .apt.package)

  case "$special" in
    docker-engine) install_docker_engine ;;
    vscode-repo)   install_vscode ;;
    rider-snap)    install_rider ;;
    null|"")
      if [[ "$pkg" != "null" && -n "$pkg" ]]; then
        install_apt_package "$pkg"
      else
        warn "No apt install method defined for $name, skipping"
      fi
      ;;
    *) warn "Unknown special installer '$special' for $name, skipping" ;;
  esac
done

"$SCRIPT_DIR/lib/apply-dotfiles.sh"
"$SCRIPT_DIR/lib/vscode-extensions.sh"

log "Linux/WSL setup complete"
