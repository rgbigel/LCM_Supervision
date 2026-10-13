# Implementation Specification: Workspace Supervision Engine

Module: docs/Implementation.md  
Purpose: Code catalog, task controller parameters, runner dispatch logic, and telemetry persistence schemas for LCM_Supervision.  
Path: D:/Git_Repositories/LCM_Supervision/docs/Implementation.md  
Authors: Rolf, LCM_AI Engine  
Version: 10.0.0 (LCM Baseline: 10.0.0)
Status: Authoritative Implementation  
Date: 2026-10-13

---

## 1. Technical Components

### 1. `tools/Manage-SupervisionTask.ps1`
CLI controller supporting actions:
- `-Action Get`: Outputs formatted table of all tasks and their observation counters.
- `-Action Start`: Activates task schedule.
- `-Action Stop`: Disables task schedule.
- `-Action Pause`: Marks task as paused.
- `-Action Resume`: Resumes paused task.
- `-Action RunNow`: Executes task immediately via `Invoke-SupervisionRunner.ps1`.
- `-Action Add`: Adds a new task JSON definition.
- `-Action Delete`: Removes task from catalog.
- `-Action Modify`: Updates properties of an existing task.

### 2. `tools/Invoke-SupervisionRunner.ps1`
Unified runner executing tasks based on runner type:
- `python`: Executes Python script via Python virtualenv or base binary.
- `powershell`: Executes PowerShell script via `pwsh.exe`.
- `batch`: Executes command script via `cmd.exe`.
Parses output JSON, updates `data/supervision_catalog.json` with latest status/counters, and appends raw cycle telemetry to `data/supervision_history.jsonl`.

### 3. `assets/templates/SUPERVISION_HUB_TEMPLATE.html` / `data/artifacts/SUPERVISION_HUB.html`
Single-page application rendered with Vanilla CSS and JS, supporting:
- Multi-column sorting
- Search negation (`!term`)
- Selection checkboxes & batch operations
- Metric summary cards
- Add/Modify modal dialog
- Windows top-right Back button

---

## 2. Telemetry Persistence Schema

### `data/supervision_catalog.json`
Stores the complete state and registry of all tasks.

### `data/supervision_history.jsonl`
Append-only log containing each cycle's execution timestamp, duration, error counts, warning counts, and summary messages.
