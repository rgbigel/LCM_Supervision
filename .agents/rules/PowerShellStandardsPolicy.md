---
name: PowerShellStandardsPolicy
description: Authoritative PowerShell coding standards enforcing StrictMode array wrapping, approved verb compliance, string interpolation safety, pipeline hygiene, and Pester v5 syntax.
globs: "*.ps1,*.psm1,*.psd1"
---
# File: PowerShellStandardsPolicy.md

Module: PowerShellStandardsPolicy  
Purpose: Defines mandatory PowerShell standards for strict mode resilience, verb compliance, string interpolation, pipeline hygiene, and testing across all repositories.  
Path: .agents/rules/PowerShellStandardsPolicy.md  
Authors: Rolf, Workspace_AI Governance  
Version: 7.1.0  
Status: Authoritative Policy  
Date: 2026-09-03  

---

## 1. Governance Rules

### RULE-PS-001: Safe Collection & Array Handling under StrictMode
Under `Set-StrictMode -Version Latest`, PowerShell disables scalar property virtualization. Accessing `.Count` or `.Length` on a scalar result that does not natively define it throws a `PropertyNotFoundException`.
- **Mandatory Invariant**: All command outputs, function returns, or expressions that may yield `$null`, a single scalar item, or an array `MUST` be wrapped in the array subexpression operator `@(...)` before evaluating `.Count`, accessing indices, or iterating.
- **Correct**:
  ```powershell
  $items = @(Get-ChildItem -Path $targetPath -Filter *.md)
  if ($items.Count -gt 0) { ... }
  ```
- **Forbidden**:
  ```powershell
  $items = Get-ChildItem -Path $targetPath -Filter *.md
  if ($items.Count -gt 0) { ... }  # Throws PropertyNotFoundException if 1 item returned
  ```

---

### RULE-PS-002: Approved Microsoft Verb Compliance
All exported module cmdlets and public functions `MUST` strictly adhere to standard Microsoft approved verbs (`Get-Verb`).
- **Canonical Naming**: Use approved prefixes (`Get`, `Set`, `New`, `Update`, `ConvertFrom`, `Resolve`, `Invoke`, `Add`, `Remove`, `Test`, `Export`, `Format`).
- **Legacy & Domain Aliases**: If a legacy or colloquial name is desired (e.g., `Sync-CRJunctions`, `Parse-ProposalIdExpression`), the canonical implementation `MUST` use an approved verb (e.g., `Update-CRJunctions`, `Resolve-ProposalIdExpression`), and expose the legacy name via `Set-Alias -Name <Legacy> -Value <Canonical>` and `Export-ModuleMember -Alias`.

---

### RULE-PS-003: Colon-Safe String Interpolation
When interpolating a variable immediately followed by a colon (`:`) within a double-quoted string, developers `MUST` delimit the variable using `$($var):` or `${var}:`.
- **Rationale**: PowerShell treats `$var:` as an unclosed scope qualifier (e.g., `$global:`, `$script:`), causing a fatal `ParserError`.
- **Correct**:
  ```powershell
  Write-Host ("Created Proposal #{0}: {1}" -f $newId, $Title)
  # or
  Write-Host "Created Proposal #$($newId): $Title"
  ```
- **Forbidden**:
  ```powershell
  Write-Host "Created Proposal #$newId: $Title"  # Throws ParserError
  ```

---

### RULE-PS-004: Pester v5 Hyphenated Assertion Syntax
All test assertions in `*.Tests.ps1` files `MUST` utilize Pester v5 hyphenated assertion operators per repository quality gates (`Assert-PesterV5Syntax`).
- **Correct**: `Should -Be`, `Should -Not -BeNullOrEmpty`, `Should -BeGreaterThan`, `Should -Throw`.
- **Forbidden**: Legacy unhyphenated assertions (`Should Be`, `Should Not BeNullOrEmpty`).

---

### RULE-PS-005: StrictMode & ErrorAction Defaults
Every production script and module file `MUST` declare strict execution defaults at the beginning of the file:
```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
```

---

### RULE-PS-006: Pipeline Hygiene & Identifier Formatting
- **Assign `$_` First**: In complex `ForEach-Object` pipeline blocks, assign `$_` or `$PSItem` to an explicitly named local variable immediately before nested operations.
- **Function Pipeline Hygiene (Libraries & Atoms)**: In module functions, cmdlets, and library atoms that return values, unneeded command output `MUST` be suppressed using `| Out-Null`, `[void]`, or `$null = ...` to prevent corrupting caller return streams.
- **Interactive CLI & User Scripts Exemption**: User-facing execution scripts, CLI tools, diagnostics, and reports are **exempt** from pipeline suppression for intentional console output, status reporting, and table rendering (`Write-Host`, `Format-Table`, progress messages).
- **ASCII-Only Identifiers**: Variable, parameter, and function names must be strictly ASCII-only (umlauts and special characters permitted only in string literals and comments).

---

