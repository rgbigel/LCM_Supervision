---
name: JsonRules
description: Authoritative rules for JSON data serialization, schemas, encoding, and formatting.
globs: "*.json"
---
# File: JsonRules.md

Module: JsonRules  
Purpose: Authoritative rules for JSON normalization, schema referencing, encoding, and indentation.  
Path: .agents/rules/JsonRules.md  
Authors: Rolf  
Version: 7.0.0  
Status: Authoritative Invariant Rule  
Date: 2026-08-29  

---

## 1. Core JSON Invariants

### JSON-RULES
- **utf8-without-bom**: All JSON files must be encoded as UTF-8 without BOM.
- **indent-2**: JSON files must use clean 2-space indentation (e.g. `ConvertTo-Json -Depth 5`).
- **newline-crlf**: All JSON files must end with CRLF line endings.
- **schema-declaration**: JSON data files should include a `$schema` property referencing a valid draft schema when applicable.
- **ascii-default**: ASCII recommended for keys and identifiers; UTF-8 strings permitted for localized values.
- **deterministic-output**: Predictable, key-ordered serialization (`[ordered]@{ ... }`).

