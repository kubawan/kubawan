#!/usr/bin/env bash
# Applies git config from the template and checks for an SSH key.
# Doesn't touch shell rc files beyond what's in dotfiles/ (see README).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

git_name=$(git config --global user.name || true)
git_email=$(git config --global user.email || true)

if [[ -z "$git_name" ]]; then
  read -rp "Git user.name not set. Enter it now (blank to skip): " git_name
fi
if [[ -z "$git_email" ]]; then
  read -rp "Git user.email not set. Enter it now (blank to skip): " git_email
fi

if [[ -n "$git_name" ]]; then
  git config --global user.name "$git_name"
fi
if [[ -n "$git_email" ]]; then
  git config --global user.email "$git_email"
fi

git config --global include.path "$REPO_ROOT/dotfiles/gitconfig-shared"

ssh_dir="$HOME/.ssh"
if ls "$ssh_dir"/id_* &>/dev/null 2>&1; then
  log "SSH key already present in $ssh_dir, skipping"
else
  warn "No SSH key found in $ssh_dir."
  warn "Generate one with: ssh-keygen -t ed25519 -C \"$git_email\""
fi
