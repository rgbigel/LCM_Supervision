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

$scriptVersion = "1.1.0"
$supervisionRoot = Split-Path $PSScriptRoot -Parent
$catalogFile = Join-Path $supervisionRoot 'data\supervision_catalog.json'
$historyFile = Join-Path $supervisionRoot 'data\supervision_history.jsonl'
$htmlFile = Join-Path $supervisionRoot 'docs\SUPERVISION_HUB.html'

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

if (-not (Test-Path -LiteralPath $htmlFile)) {
  throw "Supervision HTML dashboard missing at: $htmlFile"
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

# Inject updated catalog & history data into HTML file
$htmlContent = Get-Content -LiteralPath $htmlFile -Raw -Encoding utf8

$injectedCatalog = "let catalogData = $catalogRaw;"
$injectedHistory = "let observationHistoryData = $historyRaw;"

$htmlContent = $htmlContent -replace 'let catalogData = \{[\s\S]*?\};', $injectedCatalog
$htmlContent = $htmlContent -replace 'let observationHistoryData = \[[\s\S]*?\];', $injectedHistory

[System.IO.File]::WriteAllText($htmlFile, $htmlContent, [System.Text.UTF8Encoding]::new($false))

Write-Host "✓ Synchronized Supervision Hub cache & observations: $htmlFile" -ForegroundColor Green

if (-not $NoLaunch) {
  Write-Host "🚀 Launching Workspace Supervision Hub on interactive desktop..." -ForegroundColor Cyan
  Start-Process $htmlFile
}
