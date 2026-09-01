---
name: SubsystemGovernancePolicy
description: Authoritative governance policy for Disjunct Subsystems, Domain-Specific Inventories, JIT Ephemeral Authentication, and Host Safety Interlocks.
globs: "*"
---
# File: SubsystemGovernancePolicy.md

Module: SubsystemGovernancePolicy  
Purpose: Governs disjunct Subsystem repositories (e.g. Home Assistant OS), dedicated subsystem inventories, JIT ephemeral write authentication, host hardware interlocks, and log segregation.  
Path: .agents/rules/SubsystemGovernancePolicy.md  
Authors: Rolf, Workspace_AI Governance  
Version: 7.0.0  
Status: Authoritative Policy  
Date: 2026-08-29  

---

## 1. Scope & Motivation

A **Subsystem** represents an autonomous runtime domain (e.g., `HaSSD06` running Home Assistant OS) that is disjunct from the host PC's multi-boot Windows environment. 

While Subsystems inherit standard LCM **documentation and quality gate rules**, their internal parts (integrations, devices, entities, add-ons) require domain-specific configuration management and elevated safety protocols.

---

## 2. Invariant Rules

### RULE-SUB-001: Subsystem Classification & Documentation Conformance
1. A repository classified as `subsystem` in `.lcm/config.json` `MUST` fully implement standard LCM **Tripartite Documentation** (`docs/Architecture.md`, `docs/Requirements.md`, `docs/Implementation.md`) and the universal runbook (`install/Installation.md`).
2. The root `Workspace_Inventory` tracks Subsystems at the macro Git level, while delegating internal part tracking to the Subsystem's dedicated inventory engine.

### RULE-SUB-002: Dedicated Subsystem Inventory Engine & Auto-Acceptance Invariant
1. Subsystems `MUST` maintain an independent internal inventory ledger at `data/subsystem_inventory.json` and a rendered summary at `docs/SUBSYSTEM_DASHBOARD.md`.
2. Dedicated audit tools (`tools/Update-<Subsystem>Inventory.ps1`) `SHALL` query domain-specific APIs or MCP services to reconcile active components without polluting the root host inventory.
3. **Direct Carry-Over from LCM (`RULE-EFF-001`)**: Routine Subsystem telemetry collection, entity dumps, and dashboard rendering constitute mechanical evidence and are **automatically accepted**. Telemetry synchronization runs `SHALL NOT` force manual review gates or block workflows on interactive diff sessions.

### RULE-SUB-003: Host-Side Hardware Safety Interlocks (Offline / Pre-Boot)
1. Any host script performing physical disk operations (flashing images, disk cloning, partition restructuring) `MUST NEVER` target arbitrary disk indices (e.g., `Disk 2`) without validating explicit **Hardware Serial Numbers** and **Model Descriptors** declared in `.lcm/config.json`.
2. Host tools `MUST` execute `Assert-DiskTargetSafety` to guarantee that active Windows `Boot`, `System`, or `PageFile` volumes are **never** targeted.
3. Destructive disk operations require high-integrity Administrator elevation and explicit operator confirmation.

### RULE-SUB-004: Safe Write Protocol & Just-In-Time (JIT) Ephemeral Authentication
1. **Dual-User Separation**: Subsystems `MUST` establish distinct service accounts:
   - **Auditor (Read-Only)**: Uses static credentials stored in git-ignored `.lcm/secrets.json` strictly for non-modifying telemetry and inventory queries.
   - **Operator (Write / Privileged)**: Authenticated strictly on-demand via **Just-In-Time (JIT) Ephemeral Sessions**.
2. **Zero Disk / Zero Log Persistence for Privileged Credentials**:
   - Write-mode passwords and tokens `MUST NOT` be stored in `.lcm/secrets.json`, configuration files, or logs.
   - Ephemeral session tokens generated from JIT authentication `SHALL` reside strictly in volatile memory (RAM) for the duration of the mutation batch (default 15–30 minutes) and be purged immediately upon completion.
