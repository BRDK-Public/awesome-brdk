---
name: as-cli
description: Use the B&R Automation Studio CLI for headless project inspection, builds, diagnostics, and repeatable Automation Studio workflows. Use when users mention as-cli, Automation Studio CLI, project status, configuration listing, symbol lookup, build diagnostics, or scripted AS project automation.
compatibility: Windows only. Requires B&R Automation Studio and the as-cli executable from https://github.com/br-automation-com/as-cli.
metadata:
  author: brdk
  version: "1.0"
---

# AS CLI

Use `as-cli` for headless B&R Automation Studio project operations when opening the full IDE would be slow, manual, or hard to automate.

## When to Use This Skill

- Inspect an Automation Studio project from a terminal.
- List project status, configurations, logical view, hardware view, or symbols.
- Build, rebuild, or clean a project and collect structured diagnostics.
- Automate repeatable local workflows around AS projects.
- Investigate project structure before editing generated or Automation Studio-managed files.

## Why AS CLI Is Useful

`as-cli` gives agents and scripts a command-line interface to Automation Studio project information. It is useful because it can make project state visible in terminal output, support repeatable build checks, and avoid relying on manual IDE navigation while still working with Automation Studio concepts such as configurations, logical objects, hardware objects, symbols, and diagnostics.

For build workflows, prefer `as-cli` when structured compiler diagnostics are useful for fixing source errors. For repository-level helper scripts that already wrap `BR.AS.Build.exe` or `PVITransfer.exe`, use the repo's documented script instead unless the user specifically asks for `as-cli`.

## Setup

1. Get `as-cli` from `https://github.com/br-automation-com/as-cli` using an account with ABB-EMU access.
2. Place the executable in a stable local folder or add it to `PATH`.
3. Run `as-cli --help` to confirm the installed version and command names.
4. Use the command help for exact options before running project-changing commands.

## Usage Guidelines

1. Start with read-only commands such as help, project info, status, list, or symbol lookup.
2. For build tasks, capture the full output and use reported file, line, column, and error information to guide fixes.
3. Confirm the active configuration before build, transfer, or project-changing operations.
4. Do not run commands that modify project structure, transfer to a PLC, force IO, or clear logs unless the user explicitly asked for that action.
5. Treat Automation Studio-managed files carefully; use `as-cli` to inspect context before editing package, logical view, hardware, or configuration files manually.

## Common Command Areas

Exact commands can vary by `as-cli` version. Use `as-cli --help` and subcommand help from the installed executable before relying on examples.

| Area | Use |
| ---- | --- |
| Project/status | Discover the current project, active configuration, installed AS/PVI paths, and project metadata. |
| Build/clean | Build, rebuild, or clean projects and collect diagnostics for source fixes. |
| Configuration | List configurations, inspect active configuration, and understand target CPU context. |
| Logical view | Inspect programs, packages, libraries, actions, and data objects. |
| Hardware view | Inspect project hardware structure and configured modules. |
| Symbols | Search or resolve project symbols for code navigation and diagnostics. |

## Example Workflow

```powershell
as-cli --help
as-cli info --help
as-cli build --help
```

After confirming the installed syntax, run the needed command against the Automation Studio project path and use the output to plan edits or diagnose build failures.
