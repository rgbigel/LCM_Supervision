# Pester v5 Test Suite: Workspace_Supervision Engine
BeforeAll {
  $supervisionRoot = Split-Path $PSScriptRoot -Parent
  $catalogFile = Join-Path $supervisionRoot 'data\supervision_catalog.json'
  $manageScript = Join-Path $supervisionRoot 'tools\Manage-SupervisionTask.ps1'
  $runnerScript = Join-Path $supervisionRoot 'tools\Invoke-SupervisionRunner.ps1'
}

Describe 'Workspace Supervision Engine Tests' {

  Context 'Supervision Catalog Data Integrity' {
    It 'Should have a valid catalog file in data/' {
      Test-Path $catalogFile | Should -BeTrue
    }

    It 'Should parse catalog JSON cleanly and contain tasks' {
      $json = Get-Content $catalogFile -Raw -Encoding utf8 | ConvertFrom-Json
      $json.tasks.Count | Should -BeGreaterThan 0
    }

    It 'Should contain required schema properties for every task' {
      $json = Get-Content $catalogFile -Raw -Encoding utf8 | ConvertFrom-Json
      foreach ($t in $json.tasks) {
        $t.id | Should -Not -BeNullOrEmpty
        $t.shortName | Should -Not -BeNullOrEmpty
        $t.domain | Should -Not -BeNullOrEmpty
        $t.status | Should -Not -BeNullOrEmpty
        $t.runner | Should -Not -BeNullOrEmpty
        $t.scriptPath | Should -Not -BeNullOrEmpty
        $t.observations | Should -Not -BeNullOrEmpty
      }
    }
  }

  Context 'CM Task Controller Lifecycle Operations' {
    It 'Should output task list on Action Get without errors' {
      { & pwsh -NoProfile -ExecutionPolicy Bypass -File $manageScript -Action Get } | Should -Not -Throw
    }

    It 'Should toggle task status to Paused and back to Active' {
      & pwsh -NoProfile -ExecutionPolicy Bypass -File $manageScript -Action Pause -TaskName BleSupervision
      $json = Get-Content $catalogFile -Raw -Encoding utf8 | ConvertFrom-Json
      $ble = $json.tasks | Where-Object { $_.shortName -eq 'BleSupervision' }
      $ble.status | Should -Be 'Paused'

      & pwsh -NoProfile -ExecutionPolicy Bypass -File $manageScript -Action Resume -TaskName BleSupervision
      $json2 = Get-Content $catalogFile -Raw -Encoding utf8 | ConvertFrom-Json
      $ble2 = $json2.tasks | Where-Object { $_.shortName -eq 'BleSupervision' }
      $ble2.status | Should -Be 'Active'
    }
  }

  Context 'Task Dispatcher & Observation Logging' {
    It 'Should execute BleSupervision task and record observations' {
      { & pwsh -NoProfile -ExecutionPolicy Bypass -File $runnerScript -TaskName BleSupervision } | Should -Not -Throw
      $json = Get-Content $catalogFile -Raw -Encoding utf8 | ConvertFrom-Json
      $ble = $json.tasks | Where-Object { $_.shortName -eq 'BleSupervision' }
      $ble.lastRun | Should -Not -BeNullOrEmpty
      $ble.observations.total | Should -BeGreaterThan 0
    }
  }
}
