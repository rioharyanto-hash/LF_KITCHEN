# Install Git Hooks for LF Kitchen
# Run this script to set up pre-commit hooks
#
# Usage: .\scripts\install-hooks.ps1

Write-Host "Installing Git hooks for LF Kitchen..." -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Get the project root directory
$projectRoot = Split-Path -Parent $PSScriptRoot
$hooksDir = Join-Path $projectRoot ".git\hooks"
$sourceHook = Join-Path $projectRoot "scripts\pre-commit"
$targetHook = Join-Path $hooksDir "pre-commit"

# Check if .git directory exists
if (-not (Test-Path (Join-Path $projectRoot ".git"))) {
    Write-Host "❌ Error: .git directory not found. Are you in a git repository?" -ForegroundColor Red
    exit 1
}

# Create hooks directory if it doesn't exist
if (-not (Test-Path $hooksDir)) {
    New-Item -ItemType Directory -Path $hooksDir | Out-Null
}

# Copy the pre-commit hook
Copy-Item -Path $sourceHook -Destination $targetHook -Force

Write-Host ""
Write-Host "✅ Pre-commit hook installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "The hook will run 'flutter analyze' before each commit." -ForegroundColor Yellow
Write-Host "If there are any issues, the commit will be blocked." -ForegroundColor Yellow
Write-Host ""
Write-Host "To bypass the hook (not recommended):" -ForegroundColor Gray
Write-Host "  git commit --no-verify -m 'your message'" -ForegroundColor Gray
Write-Host ""
