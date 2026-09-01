# ---------------------------------------------------------------------------
# Stop tracking _site so Quarto Pub publishes only current output.
#
# Why: _site/ is committed to this repo and never cleaned. 36.6 MB of the
# 61.9 MB in there is stale output no longer produced by a render (old
# presentations/, duplicate images, an about.html from 2023). The whole folder
# is re-uploaded on every publish, and Quarto Pub rejects the deploy with
# "413 Payload Too Large". A clean render is ~26 MB.
#
# This script does NOT push. It stops after committing so you can review.
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

Write-Host ""
Write-Host "Repo: $PSScriptRoot" -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath ".git")) {
    Write-Host "This folder is not a git repository. Nothing done." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

# --- 1. Move _site out of the repo (not deleted: it holds a few files that
#        exist nowhere else locally, e.g. publications/ PDFs and two images) ---
if (Test-Path -LiteralPath "_site") {
    $stamp  = Get-Date -Format "yyyy-MM-dd_HHmm"
    $backup = Join-Path (Split-Path -Parent $PSScriptRoot) "Website__site_backup_$stamp"
    Write-Host ""
    Write-Host "Moving _site out of the repo to:" -ForegroundColor Yellow
    Write-Host "  $backup"
    Move-Item -LiteralPath "_site" -Destination $backup
    Write-Host "Done. Delete that folder yourself once you're happy." -ForegroundColor Green
} else {
    Write-Host "No _site folder present, skipping move." -ForegroundColor DarkGray
}

# --- 2. Stop tracking it in git ---
Write-Host ""
Write-Host "Removing _site from git tracking..." -ForegroundColor Yellow
git rm -r --cached --quiet -- _site
git add -- .gitignore

# --- 3. Commit just those two things ---
Write-Host ""
Write-Host "Staged for commit:" -ForegroundColor Cyan
git status --short -- .gitignore _site | Select-Object -First 12
$staged = (git diff --cached --name-only | Measure-Object -Line).Lines
Write-Host "  ... $staged path(s) total"

git commit -m "Stop tracking _site; drop stale build output causing Quarto Pub 413"

# --- 4. Report, do not push ---
Write-Host ""
Write-Host "Committed. NOT pushed." -ForegroundColor Green
Write-Host ""
Write-Host "Your branch vs origin:" -ForegroundColor Cyan
git log --oneline origin/main..HEAD
Write-Host ""
Write-Host "Review the commits above. If they are all ones you want online, run:" -ForegroundColor Yellow
Write-Host "    git push"
Write-Host ""
Write-Host "Then re-render locally with:  quarto render" -ForegroundColor DarkGray
Write-Host ""
Read-Host "Press Enter to close"
