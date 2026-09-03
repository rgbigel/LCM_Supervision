---
name: ProposalReviewFlowPolicy
description: Governs the LCM Two-Tier Proposal lifecycle, ticket-first enforcement, batch operations, granularity controls, and dual-commit synchronization.
globs: "*"
---
# File: ProposalReviewFlowPolicy.md

Module: ProposalReviewFlowPolicy  
Purpose: Enforces ticket-first proposals, batch commands, Beyond Compare 5 review gates, granularity controls, and Workspace_Inventory dual-commit synchronization.  
Path: .agents/rules/ProposalReviewFlowPolicy.md  
Authors: Rolf, Workspace_AI Governance  
Version: 7.1.0  
Status: Authoritative Policy  
Date: 2026-08-30  

---

## 1. Core LCM Review Flow Rules

### RULE-LCM-001: Proposal-First Intent Invariant
When working in LCM mode (`active`), all user ideas, questions, and exploratory discussions `MUST` be treated as **Proposals only** (State = `suggested`).
- The AI agent `MUST NOT` execute file modifications, code rewrites, or commits immediately upon receiving an initial idea or question.
- When discussion yields a conclusive path of action, register the Change Request / Proposal with State `suggested` in `Workspace_Inventory\data\proposals\proposals.json`.

### RULE-LCM-002: Batch Execution & Control Commands
Proposals transition through the defined lifecycle only upon explicit user instruction:
- **`give open Proposals`**: Returns numbered list of active proposals (`#n`).
- **`do <all, #n, #n-#m> Proposals`**: Sets matching proposals to `processed` and initiates code changes.
- **`delete <all, #n, #n-#m> Proposals`**: Sets matching proposals to `deleted` and clears associated CRs.
- **`defer <all, #n, #n-#m> Proposals`**: Sets matching proposals to `deferred`.
- **`give repos under review`**: Displays repositories with uncommitted changes, their BC5 review status, and commit readiness.

### RULE-LCM-003: Review Granularity Controls
The review frequency is governed by `review_granularity` in `Workspace_Inventory`:
- **`coarse` (Default)**: Executes all proposals in the batch, runs automated quality gates, then presents a **single BC5 review stop** for the combined changes across the repository before commit.
- **`tight`**: Implements each proposal incrementally with intermediate test runs and a **dedicated BC5 review stop per proposal**.
- Can be set via `set review granularity <coarse|tight>` or inline `do #1-#3 Proposals --tight`.

### RULE-LCM-004: Visual Diff Review & Exemption Scope
- **Governed Repositories & Root Container**: Every governed repository and the Root Container (`D:\Git_Repositories`) `MUST` undergo visual diff review via `Invoke-BeyondCompareReview.ps1 <RepoName>` before commit.
- **Sole Exemption**: `Workspace_Inventory` is **the only exempt repository** from visual BC5 review because it acts strictly as the tool/agent-controlled CM ledger (proposals, session state, review evidence, logs).

### RULE-LCM-005: Dual-Commit and Push Synchronization Invariant
1. Whenever code changes in a target repository are accepted and committed, `Workspace_Inventory` `MUST ALWAYS` be updated (updating proposal state to `completed`, recording review evidence) and **committed immediately**.
2. On any `git push`, all modified target repositories and `Workspace_Inventory` `MUST` be pushed to their respective remotes in lockstep.

### RULE-LCM-006: Pause and Resume Controls
- **`pause LCM`**: Temporarily suspends the proposal-first requirement for rapid ad-hoc tasks.
- **`resume LCM`**: Re-activates strict proposal-first governance.
- LCM status is scoped per repository and automatically resets to default active governance across new sessions.

### RULE-LCM-007: Dual-State Proposal Lifecycle & CM Plan Archive Invariant
1. **Dual-State Separation**: Every proposal in `Workspace_Inventory/data/proposals/proposals.json` `MUST` track both:
   - **Governance Plan State (`state`)**: Document approval state (`bug`, `suggested`, `approved`, `deferred`, `rejected`, `completed`, `pushed`).
   - **Implementation Progress State (`progress_state`)**: Physical execution progress (`undecided`, `queued`, `in_progress`, `verification`, `completed`, `pushed`, `blocked`, `failed`).
2. **Initial Invariant**: Every newly submitted proposal and unapproved plan `MUST` initialize with `progress_state: "undecided"`.
3. **Pushed Lifecycle Transition**: Upon successful execution of `Invoke-WorkspacePush.ps1` (or CM Control Hub Push), proposals in `completed` state whose origin repository was pushed `MUST` transition to `pushed` (`pushed_at` timestamp recorded).
4. **Mandatory CM Plan & Walkthrough Archival**:
   - All Markdown implementation plans and execution walkthroughs `MUST` be persistently archived in the governed CM repository under:
     - `Workspace_Inventory/data/proposals/plans/Proposal-{ID:03d}_{CR_ID}_Plan.md`
     - `Workspace_Inventory/data/proposals/plans/Proposal-{ID:03d}_{CR_ID}_Walkthrough.md`
   - Explicit relative links `plan_path` and `walkthrough_path` `MUST` be recorded in `proposals.json`.

