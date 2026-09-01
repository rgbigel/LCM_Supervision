---
name: DocumentationStandardsPolicy
description: Authoritative documentation standard mandating tripartite repository specifications (Architecture, Requirements, Implementation) and DOX header invariants.
globs: "*.md"
---
# File: DocumentationStandardsPolicy.md

Module: DocumentationStandardsPolicy  
Purpose: Defines mandatory tripartite repository documentation standards, audience scoping, and DOX metadata invariants across all governed repositories.  
Path: .agents/rules/DocumentationStandardsPolicy.md  
Authors: Rolf, Workspace_AI Governance  
Version: 7.0.0  
Status: Authoritative Policy  
Date: 2026-08-29  

---

## 1. Governance Rules

### RULE-DOC-001: Mandatory Tripartite Repository Specifications
Every LCM-governed repository `MUST` maintain three distinct core specifications in `<Repo>/docs/`:
1. **`Architecture.md` (End-User & Concept Perspective)**:
   - Describes the system "View" from an end-user / operator perspective.
   - User mental model, visual topology diagrams (Mermaid), CLI/API usage entrypoints, and external boundaries.
2. **`Requirements.md` (Technical Aspects of Design)**:
   - Describes normative technical constraints, prerequisites, and safety boundaries.
   - Environmental prerequisites (PowerShell 7, OS, Elevation Level), normative invariants (`MUST`/`MUST NOT`), error handling & security constraints.
3. **`Implementation.md` (Code Representation)**:
   - Describes how Architecture and Requirements are concretely realized in code and files.
   - Module & script inventory (`*.psm1`, `*.ps1`), exported cmdlets, parameter signatures, data models (`$schema`), and Pester test traceability.

---

### RULE-DOC-002: Distinct Audience Scoping & Separation of Concerns
- **No Conceptual Bleed**: Code-level file paths, function signatures, and internal parameters belong strictly in `Implementation.md`, not `Architecture.md`.
- **Requirements vs Implementation**: `Requirements.md` specifies *what* rules and constraints must be satisfied; `Implementation.md` catalogs *how* code and test files satisfy them.
- **Top-Level `README.md`**: Top-level `README.md` must serve as an executive summary and navigation index pointing directly to the three core tripartite specifications.

---

### RULE-DOC-003: DOX Metadata Header Invariant
Every Markdown document in `docs/` and `.agents/rules/` `MUST` begin with a standardized DOX metadata header:
```markdown
# <Document Title>

Module: <Relative Path>  
Purpose: <1-2 Sentence Summary of Purpose>  
Path: <Canonical Path>  
Authors: <Author Name / Engine>  
Version: <MAJOR.MINOR.PATCH>  
Status: <Authoritative Standard | Reference | Policy>  
Date: <YYYY-MM-DD>  
```

---

### RULE-DOC-004: Mandatory Universal `install/` Directory and `Installation.md` Runbook Standard
Every LCM-governed repository that deploys or installs operational payloads `MUST` maintain an `install/` directory at the repository root containing an authoritative lifecycle runbook:
1. **Primary Runbook (`install/Installation.md`)**:
   - Step-by-step procedural runbook conforming to the 7-phase procedural lifecycle:
     1. **Prerequisites & Environmental Dependencies**: OS requirements, PowerShell edition, elevation privilege, hardware interlocks, and external dependencies.
     2. **Target Destination Layout & Customization**: Target folder structure (e.g., `D:\Tools\<Component>`), separating top-level user entrypoints/wrappers from internal helper subfolders (`tools/`, `bin/`).
     3. **Preflight System Health Checks**: Verification of prerequisite drivers, running services, and path accessibility before staging.
     4. **Step-by-Step Deployment & Configuration**: Payload staging, file copying, permission hardening, environment variable and `$env:PATH` registration.
     5. **Post-Deployment Verification & Health Checks**: Verification commands, smoke tests, and contract confirmation.
     6. **Ongoing Servicing & Update Runbook**: Step-by-step update process for new versions and hotfixes.
     7. **Rollback & Uninstallation Procedures**: Clean reversal, process termination, service deregistration, and file removal.
2. **Sub-Phase Structure for Complex Installations**:
   - For complex multi-phase deployments, steps may be cleanly separated into numbered sub-documents in `install/` (e.g., `01-Prerequisites.md`, `02-Configuration.md`, `03-Deployment.md`), centrally indexed and orchestrated by `Installation.md`.
   - `install/` contains purely procedural runbooks and deployment scripts; it `MUST NOT` contain a `README.md`.
3. **Decoupled Cross-Repository Boundaries**:
   - External dependencies (such as `SharedModules` or `Workspace_Inventory`) `MUST` be represented strictly as prerequisite assertions and linkage steps without duplicating foreign repository code or internals.

---

### RULE-DOC-005: LCM Major Version Alignment Invariant (`M.Y.Z`)
Whenever a new major LCM version $M$ (e.g. `v6.0.0`, `v7.0.0`) is established and pushed:
1. **Major Parity**: All contained modules, specification documents, scripts, and configuration manifests `MUST` have their version updated such that their **Major** version component matches $M$.
2. **Subversion Preservation**: Subversions (**Minor** $Y$ and **Patch** $Z$) `MUST NOT` be reset or wiped by pre-push major version actions; their relative evolution history and component-level differentiation are strictly preserved.
3. **Transformation Formula**: If a module or spec has version $X.Y.Z$ and the new LCM major version is $M$, the new version becomes:
   $$\text{NewVersion} = M.Y.Z$$
   *(Example: A module at version `2.3.1` when major version 7 is established becomes `7.3.1`).*
4. **Baseline Synchronization**: All explicit global baseline references in configuration files (`.lcm/config.json`, `.vscode/settings.json`, `.github/agents/Config.json`), agent profiles, and DOX headers `MUST` reference the current active LCM baseline.

---

### RULE-DOC-006: Major Release Retention Horizon Policy & Evolution History Taxonomy
At the time of a major release push $M$ (e.g. `v6.0.0`, `v7.0.0`):
1. **2-Major-Release Retention Horizon ($M - 2$)**:
   - All transient operational logs (`tools/logs/*.log`, `Workspace_Inventory/logs/*.log`), temporary scratch dumps (`scratch/`), and legacy deletion trees (`Deletions/`) from major releases older than 2 major versions ($\le M - 2$) `MUST` be completely flushed.
   - For major release $M=6$, all artifacts and deletion trees from major releases $\le 4$ are purged.
   - Transient logs within the active operational window ($M$ and $M-1$) are retained.
2. **Permanent Historical Evolution Logs Exemption**:
   - Logs documenting macro-architectural evolution milestones, lineage transitions, and continuous governance history `MUST NOT` be pruned.
3. **Standardized Evolution History Taxonomy**:
   - **Directory Naming**: `{Sequence:02d}_{Theme_or_Era}-Evolution/` (e.g., `01_Pre-AI-Evolution/`, `02_Method-and-Tooling-Evolution/`, `03_Propagation-and-Continuous-History/`).
   - **File Naming**: `{Sequence:02d}_{Subject}_{MilestoneType}.md` (where `MilestoneType` $\in$ `{Lineage, Governance, Milestones, Architecture, Ledger, Rollup}`).
   - **DOX Metadata Invariant**: All permanent evolution log documents `MUST` declare `Classification: permanent-evolution-history` and `Status: Authoritative Historical Ledger`.
   - **Automated Protection**: All directories matching `*-Evolution/` or files with `Classification: permanent-evolution-history` are unconditionally protected from deletion by cleanup engines and daemons.
