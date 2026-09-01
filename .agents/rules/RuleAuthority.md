---
name: RuleAuthority
description: Authoritative governance hierarchy, single source of truth, and mandatory rule matrix synchronization policy.
globs: "*"
---
# File: RuleAuthority.md

Module: RuleAuthority  
Purpose: Defines canonical rule authority, governance hierarchy, and mandatory cross-reference synchronization across the workspace.  
Path: .agents/rules/RuleAuthority.md  
Authors: Rolf, Workspace_AI Governance  
Version: 7.0.0  
Status: Authoritative Policy  
Date: 2026-08-29  

---

## 1. Governance Authority Invariants

### `RULE-AUTH-001` (Single Source of Truth & Zero Rule Forking)
- **Canonical Hub**: `D:\Git_Repositories\.agents\rules\` is the single, authoritative canonical root for all LCM governance rules.
- **Child Repositories**: All governed child repositories `MUST` link their local `.agents\rules` directory to the canonical hub via NTFS junction (`mklink /J`).
- **No Independent Truth**: Child repositories and IDE adapter surfaces `MUST NOT` fork, maintain conflicting local copies, or override core governance policies without an approved Change Request.

---

### `RULE-AUTH-002` (Mandatory Rule Matrix Synchronization Invariant)
Whenever an existing rule is updated, or a new rule/policy is created ("invented"), the author or AI agent `MUST` update all discovery entrypoints in the same change set:
1. **Root Quick-Reference Table**: Update [`AGENTS.md`](file:///d:/Git_Repositories/AGENTS.md) with the new rule name, rule codes (`RULE-*`), domain, scope, and key invariant.
2. **Comprehensive Matrix**: Update [`Workspace_AI/docs/LCM-Rules-Cross-Reference.md`](file:///d:/Git_Repositories/Workspace_AI/docs/LCM-Rules-Cross-Reference.md) with the full metadata, enforcing scripts, and quality gate mappings.
3. **Child Junction Verification**: Verify that the newly created rule is immediately visible across all child repository `.agents\rules` junctions.

---

## 2. Activation Commands
- `@RULEAUTH`: Activates and validates the canonical source-of-truth and synchronization policy.
