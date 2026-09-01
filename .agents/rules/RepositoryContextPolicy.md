---
name: RepositoryContextPolicy
description: Authoritative rule for automatic repository context detection, fast-tier ingestion, candidate fallback, and zero-redundant scan governance.
globs: "*"
---
# File: RepositoryContextPolicy.md

Module: RepositoryContextPolicy  
Purpose: Defines automatic active-document repository detection, fast-tier context priming, candidate fallback, and scan optimization invariants.  
Path: .agents/rules/RepositoryContextPolicy.md  
Authors: Rolf, Workspace_AI  
Version: 7.0.0  
Status: Authoritative Invariant Rule  
Date: 2026-08-29  

---

## 1. Context Ingestion Invariants

### `RULE-CTX-001` (Active Repository Scope Resolution)
At the start of every interaction or when switching focus, the agent `MUST` automatically identify the target repository from:
1. The currently active document / cursor file path in the IDE metadata.
2. Explicitly referenced repository paths in the user request.
3. If working at workspace root (`D:\Git_Repositories\`), the global context in [.agents/ACTIVE_CONTEXT.md](file:///d:/Git_Repositories/.agents/ACTIVE_CONTEXT.md) defines baseline scope.

### `RULE-CTX-002` (Fast-Tier Repository Context Priming)
When active work begins on a specific repository (e.g. `VolumeInventory`, `BootEntryManager`, `HaSSD06`, `BackgroundModifier`), the agent `MUST` prime its working context in a single targeted tier by reading:
1. `<TargetRepo>/.lcm/config.json` (for elevation requirements, governance version, and repository classification).
2. `<TargetRepo>/README.md` (for module purpose, exported functions/atoms, and prerequisites).
3. Any open Change Requests / proposals in `<TargetRepo>/docs/Proposals/` (or active task files).

> [!NOTE]
> **Unonboarded Candidate Fallback:**  
> If `.lcm/config.json` is missing from an inspected target directory, the agent `SHALL` classify the repository as an `unonboarded-candidate` and reference the LCM onboarding workflow (`Invoke-LCMOnboardRepo.ps1`) rather than failing or running broad recursive scans.

### `RULE-CTX-003` (Zero Redundant Scan Invariant)
The agent `MUST NOT` run multi-step recursive discovery scans (`list_dir`, broad grep) across the entire workspace when operating within the scope of an identified repository.

### `RULE-CTX-004` (Methodology Awareness)
The agent `MUST` remain aware of the global LCM triad at all times:
* **`Workspace_AI`**: Governs release baselines (v4.3.0), templates, and quality gates.
* **`Workspace_Inventory`**: Configuration Management engine, audit ledger, and cross-repo CR indexing.
* **`SharedModules`**: Reusable functional PowerShell atom library (`Logging`, `VolumeAtoms`, `BcdAtoms`).

