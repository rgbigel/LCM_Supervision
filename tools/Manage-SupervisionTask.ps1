<#
.SYNOPSIS
  CM Control Tool for Workspace Supervision Tasks.

.DESCRIPTION
  Provides comprehensive Lifecycle Management (LCM) control over supervision tasks:
  1. Start / Stop / Pause / Resume / RunNow for specific tasks or 'All'.
  2. Add / Delete / Modify task definitions.
  3. Display formatted interactive table of tasks with short/long names, status, and observation metrics.

.PARAMETER Action
  Action to perform: 'Get', 'Start', 'Stop', 'Pause', 'Resume', 'RunNow', 'Add', 'Delete', 'Modify'.

.PARAMETER TaskName
  Target task ShortName or ID, or 'All' for bulk actions.

.PARAMETER IntervalMinutes
  New interval in minutes when modifying a task.

.PARAMETER TaskJson
  JSON payload or file path when adding or modifying a task.

.PARAMETER WorkspaceRoot
  Root directory of the LCM multi-repository workspace.

.PARAMETER Help
  Displays this synopsis and usage screen.

.EXAMPLE
  pwsh -File tools/Manage-SupervisionTask.ps1 -Action Get
  pwsh -File tools/Manage-SupervisionTask.ps1 -Action RunNow -TaskName BleSupervision
  pwsh -File tools/Manage-SupervisionTask.ps1 -Action Pause -TaskName All
  pwsh -File tools/Manage-SupervisionTask.ps1 -Action Resume -TaskName BleSupervision
  pwsh -File tools/Manage-SupervisionTask.ps1 -Action Start -TaskName All
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $false, Position = 0, HelpMessage = 'Action to perform: Get, Show, List, Start, Stop, Pause, Resume, RunNow, Run, Add, Delete, Remove, Modify, Update.')]
  [ValidateSet('Get', 'Show', 'List', 'Start', 'Stop', 'Pause', 'Resume', 'RunNow', 'Run', 'Add', 'Delete', 'Remove', 'Modify', 'Update')]
  [string]$Action = 'Get',

  [Parameter(Mandatory = $false, Position = 1, HelpMessage = 'Target task ShortName or ID, or All for bulk actions.')]
  [string]$TaskName = 'All',

  [Parameter(Mandatory = $false, HelpMessage = 'New interval in minutes when modifying a task.')]
  [int]$IntervalMinutes,

  [Parameter(Mandatory = $false, HelpMessage = 'JSON payload or file path when adding or modifying a task.')]
  [string]$TaskJson,

  [Parameter(Mandatory = $false, HelpMessage = 'Root directory of the LCM multi-repository workspace.')]
  [string]$WorkspaceRoot = 'D:\Git_Repositories',

  [Parameter(Mandatory = $false, HelpMessage = 'Displays this synopsis and usage screen.')]
  [Alias('h', '?')]
  [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptVersion = "1.0.0"
$supervisionRoot = Join-Path $WorkspaceRoot 'LCM_Supervision'
$catalogFile = Join-Path $supervisionRoot 'data\supervision_catalog.json'

if ($Help) {
  Write-Host "==========================================================================" -ForegroundColor Cyan
  Write-Host " WORKSPACE SUPERVISION CM TASK CONTROLLER (v$scriptVersion)" -ForegroundColor Cyan
  Write-Host "==========================================================================" -ForegroundColor Cyan
  Write-Host "Actions:"
  Write-Host "  Get / List     : Show interactive table of registered tasks with observation counters"
  Write-Host "  Start          : Activate task scheduling (TaskName or 'All')"
  Write-Host "  Stop           : Decommission/stop task scheduling (TaskName or 'All')"
  Write-Host "  Pause          : Temporarily suspend task execution (TaskName or 'All')"
  Write-Host "  Resume         : Resume paused task execution (TaskName or 'All')"
  Write-Host "  RunNow / Run   : Execute task cycle immediately and record telemetry"
  Write-Host "  Add            : Register new supervision task from JSON"
  Write-Host "  Delete / Remove: Remove task from supervision catalog"
  Write-Host "  Modify / Update: Update task properties (interval, status, args)"
  Write-Host "`nExamples:"
  Write-Host "  pwsh tools/Manage-SupervisionTask.ps1 -Action Get"
  Write-Host "  pwsh tools/Manage-SupervisionTask.ps1 -Action RunNow -TaskName BleSupervision"
  Write-Host "  pwsh tools/Manage-SupervisionTask.ps1 -Action Pause -TaskName All"
  return
}

if (-not (Test-Path $catalogFile)) {
  throw "Supervision catalog not found at: $catalogFile"
}

function Load-Catalog {
  $raw = Get-Content $catalogFile -Raw -Encoding utf8
  return ($raw | ConvertFrom-Json)
}

function Save-Catalog ($cat) {
  $cat.lastUpdated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  $json = $cat | ConvertTo-Json -Depth 10
  [System.IO.File]::WriteAllText($catalogFile, $json, [System.Text.UTF8Encoding]::new($false))
}

$catalog = Load-Catalog

# Normalize Action Aliases
$act = $Action.ToLower()
if ($act -eq 'show' -or $act -eq 'list') { $act = 'get' }
if ($act -eq 'run') { $act = 'runnow' }
if ($act -eq 'remove') { $act = 'delete' }
if ($act -eq 'update') { $act = 'modify' }

switch ($act) {
  'get' {
    Write-Host "========================================================================================================" -ForegroundColor Cyan
    Write-Host " WORKSPACE SUPERVISION TASK FLEET REGISTRY & OBSERVATION TELEMETRY" -ForegroundColor Cyan
    Write-Host "========================================================================================================" -ForegroundColor Cyan
    
    $rows = foreach ($t in $catalog.tasks) {
      $statusIcon = switch ($t.status) {
        'Active'  { '🟢 Active ' }
        'Paused'  { '🟡 Paused ' }
        'Stopped' { '⚪ Stopped' }
        'Failing' { '🔴 Failing' }
        default   { '🔵 ' + $t.status }
      }

      [PSCustomObject]@{
        'Short Name'   = $t.shortName
        'Status'       = $statusIcon
        'Domain'       = $t.domain
        'Interval'     = "$($t.intervalMinutes)m"
        'Errors (🔴)'  = $t.observations.errors
        'Warns (🟡)'   = $t.observations.warnings
        'Info (🔵)'    = $t.observations.info
        'Total Obs'    = $t.observations.total
        'Last Status'  = $t.lastStatus
        'Last Run'     = if ($t.lastRun) { ($t.lastRun -replace 'T', ' ' -replace 'Z', '') } else { 'Never' }
        'Long Name'    = $t.longName
      }
    }

    $rows | Format-Table -AutoSize
    
    $totalActive = @($catalog.tasks | Where-Object { $_.status -eq 'Active' }).Count
    $totalPaused = @($catalog.tasks | Where-Object { $_.status -eq 'Paused' }).Count
    $totalErrors = ($catalog.tasks | Measure-Object -Property { $_.observations.errors } -Sum).Sum
    $totalWarns = ($catalog.tasks | Measure-Object -Property { $_.observations.warnings } -Sum).Sum
    $totalObs = ($catalog.tasks | Measure-Object -Property { $_.observations.total } -Sum).Sum

    Write-Host "Summary: $($catalog.tasks.Count) Total Tasks | $totalActive Active | $totalPaused Paused | $totalErrors Total Errors | $totalWarns Total Warnings | $totalObs Total Observations`n" -ForegroundColor DarkGray
  }

  'start' {
    $target = $TaskName.Trim()
    $count = 0
    foreach ($t in $catalog.tasks) {
      if ($target -eq 'All' -or $t.shortName -eq $target -or $t.id -eq $target) {
        $t.status = 'Active'
        $count++
        Write-Host "✓ Started task: $($t.shortName) (Status: Active)" -ForegroundColor Green
      }
    }
    if ($count -gt 0) { Save-Catalog $catalog } else { Write-Warning "No matching tasks found for: $target" }
  }

  'stop' {
    $target = $TaskName.Trim()
    $count = 0
    foreach ($t in $catalog.tasks) {
      if ($target -eq 'All' -or $t.shortName -eq $target -or $t.id -eq $target) {
        $t.status = 'Stopped'
        $count++
        Write-Host "⏹ Stopped task: $($t.shortName) (Status: Stopped)" -ForegroundColor Yellow
      }
    }
    if ($count -gt 0) { Save-Catalog $catalog } else { Write-Warning "No matching tasks found for: $target" }
  }

  'pause' {
    $target = $TaskName.Trim()
    $count = 0
    foreach ($t in $catalog.tasks) {
      if ($target -eq 'All' -or $t.shortName -eq $target -or $t.id -eq $target) {
        $t.status = 'Paused'
        $count++
        Write-Host "⏸ Paused task: $($t.shortName) (Status: Paused)" -ForegroundColor Yellow
      }
    }
    if ($count -gt 0) { Save-Catalog $catalog } else { Write-Warning "No matching tasks found for: $target" }
  }

  'resume' {
    $target = $TaskName.Trim()
    $count = 0
    foreach ($t in $catalog.tasks) {
      if ($target -eq 'All' -or $t.shortName -eq $target -or $t.id -eq $target) {
        $t.status = 'Active'
        $count++
        Write-Host "▶ Resumed task: $($t.shortName) (Status: Active)" -ForegroundColor Green
      }
    }
    if ($count -gt 0) { Save-Catalog $catalog } else { Write-Warning "No matching tasks found for: $target" }
  }

  'runnow' {
    $runnerScript = Join-Path $supervisionRoot 'tools\Invoke-SupervisionRunner.ps1'
    if ($TaskName -eq 'All') {
      & pwsh -NoProfile -ExecutionPolicy Bypass -File $runnerScript -All -WorkspaceRoot $WorkspaceRoot
    } else {
      & pwsh -NoProfile -ExecutionPolicy Bypass -File $runnerScript -TaskName $TaskName -WorkspaceRoot $WorkspaceRoot
    }
  }

  'add' {
    if (-not $TaskJson) {
      throw "Adding a task requires -TaskJson parameter containing task manifest."
    }
    $newTask = if (Test-Path $TaskJson) { Get-Content $TaskJson -Raw | ConvertFrom-Json } else { $TaskJson | ConvertFrom-Json }
    
    if (-not $newTask.id -or -not $newTask.shortName -or -not $newTask.scriptPath) {
      throw "Invalid task definition. Required properties: id, shortName, scriptPath."
    }

    # Ensure observations structure exists
    if (-not $newTask.observations) {
      $newTask | Add-Member -NotePropertyName observations -NotePropertyValue ([PSCustomObject]@{ errors = 0; warnings = 0; info = 0; total = 0 })
    }
    if (-not $newTask.status) {
      $newTask | Add-Member -NotePropertyName status -NotePropertyValue 'Active'
    }

    $existingIdx = -1
    for ($i = 0; $i -lt $catalog.tasks.Count; $i++) {
      if ($catalog.tasks[$i].id -eq $newTask.id) { $existingIdx = $i; break }
    }

    if ($existingIdx -ge 0) {
      $catalog.tasks[$existingIdx] = $newTask
      Write-Host "✓ Updated existing task: $($newTask.shortName)" -ForegroundColor Green
    } else {
      $catalog.tasks += $newTask
      Write-Host "✓ Registered new supervision task: $($newTask.shortName)" -ForegroundColor Green
    }
    Save-Catalog $catalog
  }

  'delete' {
    $target = $TaskName.Trim()
    if ($target -eq 'All') {
      throw "Deleting 'All' tasks at once is prohibited."
    }
    $initialCount = $catalog.tasks.Count
    $catalog.tasks = @($catalog.tasks | Where-Object { $_.shortName -ne $target -and $_.id -ne $target })
    if ($catalog.tasks.Count -lt $initialCount) {
      Save-Catalog $catalog
      Write-Host "🗑 Deleted supervision task: $target" -ForegroundColor Green
    } else {
      Write-Warning "Task not found: $target"
    }
  }

  'modify' {
    $target = $TaskName.Trim()
    $count = 0
    foreach ($t in $catalog.tasks) {
      if ($t.shortName -eq $target -or $t.id -eq $target) {
        if ($IntervalMinutes -gt 0) {
          $t.intervalMinutes = $IntervalMinutes
          Write-Host "✓ Updated interval for $($t.shortName): $($IntervalMinutes)m" -ForegroundColor Green
        }
        $count++
      }
    }
    if ($count -gt 0) { Save-Catalog $catalog } else { Write-Warning "Task not found: $target" }
  }
}
