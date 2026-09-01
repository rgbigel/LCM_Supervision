<#
.SYNOPSIS
  Unified task dispatcher and telemetry recorder for Workspace Supervision.

.DESCRIPTION
  Executes specific or all active supervision tasks, captures structured observation metrics,
  updates 'data/supervision_catalog.json', and appends records to 'data/supervision_history.jsonl'.

.EXAMPLE
  pwsh -File tools/Invoke-SupervisionRunner.ps1 -TaskId ble-fleet-stability
  pwsh -File tools/Invoke-SupervisionRunner.ps1 -TaskName BleSupervision
  pwsh -File tools/Invoke-SupervisionRunner.ps1 -All
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string]$TaskId,

  [Parameter(Mandatory = $false)]
  [string]$TaskName,

  [Parameter(Mandatory = $false)]
  [switch]$All,

  [Parameter(Mandatory = $false)]
  [string]$WorkspaceRoot = 'D:\Git_Repositories'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$supervisionRoot = Join-Path $WorkspaceRoot 'Workspace_Supervision'
$catalogFile = Join-Path $supervisionRoot 'data\supervision_catalog.json'
$historyFile = Join-Path $supervisionRoot 'data\supervision_history.jsonl'

if (-not (Test-Path $catalogFile)) {
  throw "Supervision catalog not found at: $catalogFile"
}

$catalogRaw = Get-Content $catalogFile -Raw -Encoding utf8
$catalog = $catalogRaw | ConvertFrom-Json

$tasksToRun = @()
if ($All) {
  $tasksToRun = @($catalog.tasks | Where-Object { $_.status -eq 'Active' })
} elseif ($TaskId) {
  $tasksToRun = @($catalog.tasks | Where-Object { $_.id -eq $TaskId })
} elseif ($TaskName) {
  $tasksToRun = @($catalog.tasks | Where-Object { $_.shortName -eq $TaskName -or $_.id -eq $TaskName })
} else {
  $tasksToRun = @($catalog.tasks | Where-Object { $_.status -eq 'Active' })
}

if ($tasksToRun.Count -eq 0) {
  Write-Warning "No matching active supervision tasks found to execute."
  return
}

$pythonExe = (Get-Command python.exe -ErrorAction SilentlyContinue).Source
if (-not $pythonExe) { $pythonExe = 'D:\Tools\Python314\python.exe' }

$executedResults = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($t in $tasksToRun) {
  Write-Host "⚡ Executing Supervision Task: $($t.shortName) ($($t.id))..." -ForegroundColor Cyan
  $scriptFull = Join-Path $supervisionRoot $t.scriptPath
  if (-not (Test-Path $scriptFull)) {
    Write-Error "Task script not found: $scriptFull"
    continue
  }

  $runnerType = $t.runner.ToLower()
  $argsList = if ($t.args) { @($t.args) } else { @() }
  $outputJson = $null
  $startTs = Get-Date

  try {
    if ($runnerType -eq 'python') {
      $cmdArgs = @($scriptFull) + $argsList
      $rawOut = & $pythonExe $cmdArgs 2>&1 | Out-String
      $cleanJson = $rawOut.Trim()
      $outputJson = $cleanJson | ConvertFrom-Json
    } elseif ($runnerType -eq 'powershell' -or $runnerType -eq 'pwsh') {
      $cmdArr = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptFull) + @($argsList)
      $rawOut = & pwsh $cmdArr 2>&1 | Out-String
      $cleanJson = $rawOut.Trim()
      $outputJson = $cleanJson | ConvertFrom-Json
    } else {
      $rawOut = & cmd.exe /c $scriptFull @argsList 2>&1 | Out-String
      $cleanJson = $rawOut.Trim()
      $outputJson = $cleanJson | ConvertFrom-Json
    }
  } catch {
    Write-Warning "Execution failed for $($t.shortName): $($_.Exception.Message)"
    $outputJson = [PSCustomObject]@{
      taskId          = $t.id
      timestamp       = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
      durationSeconds = [Math]::Round(((Get-Date) - $startTs).TotalSeconds, 3)
      status          = "Failing"
      counts          = [PSCustomObject]@{ errors = 1; warnings = 0; info = 0; total = 1 }
      summary         = "Runner exception: $($_.Exception.Message)"
      details         = @()
    }
  }

  if ($null -ne $outputJson) {
    # Update catalog entry
    $t.lastRun = $outputJson.timestamp
    $t.lastDuration = $outputJson.durationSeconds
    $t.lastStatus = $outputJson.status
    $t.observations.errors = $outputJson.counts.errors
    $t.observations.warnings = $outputJson.counts.warnings
    $t.observations.info = $outputJson.counts.info
    $t.observations.total = $outputJson.counts.total
    
    $nextDt = (Get-Date).AddMinutes($t.intervalMinutes)
    $t.nextRun = $nextDt.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    # Append to history ledger
    $historyEntry = [PSCustomObject]@{
      timestamp       = $outputJson.timestamp
      taskId          = $t.id
      shortName       = $t.shortName
      durationSeconds = $outputJson.durationSeconds
      status          = $outputJson.status
      errors          = $outputJson.counts.errors
      warnings        = $outputJson.counts.warnings
      info            = $outputJson.counts.info
      total           = $outputJson.counts.total
      summary         = $outputJson.summary
    } | ConvertTo-Json -Compress

    [System.IO.File]::AppendAllText($historyFile, "$historyEntry`r`n", [System.Text.UTF8Encoding]::new($false))
    $executedResults.Add($outputJson)

    Write-Host "✓ Completed $($t.shortName): Status=$($outputJson.status), Errors=$($outputJson.counts.errors), Warnings=$($outputJson.counts.warnings), Info=$($outputJson.counts.info) ($($outputJson.durationSeconds)s)" -ForegroundColor Green
  }
}

# Save updated catalog (UTF-8 without BOM)
$catalog.lastUpdated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$newCatalogJson = $catalog | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($catalogFile, $newCatalogJson, [System.Text.UTF8Encoding]::new($false))

Write-Host "Catalog updated at: $catalogFile" -ForegroundColor DarkGray