3. **5-Stage Safe Mutation Pipeline**:
   - All state modifications `MUST` execute through the 5-stage pipeline: `(1) Pre-Flight State Snapshot` $\rightarrow$ `(2) Beyond Compare Visual Payload Gate` $\rightarrow$ `(3) Atomic API Dispatch` $\rightarrow$ `(4) Tiered Polling Health & Liveness Loop (up to 10m for Add-ons, up to 20m for Core, up to 30–45m for Host OS reboots / schema migrations)` $\rightarrow$ `(5) Automated Rollback on Failure`.

### RULE-SUB-005: Strict Log & Evidence Segregation
1. Host-level CM activities (`Workspace_Inventory/logs/cm_activity.log`) record only macro repository lifecycle milestones.
2. Granular runtime events, entity modifications, and API traces `MUST` write exclusively to the Subsystem's internal log directory (`<Subsystem>/logs/subsystem_activity.log` and `<Subsystem>/logs/api_traffic.log`).
3. Outgoing and incoming log messages `MUST` pass through automatic regex sanitization to redact any authorization headers, bearer tokens, or password strings.

### RULE-SUB-006: Subsystem External Update-Gate & Breaking-Change Bundling Protocol
1. **Automated Discovery & Breaking-Change Ingestion**:
   - The Subsystem update engine `MUST` scan external updates (Core, OS, Add-ons, Integrations, HACS components, device firmwares) and parse all accompanying release descriptions, explicitly extracting **Breaking Changes**.
   - Each discovered update `SHALL` generate a structured **Change Request Proposal (CRP)** in `data/proposals/`.
2. **Relevance & Risk-Ordered Review**:
   - CRPs `MUST` be prioritized and ordered by operational risk: (1) Breaking Changes & Core/OS $\rightarrow$ (2) Add-ons & Network Services $\rightarrow$ (3) HACS custom components $\rightarrow$ (4) Minor device firmwares.
   - Operators may accept, partially reject, or defer individual CRPs.
3. **Consolidation into Approved Update Bundles**:
   - Accepted CRPs are consolidated into a versioned **Update Bundle** (e.g. `data/bundles/BUNDLE-YYYYMMDD.json`) for semi-automatic execution.
4. **Mandatory Pre-Update Backup & Safety Gate**:
   - Prior to applying any external updates, an atomic full-system snapshot / backup `MUST` be initiated via the Subsystem API.
   - If the pre-update backup fails or times out, the update pipeline `MUST` abort immediately.
5. **Execution Under Security Protocol**:
   - Upon backup verification, the update bundle `SHALL` execute under the JIT visual authentication protocol (`RULE-SUB-004`) followed by the operation-aware Tiered Polling Health Loop (generous multi-minute budgets: up to 10m for Add-ons, 20m for Core, 30–45m for Host OS reboots / large migrations) checking `state == 'RUNNING'` and `safe_mode == false`, with automated rollback on failure.

### RULE-SUB-007: Central Registry Non-Mutation Invariant
1. **Authoritative Internal State**: The Subsystem's internal runtime registries (e.g. Home Assistant OS Device Registry, Entity Registry, Area Registry, and Config Entries stored in `.storage/`) constitute the authoritative internal state of the Subsystem host.
2. **External Write Prohibition**: Tooling, scripts, and MCP agents executing on the host PC `MUST NOT` attempt to mutate, overwrite, clean, or inject records into the Subsystem's internal central registry from the outside (whether via direct `.storage/` file writes or WebSocket mutation endpoints like `config/device_registry/update`).
3. **Observation-Only Protocol**: LCM Configuration Management tools `SHALL` operate strictly as read-only observers and reconcilers. Even if internal registry records contain historical errors, duplicate hardware identifiers, or inconsistent naming, corrections `MUST` be performed exclusively within the official Subsystem UI by the human operator.