### RULE-LCM-008: Lightweight BUG Report & Error Feedback Invariant
1. **Default Lightweight Report on Negative Feedback**: Whenever the operator reports errors, unexpected script failures, broken dependencies, or unwanted agent behavior via prompts, chat, or backchannel inbox:
   - The agent `MUST NOT` immediately initiate a full-scale code rewrite or uncontrolled repository file mutations.
   - The agent `MUST` default to producing a concise **Lightweight BUG Report** containing:
     - **Issue Summary**: Clear description of the symptom or discrepancy.
     - **Superficial Root Cause**: Initial diagnostic hypothesis.
     - **Criticality Assessment**: Impact rating (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`).
     - **Affected Scope**: Target repository and affected modules.
     - **Proposed Remediation Plan**: High-level proposed fix strategy.
2. **Mandatory Operator Stop**: Upon emitting the Lightweight BUG Report, the agent `MUST STOP` and await explicit operator direction (`do <fix>`, `create CRP`, or alternate instructions) before executing code modifications.

### RULE-LCM-009: Scope and Version-Explicit CRP Naming Standard
1. **Canonical Filename Convention**: All Change Request Proposals (CRPs) `MUST` follow the standardized structure:
   `CRP-YYYY-NNN-[Scope]-[Version]-[DescriptiveSlug].md`
   - `[Scope]`: Affected repository/subsystem name (e.g. `Workspace_AI`, `Installation_LCD`, `SystemConfiguration`, `HaSSD06`), `LCM` for core governance, or `Multiple` for cross-cutting bundles.
   - `[Version]`: Target baseline or affected version horizon (e.g. `v7.0.0`, `v6.2.0`, `v1.0.0-v1.2.0`).
   - `[DescriptiveSlug]`: Kebab-case intent description.
2. **Mandatory Header Metadata**: Every CRP specification `MUST` include explicit metadata fields:
   - `Target Scope`: Explicit repository or subsystem boundary.
   - `Affected Version Range`: Semantic version or range.
   - `Impacted Repositories`: Array of modified repositories.

### RULE-LCM-010: Mandatory Self-Discovered Bug Registration Invariant
1. **Mandatory Self-Discovery Reporting**: Whenever the AI agent discovers a bug, syntax defect, unhandled runtime exception, parser failure, or regression in a permanent tool, platform script, shared module, or web UI during development, testing, or tool execution, the AI agent `MUST` formally register a Bug Report in `Workspace_Inventory/data/proposals/proposals.json` and generate an accompanying plan and walkthrough.
2. **Prohibition of Silent In-Place Hotfixing**: The AI agent `MUST NOT` silently patch defects in permanent tools without registering a formal BUG entry in the Configuration Management ledger.

### RULE-LCM-011: Scope and Version-Explicit Bug Report Naming Standard
1. **Canonical Bug Filename Convention**: All formal Bug Reports `MUST` follow the standardized structure:
   `BUG-YYYY-NNN-[Scope]-[Version]-[DescriptiveSlug].md`
   under `Workspace_Inventory/docs/Proposals/`.
2. **Mandatory Frontmatter Metadata**: Every Bug Report `MUST` include explicit frontmatter fields:
   - `Bug-ID`: Sequential unique identifier (e.g. `BUG-2026-001`).
   - `Scope`: Affected repository or subsystem boundary.
   - `Version`: Target release baseline (e.g. `v7.1.0`).
   - `Affected-Repos`: Array of modified repositories.
   - `Severity`: Impact assessment (`Low`, `Medium`, `High`, `Critical`).
   - `Status`: Lifecycle status (`Open`, `In-Progress`, `Completed`).
   - `Root-Cause`: Concise explanation of failure mechanics.

### RULE-LCM-012: Mandatory Scope-and-Version Explicit CRP Specification Generation Invariant
1. **Mandatory Standalone Specification**: Whenever proposing, designing, or implementing new features, tools, workflows, architectural enhancements, or governance policies, the AI agent `MUST` author a formal, standalone Scope-and-Version Explicit Change Request Proposal specification (`CRP-YYYY-NNN-[Scope]-[Version]-[DescriptiveSlug].md`) in `Workspace_Inventory/docs/Proposals/` before or alongside ledger registration.
2. **Prohibition of Orphan Feature Proposals**: Proposing or executing features or tool modifications without an authoritative, permanent `CRP-*.md` specification file in `Workspace_Inventory/docs/Proposals/` is strictly prohibited. Every non-bug feature proposal in `proposals.json` `MUST` link to a valid `bundle_id` matching an existing CRP document.

### RULE-LCM-013: Mandatory Pre-Push Gemini AI & Knowledge Base Synchronization Invariant
1. **Mandatory Automated Pre-Push Execution**: Every multi-repository push operation executed via `Invoke-WorkspacePush.ps1` (or 1-click UI triggers) `MUST` automatically execute the `Update-Gemini.ps1` pipeline prior to pushing commits to remote Git repositories.
2. **Context & Rules Mirroring Parity**: This guarantees that all 17 canonical LCM rules (`Workspace_AI/docs/LCM_Rules_Gemini_Export.md`), plain-text `.txt` mirrors, tool catalogs, and full workspace knowledge base exports (`D:\GDrive\LCM`) are 100% synchronized with the pushed Git baseline at the moment of remote dispatch.
3. **Automated Export Commit**: If the `Update-Gemini` pipeline updates the consolidated rules export in `Workspace_AI`, those changes `MUST` be staged and committed immediately before dispatching the push to `origin/main`.







### RULE-LCM-014: Implementation Plan Auto-Proceed Block Invariant
1. **Mandatory Stop on Open Questions**: Whenever an Implementation Plan (e.g., implementation_plan.md) is drafted and contains **Open Questions** requiring operator clarification, architectural feedback, or explicit decisions, the AI agent MUST NOT proceed to execution under any circumstances.
2. **Override of Auto-Approval**: Even if automated workspace review policies or system hooks attempt to automatically approve the artifact and trigger execution, the AI agent MUST explicitly halt, reject the auto-proceed, highlight the unresolved questions, and await a direct, human-authored response from the operator before executing any code modifications.
