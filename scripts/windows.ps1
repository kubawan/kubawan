# Windows setup: reads manifest.yaml and installs each tool via winget.
# Run from an elevated PowerShell (Run as Administrator).
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Manifest = Join-Path $RepoRoot "manifest.yaml"

function Log($msg)  { Write-Host "==> $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Warning $msg }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Warn "winget not found. Install 'App Installer' from the Microsoft Store, then re-run this script."
    exit 1
}

if (-not (Get-Command yq -ErrorAction SilentlyContinue)) {
    Log "yq not found, installing it (used to read manifest.yaml)"
    winget install --id MikeFarah.yq -e --source winget --accept-package-agreements --accept-source-agreements
    $env:Path += ";$env:LOCALAPPDATA\Microsoft\WinGet\Links"
}

$count = [int](yq '.tools | length' $Manifest)
for ($i = 0; $i -lt $count; $i++) {
    $name = (yq -r ".tools[$i].name" $Manifest)
    $id   = (yq -r ".tools[$i].winget.id" $Manifest)

    if ($id -eq "null" -or [string]::IsNullOrWhiteSpace($id)) {
        Warn "No winget id defined for $name, skipping"
        continue
    }

    $installed = winget list --id $id -e 2>$null | Select-String -SimpleMatch $id
    if ($installed) {
        Log "$name already installed ($id), skipping"
    } else {
        Log "Installing $name (winget $id)"
        winget install --id $id -e --source winget --accept-package-agreements --accept-source-agreements
    }
}

# --- git config ---
$gitName = git config --global user.name
$gitEmail = git config --global user.email

if (-not $gitName) {
    $gitName = Read-Host "Git user.name not set. Enter it now (blank to skip)"
    if ($gitName) { git config --global user.name $gitName }
}
if (-not $gitEmail) {
    $gitEmail = Read-Host "Git user.email not set. Enter it now (blank to skip)"
    if ($gitEmail) { git config --global user.email $gitEmail }
}

$sharedGitconfig = Join-Path $RepoRoot "dotfiles\gitconfig-shared"
git config --global include.path $sharedGitconfig
# Windows-specific override: shared config sets autocrlf=input (mac/linux
# convention); Windows wants CRLF normalized on checkout too.
git config --global core.autocrlf true

# --- SSH key check ---
$sshDir = Join-Path $HOME ".ssh"
if (Test-Path $sshDir) {
    $keys = Get-ChildItem $sshDir -Filter "id_*" -ErrorAction SilentlyContinue
} else {
    $keys = $null
}
if ($keys) {
    Log "SSH key already present in $sshDir, skipping"
} else {
    Warn "No SSH key found in $sshDir."
    Warn "Generate one with: ssh-keygen -t ed25519 -C `"$gitEmail`""
}

# --- VS Code extensions ---
if (Get-Command code -ErrorAction SilentlyContinue) {
    $extensionsFile = Join-Path $RepoRoot "config\vscode\extensions.txt"
    Get-Content $extensionsFile | ForEach-Object {
        $ext = $_.Trim()
        if ($ext -and -not $ext.StartsWith("#")) {
            code --install-extension $ext --force
        }
    }
} else {
    Warn "'code' CLI not on PATH yet (may need a new shell session), skipping extension install"
}

Log "Windows setup complete"