### RULE-PS-007: Test Suite Elevation Gating & Runtime Normalization
1. **Pre-Flight Elevation Check**: Test files asserting administrative or privileged capabilities `MUST` inspect `[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrator')` during `BeforeAll`.
2. **Graceful Skip Invariant**: Tests that require Administrator privileges `MUST NOT` attempt live writes when running under an unprivileged user context. They `MUST` either:
   - Gracefully skip live execution (`-Skip:$(-not $isAdmin)`), OR
   - Restrict in-process validation strictly to AST parsing and declarative schema checks, delegating live execution to `Invoke-ElevatedTest.ps1`.
3. **Block Scoping**: `BeforeAll` and `AfterAll` blocks `MUST ALWAYS` reside strictly inside `Describe` or `Context` blocks to ensure compatibility across test runners.

---

### RULE-PS-008: Mandatory File Header Metadata & Date Invariant
All PowerShell scripts (`*.ps1`, `*.psm1`, `*.psd1`) `MUST` contain a standardized metadata header containing the canonical fields:
- `Module`: Canonical module or script identifier.
- `Purpose`: Brief 1-2 sentence description of functionality.
- `Path`: Canonical absolute or repository-relative path.
- `Authors`: Author names and/or AI engine attribution.
- `Version`: Semantic version or date-based version (`YYYY-MM-DD` or `MAJOR.MINOR.PATCH`).
- `Date`: Modification date (`YYYY-MM-DD`).

**Date Update Invariant**:
Whenever an existing script is modified, the `Date:` field (and changelog/version if applicable) `MUST` be updated to the current date. AI agents `MUST NOT` leave stale dates upon modifying script files.

**Canonical Header Format**:
```powershell
<#
.SYNOPSIS
    Brief summary.
.DESCRIPTION
    Module: <ScriptOrModuleName>
    Purpose: <Description>
    Path: <Path>
    Authors: <Author>
    Version: <Version>
    Date: <YYYY-MM-DD>
#>
```

---

