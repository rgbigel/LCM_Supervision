# Architecture Specification: Workspace Supervision Engine

- **Module**: `Workspace_Supervision`
- **Domain**: `Workspace_Supervision`
- **Authors**: Rolf, Workspace_AI Engine
- **Version**: 1.0.1 (LCM Baseline: 7.3.2)
- **Date**: 2026-09-08
- **LCM Status**: Active

---

## 1. System Architecture

```mermaid
graph TB
    subgraph UI_Layer ["Presentation & Interaction Layer"]
        HUB["Supervision Hub UI<br/>(docs/SUPERVISION_HUB.html)"]
        CLI["CM Controller CLI<br/>(tools/Manage-SupervisionTask.ps1)"]
    end

    subgraph Control_Layer ["Control & Orchestration Layer"]
        MGR["Manage-SupervisionTask.ps1"]
        DISPATCH["Invoke-SupervisionRunner.ps1"]
        CATALOG[("data/supervision_catalog.json<br/>(Registry & State)")]
    end

    subgraph Execution_Layer ["Execution & Task Layer"]
        OS_SCHED["Windows Task Scheduler<br/>(Power-Down Resilient)"]
        IDE_CRON["Antigravity Daemon Cron"]
        
        TASK_BLE["tasks/bluetooth/BleSupervisionTask.py<br/>(51 BLE Entities)"]
        TASK_SYS["tasks/system/MouseFlickerSupervision.ps1<br/>(Invariants Monitor)"]
    end

    subgraph Data_Layer ["Telemetry & Evidence Layer"]
        HIST[("data/supervision_history.jsonl<br/>(Append-Only Ledger)")]
    end

    HUB -->|Actions: Start/Stop/Pause/Run| MGR
    CLI -->|Actions: Start/Stop/Pause/Run| MGR
    MGR <--> CATALOG
    MGR -->|Configure Triggers| OS_SCHED
    MGR -->|Configure Crons| IDE_CRON

    OS_SCHED --> DISPATCH
    IDE_CRON --> DISPATCH
    DISPATCH --> CATALOG
    DISPATCH --> TASK_BLE
    DISPATCH --> TASK_SYS

    TASK_BLE --> HIST
    TASK_SYS --> HIST
    HIST --> HUB
    CATALOG --> HUB
```

---

## 2. Task Lifecycle States

A supervision task moves deterministically through five states:

| State | Badge Color | Description |
| :--- | :--- | :--- |
| **`Active`** | 🟢 Green | Scheduled and executing automatically at its configured interval. |
| **`Paused`** | 🟡 Amber | Temporarily suspended; schedules remain registered but executions are skipped. |
| **`Stopped`** | ⚪ Gray | Fully decommissioned from active scheduling. |
| **`Running`** | 🔵 Blue | Currently in the middle of executing a supervision cycle. |
| **`Failing`** | 🔴 Red | Last cycle encountered unexpected execution errors or critical threshold breaches. |

---

## 3. Standardized Observation Model

Every supervision task produces structured observation telemetry:

```json
{
  "taskId": "ble-fleet-stability",
  "timestamp": "2026-09-01T13:21:58Z",
  "durationSeconds": 2.14,
  "status": "Healthy",
  "counts": {
    "errors": 0,
    "warnings": 0,
    "info": 1,
    "total": 1
  },
  "summary": "Monitored 51 dynamic BLE entities. 0 dropouts, 0 rapid oscillations.",
  "details": []
}
```
