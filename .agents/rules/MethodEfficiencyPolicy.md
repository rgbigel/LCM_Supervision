# MethodEfficiencyPolicy

Module: MethodEfficiencyPolicy.md  
Purpose: Defines auto-acceptance, zero-test-trigger invariants, and method efficiency rules for generated inventory telemetry and logs.  
Path: .agents/rules/MethodEfficiencyPolicy.md  
Authors: Rolf, Workspace_AI Engine  
Version: 7.1.0  
Status: Authoritative Invariant Rule  
Date: 2026-09-03  

---

## 1. Purpose & Motivation

In the Lifecycle Model (LCM), Configuration Management (CM) audits, baseline snapshots, test execution evidence, and governance logs are generated deterministically and mechanically by approved tooling.

To maximize **Method Efficiency** and eliminate ceremonial overhead, this policy establishes that purely mechanical, tool-produced artifacts must **never block workflows for manual review** and **must never trigger redundant test runs**.

---

## 2. Invariant Rules

### RULE-EFF-001 (Mechanical Artifact Auto-Acceptance)
Changes strictly modifying tool-generated evidence, audit databases, dashboard summaries, and logs are **automatically accepted** without requiring manual review gates. This applies to:
* `Workspace_Inventory/data/inventory.json`
* `Workspace_Inventory/docs/INVENTORY_DASHBOARD.md`
* `Workspace_Inventory/data/baselines/*.json`
* `Workspace_Inventory/logs/*.log`
* `*_Inventory/data/subsystem_inventory.json` (Subsystem Inventories e.g. `HaSSD06_Inventory`)
* `*_Inventory/docs/SUBSYSTEM_DASHBOARD.md`
* `*_Inventory/logs/*.log` and `*_Inventory/data/proposals/*.json`
* `**/out/test_results.json`
* `.copilot/Logs/*.log` and `.agents/logs/*.log`

### RULE-EFF-002 (Zero-Test Cascade Invariant)
Modifications to the mechanical artifacts listed in `RULE-EFF-001` **MUST NEVER** trigger automated test runs, readiness test cascades, or validation cycles. These files are outputs/evidence of prior verification, not executable source code.

### RULE-EFF-003 (Machine-Only Mutation Authority)
Human operators and AI assistants `MUST NOT` hand-edit `inventory.json`, `INVENTORY_DASHBOARD.md`, or baseline snapshots. They must be modified solely by designated CM tools (`Invoke-WorkspaceAudit.ps1`, `New-WorkspaceBaseline.ps1`, `Invoke-LCMUpdate.ps1`).

### RULE-EFF-004 (Agent Direct Execution & RR Review Gating Alignment)
AI pair-programming agents operating under the Lifecycle Model (LCM) `SHALL` execute tool operations, script commands, and file edits directly under `always-proceed` and `allow` policies without introducing interactive chat planning pauses or confirmation prompts. Formal review gating, safety verification, and user acceptance are strictly and exclusively enforced downstream at the Review Request / Beyond Compare (`RR.ps1` / `Invoke-BeyondCompareReview.ps1`) commit stage per `RULE-REV-001`.

### RULE-EFF-005 (Quality Gate Short-Circuiting & Negative-Outcome Prevention)
1. **Short-Circuit on Upstream Failure**: Multi-phase quality gates (`Test-RepoReadiness.ps1`, `Test-WorkspaceReadiness.ps1`) `MUST` execute tiered validations in prerequisite order (`Structure` $\rightarrow$ `Formatting` $\rightarrow$ `GovernanceLinks` $\rightarrow$ `ElevationConsistency` $\rightarrow$ `DocumentationFabric` $\rightarrow$ `PesterSuite`). If any structural tier fails, execution `MUST` abort immediately with a diagnostic message without executing downstream test suites.
2. **Zero Negative-Outcome Execution**: Agents and runners `MUST NEVER` dispatch tests or commands whose operational prerequisites (e.g. elevation, required modules, linked junctions) are known to be absent.

### RULE-EFF-006 (Agent Direct Execution Alignment — Reserved)
Reserved for future use. See RULE-EFF-004 for current agent execution policy.

---

### RULE-EFF-007: Mandatory Search Dispatch Standard
- **Direct execution of `es.exe` is strictly prohibited** due to IPC authorization constraints when running from non-interactive or Session 0 contexts.
- All high-speed file searches **must** be dispatched via `Search-Everything.ps1` (`.lcm/tools/internal/Search-Everything.ps1`) or directly against the Everything 1.5a HTTP REST API (port 8080).
- CLI text searches inside file contents **must** use `rg.exe` (installed machine-wide in `D:\Tools\rg\`).

---

### RULE-EFF-008: Canonical Tool Discovery Standard
- Agents inspecting, modifying, or querying workspace tools or platform commands **must** query `.lcm/tools/internal/tool_catalog.json` first as the **authoritative single source of truth** before any filesystem traversal.
- Agents are **strictly prohibited** from executing broad, unindexed grep searches across `.psm1`, `.ps1`, or `.cmd` files to locate tool signatures or parameters when `tool_catalog.json` can satisfy the query.

---

### RULE-ENV-003: Zero Speculative Relative Pathing
- Speculative dot-traversal paths (such as `.\..lcm`, `..\..\`, or any path containing `..` without explicit validation) are **prohibited** in tool invocations and script references.
- Tool and script invocations **must** anchor strictly to one of:
  1. `$PSScriptRoot` for same-repository references.
  2. Registered trampolines in `.lcm/Cmd/` for cross-repository dispatch.
  3. An explicit `Resolve-Path` / `Test-Path` pre-flight check before any path is consumed.

---

## 3. Enforcement & Governance Integration

- **Readiness Runners**: `Test-RepoReadiness.ps1` and `Test-WorkspaceReadiness.ps1` treat changes in log directories and `out/` as non-invalidating evidence and enforce short-circuiting on failure.
- **Git Commit Workflow**: Automated audit syncs and baseline captures may be committed and pushed directly as `chore(audit)` or `chore(telemetry)` without entering formal Change Request review loops.
- **Agent Execution Policy**: Agents must operate in direct execution mode; interactive approval loops in chat UI are superseded by the RR pipeline.
- **Search Enforcement (RULE-EFF-007)**: All agents and tooling must route file-system searches through `Search-Everything.ps1` or the Everything HTTP API; `rg.exe` is the mandatory content-search tool.
- **Tool Discovery Enforcement (RULE-EFF-008)**: `tool_catalog.json` is the first-query target for all tool and command discovery; broad unindexed filesystem scans are prohibited.
- **Path Safety Enforcement (RULE-ENV-003)**: All path constructions must be grounded via `$PSScriptRoot`, registered trampolines, or explicit pre-flight resolution; speculative traversal is prohibited.





