#!/usr/bin/env bash
# Shared helpers sourced by scripts/macos.sh and scripts/linux.sh.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$REPO_ROOT/manifest.yaml"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

is_wsl() {
  [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null
}

ensure_yq() {
  if command -v yq &>/dev/null; then
    return
  fi
  log "yq not found, installing it (used to read manifest.yaml)"
  if command -v brew &>/dev/null; then
    brew install yq
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update -y && sudo apt-get install -y yq
  else
    warn "Could not install yq automatically. Install it manually: https://github.com/mikefarah/yq"
    exit 1
  fi
}

# Print the number of tools in the manifest.
manifest_tool_count() {
  yq '.tools | length' "$MANIFEST"
}

# Print a field for tool index $1, e.g. manifest_field 0 .name
manifest_field() {
  local idx="$1" path="$2"
  yq -r ".tools[$idx]$path" "$MANIFEST"
}
