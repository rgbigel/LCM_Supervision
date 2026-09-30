<#
.SYNOPSIS
  Launches the Workspace Supervision Hub dashboard on your interactive desktop.

.DESCRIPTION
  Renders and synchronizes real-time supervision telemetry, observation history,
  and fleet task definitions, then opens the interactive Supervision Hub single-page
  application in your default browser.

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

$scriptVersion = "1.1.1"
$supervisionRoot = Split-Path $PSScriptRoot -Parent
$catalogFile = Join-Path $supervisionRoot 'data\supervision_catalog.json'
$historyFile = Join-Path $supervisionRoot 'data\supervision_history.jsonl'
$templateFile = Join-Path $supervisionRoot 'assets\SUPERVISION_HUB.html'
if (-not (Test-Path -LiteralPath $templateFile)) {
  $templateFile = Join-Path $supervisionRoot 'docs\SUPERVISION_HUB.html'
}

$artifactsDir = Join-Path $supervisionRoot 'data\artifacts'
if (-not (Test-Path -LiteralPath $artifactsDir)) {
  New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
}
$scratchDir = Join-Path $supervisionRoot 'scratch'
if (-not (Test-Path -LiteralPath $scratchDir)) {
  New-Item -ItemType Directory -Path $scratchDir -Force | Out-Null
}
$htmlFile = Join-Path $artifactsDir 'SUPERVISION_HUB.html'

if ($Help) {
  Write-Host "==========================================================================" -ForegroundColor Cyan
  Write-Host " WORKSPACE SUPERVISION HUB DASHBOARD LAUNCHER (v$scriptVersion)" -ForegroundColor Cyan
  Write-Host "==========================================================================" -ForegroundColor Cyan
  Write-Host "Usage: pwsh tools/Show-SupervisionHub.ps1 [-NoLaunch] [-Help]"
  return
}

if (-not (Test-Path -LiteralPath $catalogFile)) {
  throw "Supervision catalog file missing at: $catalogFile"
}

if (-not (Test-Path -LiteralPath $templateFile)) {
  throw "Supervision HTML dashboard template missing at: $templateFile"
}

# Read live catalog data
$catalogRaw = Get-Content -LiteralPath $catalogFile -Raw -Encoding utf8

# Read live observations history
$historyItems = @()
if (Test-Path -LiteralPath $historyFile) {
  $lines = Get-Content -LiteralPath $historyFile -Encoding utf8
  foreach ($l in $lines) {
    if (-not [string]::IsNullOrWhiteSpace($l)) {
      try {
        $item = $l | ConvertFrom-Json
        $historyItems += $item
      } catch {}
    }
  }
}
$historyRaw = ($historyItems | ConvertTo-Json -Depth 6 -Compress)

# Inject updated catalog & history data into HTML template
$htmlContent = Get-Content -LiteralPath $templateFile -Raw -Encoding utf8

$injectedCatalog = "let catalogData = $catalogRaw;"
$injectedHistory = "let observationHistoryData = $historyRaw;"

$htmlContent = $htmlContent -replace 'let catalogData = \{[\s\S]*?\};', $injectedCatalog
$htmlContent = $htmlContent -replace 'let observationHistoryData = \[[\s\S]*?\];', $injectedHistory

[System.IO.File]::WriteAllText($htmlFile, $htmlContent, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $scratchDir 'SUPERVISION_HUB.html'), $htmlContent, [System.Text.UTF8Encoding]::new($false))

Write-Host "✓ Synchronized Supervision Hub cache & observations: $htmlFile" -ForegroundColor Green

if (-not $NoLaunch) {
  Write-Host "🚀 Launching Workspace Supervision Hub on interactive desktop..." -ForegroundColor Cyan
  Start-Process $htmlFile
}
