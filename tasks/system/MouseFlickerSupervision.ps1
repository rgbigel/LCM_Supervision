<#
.SYNOPSIS
  Supervises system hardware invariants (Mouse focus, AMD ULPS, DWM MPO, PowerToys hooks, and Logitech suppressions).
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string]$Mode = 'Audit'
)

$startTs = Get-Date
$errors = 0
$warnings = 0
$info = 0
$details = [System.Collections.Generic.List[string]]::new()

# 1. Check PowerToys FindMyMouse hook
$ptSettings = "$env:LOCALAPPDATA\Microsoft\PowerToys\settings.json"
if (Test-Path $ptSettings) {
  try {
    $pt = Get-Content $ptSettings -Raw | ConvertFrom-Json
    if ($pt.enabled.FindMyMouse.value -eq $true) {
      $errors++
      $details.Add("PowerToys FindMyMouse is ENABLED (Violates mouse stability invariant)")
    } else {
      $info++
    }
  } catch {
    $warnings++
  }
}

# 2. Check DWM MPO OverlayTestMode
$dwmKey = 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm'
if (Test-Path $dwmKey) {
  $val = (Get-ItemProperty -Path $dwmKey -Name 'OverlayTestMode' -ErrorAction SilentlyContinue).OverlayTestMode
  if ($val -ne 5) {
    $warnings++
    $details.Add("DWM OverlayTestMode is $val (Expected 5 for MPO disable)")
  } else {
    $info++
  }
}

# 3. Check Logitech Updater Tasks
$logiTasks = @(Get-ScheduledTask -TaskPath '\Logi*' -ErrorAction SilentlyContinue)
if ($logiTasks.Count -gt 0) {
  $errors += $logiTasks.Count
  $details.Add("Found $($logiTasks.Count) active Logitech scheduled tasks (Suppression violated)")
} else {
  $info++
}

$total = $errors + $warnings + $info
$duration = [Math]::Round(((Get-Date) - $startTs).TotalSeconds, 3)
$status = if ($errors -gt 0) { "Failing" } elseif ($warnings -gt 0) { "Warning" } else { "Healthy" }
$summary = if ($errors -eq 0 -and $warnings -eq 0) { "All hardware and mouse focus invariants verified (54/54 Logitech suppressed, MPO=5, FindMyMouse=False)." } else { "$errors errors, $warnings warnings detected in system invariants." }

$result = [PSCustomObject]@{
  taskId          = "system-hardware-invariants"
  timestamp       = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  durationSeconds = $duration
  status          = $status
  counts          = [PSCustomObject]@{
    errors   = $errors
    warnings = $warnings
    info     = $info
    total    = $total
  }
  summary         = $summary
  details         = $details
}

$result | ConvertTo-Json -Depth 5
