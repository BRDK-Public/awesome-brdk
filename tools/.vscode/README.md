# AS Compile Tasks

VS Code tasks for building and transferring B&R Automation Studio projects.

## Features

- **Auto-detection of AS/PVI** from Windows registry
- **Version matching** - Selects correct AS version for project
- **Configuration discovery** - Parses project to find all configurations
- **Build all configurations** in one task
- **Auto-generated PIL files** - No manual PIL file needed for transfers
- **Problem matcher** - Errors/warnings appear in VS Code Problems panel
- **Colored output** with error/warning counts

## Prerequisites

- B&R Automation Studio 4.x/6.x installed
- PVI 4.x/6.x installed (for transfer tasks)
- PowerShell 5.1 or later

## Setup

Copy the `.vscode` folder to your Automation Studio project root:

```
MyMachine/
├── MyMachine.apj
├── Physical/
├── Logical/
├── LastUser.set
└── .vscode/
    ├── tasks.json
    ├── README.md
    └── scripts/
        └── invoke-as-build.ps1
```

## Available Tasks

### Standard Tasks

| Task Label | Description |
|------------|-------------|
| `AS: Build` | Build with auto-detected AS version and configuration (default) |
| `AS: Build All Configurations` | Build all configurations in project |
| `AS: Rebuild` | Force complete rebuild |
| `AS: Clean` | Remove Temp, Binaries, Diagnosis |
| `AS: Transfer` | Transfer to localhost/ARsim (auto-generates PIL) |
| `AS: Build and Transfer` | Build and transfer to localhost/ARsim |

### Interactive Tasks

| Task Label | Prompts For |
|------------|-------------|
| `AS: Build (Interactive)` | Configuration name, show warnings |
| `AS: Transfer (Interactive)` | Target IP address |
| `AS: Build and Transfer (Interactive)` | Configuration, target IP, show warnings |

## Running Tasks

### From VS Code UI

1. Press `Ctrl+Shift+P`
2. Type "Tasks: Run Task"
3. Select the desired task

Or use `Ctrl+Shift+B` to run the default build task (`AS: Build`).

### From Command Palette

```
Tasks: Run Task → AS: Build
Tasks: Run Task → AS: Build and Transfer
```

## Output Behavior

- **Errors** are always displayed (in red)
- **Warnings** are hidden by default, use Interactive tasks to show them
- Build summary shows error/warning counts per configuration



## How It Works

### AS Version Detection

The script reads the Windows registry to find all installed AS versions:
- `HKLM:\SOFTWARE\WOW6432Node\BR_AS_*`

It then matches the project's AS version (from `.apj` file) to the compatible installation.

### Configuration Discovery

Configurations are discovered by parsing:
- `Physical/Physical.pkg` - Lists all configurations
- `Physical/<Config>/Config.pkg` - Gets CPU name for each config

If no configuration is specified, it reads `LastUser.set` for the active configuration.

### Auto-Generated PIL Files

For transfer operations, the script auto-generates a PIL file:

```
Connection "Cpu", "/IF=TcpIp /IP=<TargetIP>", "/AM=* /SDT=5 /DASESSION=1"
Transfer "<RUCPackage>", "InstallMode=<Mode> ..."
```

### Problem Matcher

Build errors and warnings are parsed and shown in the VS Code Problems panel:

```
Pattern: file(line): error/warning code: message
Example: Main.c(42): error 1234: undefined identifier 'foo'
```

## Customization

### Change Default Target IP

Edit tasks.json and modify the `-TargetIP` argument:

```json
"-TargetIP", "192.168.1.100"
```

### Use Specific Configuration

Add `-Configuration` argument:

```json
"-Configuration", "SimPC"
```

### Always Show Warnings

Add `-ShowWarnings` to the task args:

```json
"args": [
    "-ExecutionPolicy", "Bypass",
    "-File", "${workspaceFolder}/.vscode/scripts/invoke-as-build.ps1",
    "-ProjectPath", "${workspaceFolder}",
    "-Action", "Build",
    "-ShowWarnings"
]
```

## Troubleshooting

### "No Automation Studio installations found"

- Verify AS is properly installed
- Check registry: `HKLM:\SOFTWARE\WOW6432Node\BR_AS_*`
- Script will fall back to default path

### "RUC package not found"

- Build the project before attempting transfer
- Check that the configuration has a valid CPU assigned

### Transfer fails

- Verify PLC/ARsim is running and reachable
- Check target IP address
- Ensure PVI is installed and licensed

### Transfer skipped due to build errors

- This is expected behavior for BuildAndTransfer
- Fix the build errors shown in output and run again