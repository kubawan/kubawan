# kubawan dev environment setup

One manifest (`manifest.yaml`), thin per-OS install scripts. Run the
matching entry point on a fresh machine and you get the same tools, git
config, and VS Code extensions everywhere.

## Getting started

```
git clone git@github.com:kubawan/kubawan.git
cd kubawan/dev-setup
```

## Usage

Run these from inside `dev-setup/`.

| Environment           | Command                                             |
|------------------------|------------------------------------------------------|
| macOS                  | `./install.sh`                                        |
| Linux (Debian/Ubuntu)  | `./install.sh`                                        |
| WSL (Debian/Ubuntu)    | `./install.sh` (installs into the WSL distro; see Docker note below) |
| Windows                | `.\install.ps1` from an elevated PowerShell            |

## What's managed

- **Tools/SDKs** (`manifest.yaml`): git, docker, .NET SDK, VS Code, Rider —
  add more entries to extend it. Each entry lists a `brew`, `apt`, and
  `winget` install method.
- **Git config** (`dotfiles/gitconfig-shared`): non-identity settings
  (default branch, pull behavior) included into `~/.gitconfig` via
  `include.path`. `user.name`/`user.email` are prompted for and stay in the
  real `~/.gitconfig`, not in this repo.
- **SSH**: scripts check for an existing key in `~/.ssh` and print a
  `ssh-keygen` command if none is found. Keys are never generated
  automatically.
- **VS Code extensions** (`config/vscode/extensions.txt`): installed via
  `code --install-extension` if `code` is on PATH.

## Notes

- Linux/WSL scripts assume a Debian/Ubuntu apt-based distro.
- **Docker on WSL**: don't install the Linux engine inside the distro.
  Install Docker Desktop on the Windows host and enable WSL integration for
  your distro — `scripts/linux.sh` detects WSL and skips the engine install
  with a reminder.
- **Rider on Linux**: installed via `snap install rider --classic`. If snap
  isn't available, install via [JetBrains
  Toolbox](https://www.jetbrains.com/toolbox-app/) manually.
- All scripts are idempotent — safe to re-run after editing `manifest.yaml`
  to pick up newly added tools without reinstalling existing ones.

## Adding a tool

Add an entry to `manifest.yaml` with `brew`/`apt`/`winget` install info (or
an `apt.special` marker plus a matching function in `scripts/linux.sh` if it
needs repo/snap setup instead of a plain package). No other script changes
needed for the common case.
