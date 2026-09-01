<#
.SYNOPSIS
  Launches the Workspace Supervision Hub dashboard on your interactive desktop.

.DESCRIPTION
  Renders and synchronizes real-time supervision telemetry and fleet task definitions,
  then opens the interactive Supervision Hub single-page application in your default browser.

.PARAMETER NoLaunch
  Synchronizes HTML cache without opening browser window.

.PARAMETER Help
  Displays parameter help.

.EXAMPLE
  pwsh -File tools/Show-SupervisionHub.ps1
  pwsh -File tools/Show-SupervisionHub.ps1 -NoLaunch
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [switch]$NoLaunch,

  [Alias('h', '?')]
  [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptVersion = "1.0.0"
$supervisionRoot = Split-Path $PSScriptRoot -Parent
$catalogFile = Join-Path $supervisionRoot 'data\supervision_catalog.json'
$htmlFile = Join-Path $supervisionRoot 'docs\SUPERVISION_HUB.html'

if ($Help) {
  Write-Host "==========================================================================" -ForegroundColor Cyan
  Write-Host " WORKSPACE SUPERVISION HUB DASHBOARD LAUNCHER (v$scriptVersion)" -ForegroundColor Cyan
  Write-Host "==========================================================================" -ForegroundColor Cyan
  Write-Host "Usage: pwsh tools/Show-SupervisionHub.ps1 [-NoLaunch] [-Help]"
  return
}

if (-not (Test-Path $catalogFile)) {
  throw "Supervision catalog file missing at: $catalogFile"
}

if (-not (Test-Path $htmlFile)) {
  throw "Supervision HTML dashboard missing at: $htmlFile"
}

# Read live catalog data
$catalogRaw = Get-Content $catalogFile -Raw -Encoding utf8

# Inject updated catalog data into HTML file
$htmlContent = Get-Content $htmlFile -Raw -Encoding utf8
$injectedPattern = 'let catalogData = \{[\s\S]*?\};'
$replacement = "let catalogData = $catalogRaw;"
$updatedHtml = $htmlContent -replace $injectedPattern, $replacement

[System.IO.File]::WriteAllText($htmlFile, $updatedHtml, [System.Text.UTF8Encoding]::new($false))

Write-Host "✓ Synchronized Supervision Hub cache: $htmlFile" -ForegroundColor Green

if (-not $NoLaunch) {
  Write-Host "🚀 Launching Workspace Supervision Hub on interactive desktop..." -ForegroundColor Cyan
  Start-Process $htmlFile
}
