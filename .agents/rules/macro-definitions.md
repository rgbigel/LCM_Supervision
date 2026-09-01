---
name: macro-definitions
description: Authoritative governance rule mirror for macro-definitions
globs: "*"
---
<!-- ===================================================================== -->
<!-- ANTIGRAVITY RULE MIRROR                                               -->
<!-- Source Authority: .copilot/Rules/macro-definitions.md                 -->
<!-- Activation: Workspace Automatic                                       -->
<!-- ===================================================================== -->
# macro-definitions.md
# version: 4.2.0

# MACRO-DEFINITIONS-METADATA
# scope: durable-memory
# location: .copilot/Rules/macro-definitions.md
# update-policy: manual

MACRO: @technical
- description: enforce strict technical, ascii-only, deterministic output
- rules:
  - no prose
  - no decoration
  - no emojis
  - no unicode
  - explicit structures only

MACRO: @user
- description: normal user-facing mode
- rules:
  - allow brief explanations
  - allow minimal formatting
  - keep responses concise

MACRO: @S
- description: system-aligned mode
- rules:
  - follow workspace rules
  - follow copilot profile
  - respect durable-memory files

MACRO: @profile status
- description: report current copilot profile state
- rules:
  - summarize durable-memory presence
  - summarize test-suite presence
  - summarize version alignment

MACRO: @tools
- description: display authoritative alphabetical index of LCM and HaSSD06 tools via Show-ToolIndex.ps1
- aliases: ShowTools, showtools, ShowToolsIndex, Show-ToolIndex, @tools, @t, @menu
- rules:
  - 'ShowTools' / 'showtools' / '@tools' / '@t' -> executes 'pwsh -File tools/Show-ToolIndex.ps1 -Audience User'
  - 'ShowTools dev' / 'showtools dev' / '@tools dev' -> executes 'pwsh -File tools/Show-ToolIndex.ps1 -Audience Dev'
  - 'ShowTools ha' / 'showtools ha' / '@tools ha' -> executes 'pwsh -File tools/Show-ToolIndex.ps1 -Group HaSSD06'
  - 'ShowTools lcm' / 'showtools lcm' / '@tools lcm' -> executes 'pwsh -File tools/Show-ToolIndex.ps1 -Group LCM'
  - 'ShowTools all' / 'showtools all' / '@tools all' -> executes 'pwsh -File tools/Show-ToolIndex.ps1 -Audience All'
  - supports -Filter <query> and -NoBrowser / -Cli

MACRO: @set-tool-audience
- description: update whether a tool is User-exposed or Developer-only
- rules:
  - execute 'pwsh -File tools/Set-ToolAudience.ps1 -ToolName <name> -Audience <User|Developer>'

MACRO: @log
- description: locate and open latest LCM log file and reveal full log history in File Explorer
- aliases: @log, @logs, @lastlog
- rules:
  - '@log' or '@logs' -> executes 'pwsh -File tools/Show-LastLog.ps1'
  - '@log <ToolName>' -> executes 'pwsh -File tools/Show-LastLog.ps1 -ToolName <ToolName>'

MACRO: @BCR
- description: launch Beyond Compare 5 visual review display for a repository against baseline commit
- aliases: BCR, @bcr, bcr
- rules:
  - 'BCR <repo>' or 'bcr <repo>' -> executes 'pwsh -File tools/Invoke-BeyondCompareReview.ps1 -RepositoryName <repo>'
  - 'BCR <repo> <commit>' -> executes 'pwsh -File tools/Invoke-BeyondCompareReview.ps1 -RepositoryName <repo> -BaseCommit <commit>'

MACRO: @ACCEPT
- description: submit review result as Accepted, close Beyond Compare review window, run quality gates, and commit
- aliases: ACCEPT, ACCEPTED, @accept, @accepted
- rules:
  - 'ACCEPT <repo>' or 'ACCEPT' -> executes 'pwsh -File tools/Submit-ReviewResult.ps1 -RepositoryPath <repo> -Result Accepted'
  - automatically closes matching Beyond Compare review window
