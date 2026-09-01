---
name: CMDRules
description: Authoritative rules for Windows Command Prompt (CMD/Batch) script generation and normalization.
globs: "*.cmd,*.bat"
---
# File: CMDRules.md

Module: CMDRules  
Purpose: Authoritative rules for CMD batch generation, echo control, error levels, and normalization.  
Path: .agents/rules/CMDRules.md  
Authors: Rolf  
Version: 7.0.0  
Status: Authoritative Invariant Rule  
Date: 2026-08-29  

---

## 1. Core CMD & Batch Rules

### CMD-RULES
- **echo-control**: Always begin batch scripts with `@echo off`.
- **errorlevel-handling**: Always verify command outcomes using `if errorlevel 1` or `%ERRORLEVEL%` checks.
- **ascii-default**: CMD batch scripts must strictly use ASCII-only character sets.
- **newline-crlf**: All `*.cmd` and `*.bat` files must end with CRLF line endings.
- **deterministic-output**: Identical input $\rightarrow$ identical output.
- **indent-2**: 2-space indentation for logical blocks and parenthesized expressions.

