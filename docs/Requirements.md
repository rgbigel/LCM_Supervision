# Requirements Specification: Workspace Supervision Engine

Module: docs/Requirements.md  
Purpose: Normative requirements, task lifecycle states, and telemetry data models for LCM_Supervision.  
Path: D:/Git_Repositories/LCM_Supervision/docs/Requirements.md  
Authors: Rolf, LCM_AI Engine  
Version: 1.1.1 (LCM Baseline: 7.0.0)  
Status: Authoritative Requirements  
Date: 2026-09-19  

---

## 1. Functional Requirements

### FR-01: Lifecycle Control (Start / Stop / Pause / Resume / RunNow)
- **FR-01.1**: The system must allow starting, stopping, pausing, resuming, or executing on-demand any registered supervision task.
- **FR-01.2**: The system must support bulk operations targeting `All` tasks simultaneously.

### FR-02: Task Definition Management (Add / Delete / Modify)
- **FR-02.1**: The system must support registering new supervision tasks via JSON descriptors, CLI parameters, or the browser UI form.
- **FR-02.2**: The system must support modifying task properties (interval, runner, target parameters, enabled status) and deleting obsolete tasks.

### FR-03: Observation Accounting & Telemetry
- **FR-03.1**: Each supervision run must track four standardized observation counters:
  - **`Errors`** (🔴 Failures, disconnects, threshold breaches)
  - **`Warnings`** (🟡 Flapping, jitter, elevated latency)
  - **`Info`** (🔵 Nominal cycles, telemetry captures)
  - **`Total`** (Sum of all observations)
- **FR-03.2**: Results must be appended to an immutable JSON Lines audit log (`data/supervision_history.jsonl`).

### FR-04: Universal Table Display UX
- **FR-04.1**: Multi-column sorting on all fields.
- **FR-04.2**: Global text filter with token negation (`!term`).
- **FR-04.3**: Selection checkboxes with batch action toolbar.
- **FR-04.4**: Summary metric cards.
- **FR-04.5**: Windows top-right `[⬅ Back]` navigation button.
- **FR-04.6**: High-contrast Dark and Light modes.

### FR-05: Baseline Task Integration
- **FR-05.1**: The 51-entity Home Assistant Bluetooth fleet stability supervisor must be integrated as `BleSupervisionTask`.

---

## 2. Non-Functional Requirements
- **NFR-01 (Resilience)**: Scheduled supervision must survive machine reboots, sleep states, and power-downs via Windows Task Scheduler catch-up (`StartWhenAvailable`).
- **NFR-02 (Performance)**: Supervision hub table must render instantly (<100ms) for up to 500 tasks.
- **NFR-03 (Encoding)**: All JSON and Markdown files must be encoded in UTF-8 without BOM with CRLF line endings.
