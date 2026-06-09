# Hooks

Hooks provide event-based automation for agent sessions. They can run small scripts at lifecycle points to collect repository context, prepare tools, or surface project facts before the agent starts work.

## Available Hooks

| Name | Event | Description |
| ---- | ----- | ----------- |
| [session-start-as-project-info](../hooks/session-start-as-project-info.json) | `SessionStart` | Runs [as-project-info.ps1](../hooks/scripts/as-project-info.ps1) to inject a compact B&R Automation Studio project snapshot, including project version, technology packages, configurations, PLC/HMI details, OPC UA, and mappView URLs. |

## How to Use Hooks

Copy the hook JSON file and its referenced scripts into the target repository's `.github` folder, preserving the relative paths used by the hook command.

After copying, the session-start hook expects this layout in the target repository:

```text
.github/hooks/session-start-as-project-info.json
.github/hooks/scripts/as-project-info.ps1
```

The PowerShell script is safe to run in non-AS projects; it emits an empty or partial snapshot when Automation Studio files are not present.