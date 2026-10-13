# LCM_Supervision

Generalized Fleet Stability, Hardware Invariants, and Subsystem Health Supervision Hub for the Lifecycle Model (LCM) architecture.

---

## 1. Overview & Purpose
`LCM_Supervision` provides an extensible, multi-task supervisory framework to orchestrate, execute, audit, and visualize long-running and periodic diagnostic supervision tasks across the entire workspace infrastructure.

### Core Capabilities:
1. **Multi-Task Registry**: Standardized JSON manifests (`data/supervision_catalog.json`) supporting Python, PowerShell, and Batch runners.
2. **Unified CM Lifecycle Control**: Start, Stop, Pause, Resume, and Execute (`RunNow`) tasks individually or in bulk via [`Manage-SupervisionTask.ps1`](tools/Manage-SupervisionTask.ps1).
3. **Resilient Scheduling**: Dual-layer execution combining OS-level Windows Scheduled Tasks (power-down and sleep resilient) with IDE-level standing daemon crons.
4. **Universal Interactive Supervision Hub**: Browser-based single-page application rendered by the supervision launcher, featuring sorting, negation search (`!term`), metric cards, batch actions, and observation counters.

---

## 2. Quick Start

### Launch Interactive Supervision Hub:
```powershell
pwsh -File tools/Show-Supervision.ps1
```

### Manage Tasks via CLI:
```powershell
# List all registered supervision tasks and status
pwsh -File tools/Manage-SupervisionTask.ps1 -Action Get

# Run a specific task immediately
pwsh -File tools/Manage-SupervisionTask.ps1 -Action RunNow -TaskName BleSupervision

# Pause / Resume a task
pwsh -File tools/Manage-SupervisionTask.ps1 -Action Pause -TaskName BleSupervision
pwsh -File tools/Manage-SupervisionTask.ps1 -Action Resume -TaskName BleSupervision

# Pause or Start ALL tasks
pwsh -File tools/Manage-SupervisionTask.ps1 -Action Pause -TaskName All
pwsh -File tools/Manage-SupervisionTask.ps1 -Action Start -TaskName All
```

---

## 3. Directory Structure
```
LCM_Supervision/
├── docs/
│   ├── Architecture.md           # Supervisory model & lifecycle states
│   ├── Requirements.md           # Functional & non-functional requirements
│   ├── Implementation.md         # Technical design & API reference
│   └── SUPERVISION_HUB.html      # Interactive table dashboard
├── tools/
│   ├── Manage-SupervisionTask.ps1 # CM task controller (Start/Stop/Pause/Add/Modify)
│   ├── Invoke-SupervisionRunner.ps1 # Unified task dispatcher
│   └── Show-Supervision.ps1      # Browser UI launcher
├── tasks/
│   ├── bluetooth/
│   │   ├── BleSupervisionTask.py # 51-entity BLE fleet monitor
│   │   └── BleSupervisionTask.json # Task definition
│   └── system/
│       └── MouseFlickerSupervision.ps1 # System hardware invariants monitor
├── data/
│   ├── supervision_catalog.json  # Authoritative task catalog & status
│   └── supervision_history.jsonl # Append-only telemetry observations
└── tests/
    └── SupervisionEngine.Tests.ps1 # Pester v5 test suite
```

## 4. Specifications

- [Architecture](docs/Architecture.md)
- [Requirements](docs/Requirements.md)
- [Implementation](docs/Implementation.md)