### RULE-PS-009: Mandatory Structured Tool Logging & Summary Invariants
All PowerShell automation tools performing system mutations, diagnostics, remediations, repairs, or administrative tasks `MUST`:
1. **Persistent Audit Logging**: Automatically write a timestamped log file to `D:\OneDrive\cmd\logs\` (or repository-specific `logs/` directory) with millisecond-precision timestamps (`yyyy-MM-dd HH:mm:ss.fff`).
2. **Structured Log Levels**: Classify every message using standard log levels: `[INFO]`, `[WARN]`, `[ERROR]`, `[DEBUG]`, `[ACTION]`, `[SUMMARY]` (converging on the `SharedModules/Logging` standard).
3. **Mandatory `[SUMMARY]` Footer**: Emit a standardized terminal and log summary block upon completion displaying:
   - Tool name
   - Version number
   - Execution status (`COMPLETED` / `FAILED`)
   - Exact log file path on disk
   - Execution timestamp
4. **Detailed Inspection Support (`-ShowAll`)**: Tools must support `-ShowAll` / `-Detailed` to expose granular step-by-step diagnostic telemetry to the interactive terminal.

---

### RULE-PS-010: Mandatory `-h` / `-Help` CLI Parameter Support
All standalone PowerShell scripts, diagnostic tools, and CLI automation utilities `MUST`:
1. **Explicit Help Parameter**: Declare `[Alias('h', '?')][switch]$Help` in the `param(...)` block.
2. **Help Intercept & Exit**: When `-h`, `-Help`, or `-?` is passed, the tool `MUST` display a comprehensive, clean usage help screen (detailing synopsis, parameter reference table, and copy-paste examples) and exit cleanly without executing any mutation actions or throwing `ParameterBindingException`.

---

### RULE-PS-011: Interactive Desktop Dispatch Invariant (Session 1 Routing)
All PowerShell scripts, automation tools, and diagnostic reporters that launch interactive GUI applications, web browser dashboards, text editors (Notepad/Notepad++), File Explorer windows, or visible terminal consoles on behalf of the user `MUST`:
1. **Interactive Session Isolation Awareness**:
   Never assume script execution is running inside the interactive desktop. When executed from background agent sessions, IDE workers, or automated task runners (Session 0), raw `Start-Process` invocations are isolated and completely invisible on the user's physical screen.
2. **Mandatory Desktop Dispatch Routing**:
   Inspect whether `Invoke-InteractiveDesktop.ps1` exists in the workspace (`D:\Git_Repositories\tools\Invoke-InteractiveDesktop.ps1` or `$toolsDir`). If present, GUI execution `MUST` be routed through `Invoke-InteractiveDesktop.ps1` using:
   ```powershell
   $dispatcher = Join-Path $toolsDir "Invoke-InteractiveDesktop.ps1"
   if (Test-Path $dispatcher) {
     & pwsh -File $dispatcher -FilePath "explorer.exe" -ArgumentList "`"$htmlPath`"" | Out-Null
   } else {
     Start-Process $htmlPath
   }
   ```
3. **Privileged GUI Elevation**:
   When launching tools requiring administrative elevation in the interactive session, pass `-Elevated` to `Invoke-InteractiveDesktop.ps1` rather than relying on in-process `Start-Process -Verb RunAs`.
4. **Applies Universally To**:
   - HTML Dashboards (`TOOLS_VIEWER.html`, `INVENTORY_VIEWER.html`, `CMD_FOLDER_ANALYSIS.html`)
   - File Explorers (`explorer.exe /select,"<Path>"`)
   - Text Editors (`notepad.exe`, `notepad++.exe`)
   - Interactive Consoles & Terminals (`wt.exe`, `pwsh.exe -NoExit`)

---

### RULE-PS-012: Prohibition of Bare Inline `(if ...)` in Command Invocations
PowerShell parses parentheses `(...)` as an expression group. In PowerShell syntax, `if`, `switch`, and `foreach` are **language statements**, not expressions.
- **The Failure**: Placing a bare `(if (...) { ... } else { ... })` inside a command argument causes the parser to treat `if` as a cmdlet/function name, throwing:
  `The term 'if' is not recognized as a name of a cmdlet, function, script file, or executable program.`
- **Mandatory Invariant**:
  1. **Primary Standard (Pre-assignment - Recommended)**: Pre-calculate the conditional value into an explicitly named local variable immediately before invoking the command.
     ```powershell
     $targetSubsystem = if ($Group -ne 'All') { $Group } else { 'LCM' }
     Build-LcmToolIndexHtml -Subsystem $targetSubsystem
     ```
  2. **Subexpression `$()` Standard**: If evaluated inline, developers `MUST` prefix with the subexpression operator `$(`:
     ```powershell
     Build-LcmToolIndexHtml -Subsystem $(if ($Group -ne 'All') { $Group } else { 'LCM' })
     ```
  3. **PowerShell 7+ Ternary Operator**: Use standard ternary syntax `($cond ? $trueVal : $falseVal)`:
     ```powershell
     Build-LcmToolIndexHtml -Subsystem ($Group -ne 'All' ? $Group : 'LCM')
     ```
- **Strictly Forbidden**:
  ```powershell
  Build-LcmToolIndexHtml -Subsystem (if ($Group -ne 'All') { $Group } else { 'LCM' })  # Fatal Parser Error
  ```

---

### RULE-PS-013: Module Import Parameter Compliance (`Import-Module -Name`)
Unlike filesystem cmdlets (`Get-Content`, `Test-Path`, `Set-Content`), `Import-Module` does `NOT` accept a `-LiteralPath` parameter.
- **Mandatory Invariant**: Always use `-Name` or positional path when importing `.psm1` or `.psd1` files:
  ```powershell
  Import-Module -Name $modulePath -Force
  ```
- **Forbidden**:
  ```powershell
  Import-Module -LiteralPath $modulePath -Force  # ParameterBindingException
  ```

---

### RULE-PS-014: High-Performance NTFS Permission & Smart Inheritance Standard
Brute-force file-by-file recursion (`icacls /T`, `takeown /R`) across entire storage volumes causes millions of redundant disk writes and extreme execution latency (15-45 minutes).
- **Mandatory Invariant**:
  1. Scripts managing NTFS security descriptors `MUST` establish container and object inheritance (`(OI)(CI)(F)`) on parent/root nodes and re-enable clean inheritance (`/inheritance:e`) to allow child objects to inherit permissions dynamically in 0ms.
  2. Explicit `icacls` or `takeown` executions `MUST` be targeted specifically to directory nodes where inheritance is severed or blocked (`Acl.AreAccessRulesProtected == $true`), explicit `DENY` rules are present, or directory junctions require `/L` link-level authorization.
  3. Blind whole-volume recursive rewriting across millions of healthy inheriting files is strictly prohibited.

---

### RULE-PS-015: Variable String Interpolation and Colon Boundaries
The bare syntax `"$var:"` inside double-quoted strings is **strictly prohibited** to avoid PowerShell scope-provider collisions (`ParserError`). PowerShell parses `$identifier:` as an unclosed scope qualifier (`$global:`, `$script:`, `$env:`, drive provider `C:`), causing a fatal parse error at script load time.

- **Mandatory Invariants**:
  1. **Brace Delimitation**: Whenever an interpolated variable is immediately followed by a colon or any non-identifier character that would ambiguate the variable boundary, enclose the variable name in curly braces:
     ```powershell
     Write-Host "Verified Baseline Resolution: [${commitSha}: $commitMsg]"
     Write-Host "Drive root: ${driveLetter}:\\"
     ```
  2. **Format String Alternative**: Use PowerShell format strings as a fully safe alternative for structured output:
     ```powershell
     Write-Host ("Verified Baseline Resolution: [{0}: {1}]" -f $commitSha, $commitMsg)
     ```
  3. **Sub-Expression for Object Properties**: Object property access and nested expressions inside double-quoted strings `MUST` always use sub-expression syntax:
     ```powershell
     Write-Host "Status: $($result.Status) at $($result.Timestamp)"
     ```

- **Strictly Forbidden**:
  ```powershell
  Write-Host "Baseline: [$commitSha: $commitMsg]"   # ParserError — $commitSha: treated as scope qualifier
  Write-Host "Drive: $driveLetter:\\"               # ParserError — $driveLetter: treated as drive provider
  Write-Host "Value: $obj.Property"                 # Silent failure — expands $obj then appends literal '.Property'
  ```

