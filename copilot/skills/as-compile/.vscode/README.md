# AS Compile Tasks

VS Code tasks for building and transferring B&R Automation Studio projects with advanced features.

## Features

- **Auto-detection of AS/PVI** from Windows registry
- **Version matching** - Selects correct AS version for project
- **Configuration discovery** - Parses project to find all configurations
- **Build all configurations** in one task
- **Warning threshold** - Fail build if warnings exceed limit
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
        └── Invoke-ASBuild.ps1
```

## Available Tasks

### Automated Tasks (for runTask)

| Task Label | Description |
|------------|-------------|
| `AS: Build` | Build with auto-detected AS version and configuration |
| `AS: Build All Configurations` | Build all configurations in project |
| `AS: Rebuild` | Force complete rebuild |
| `AS: Clean` | Remove Temp, Binaries, Diagnosis |
| `AS: Transfer` | Transfer to localhost/ARsim (auto-generates PIL) |
| `AS: Build and Transfer` | Build and transfer to localhost/ARsim |
| `AS: Build with Warning Limit` | Build with warning threshold enforcement |

### Interactive Tasks

| Task Label | Prompts For |
|------------|-------------|
| `AS: Build (Interactive)` | Configuration name |
| `AS: Transfer (Interactive)` | Target IP address |
| `AS: Build and Transfer (Interactive)` | Configuration and target IP |

## Running Tasks

### From VS Code UI

1. Press `Ctrl+Shift+P`
2. Type "Tasks: Run Task"
3. Select the desired task

Or use `Ctrl+Shift+B` to run the default build task (`AS: Build`).

### Programmatically (runTask)

Use the exact task label:

```
AS: Build
AS: Build All Configurations
AS: Rebuild
AS: Clean
AS: Transfer
AS: Build and Transfer
AS: Build with Warning Limit
```

## PowerShell Script Parameters

The `Invoke-ASBuild.ps1` script supports these parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-ProjectPath` | Path to project directory | Required |
| `-Configuration` | Config name or "all" | Auto-detect |
| `-Action` | Build, Rebuild, Clean, Transfer, BuildAndTransfer | Build |
| `-MaxWarnings` | Warning threshold (-1 = disabled) | -1 |
| `-TargetIP` | Target IP for transfer | 127.0.0.1 |
| `-InstallMode` | Consistent or InstallDuringTaskOperation | Consistent |
| `-PILFile` | Custom PIL file (optional) | Auto-generate |
| `-NoClean` | Skip cleaning before build | false |
| `-BuildPIP` | Generate Project Installation Package | false |

### Direct Script Usage

```powershell
# Build with auto-detection
.\scripts\Invoke-ASBuild.ps1 -ProjectPath "C:\Projects\MyMachine"

# Build all configurations with warning limit
.\scripts\Invoke-ASBuild.ps1 -ProjectPath "C:\Projects\MyMachine" -Configuration "all" -MaxWarnings 10

# Build and transfer to specific PLC
.\scripts\Invoke-ASBuild.ps1 -ProjectPath "C:\Projects\MyMachine" -Action BuildAndTransfer -TargetIP "192.168.1.100"

# Transfer with custom install mode
.\scripts\Invoke-ASBuild.ps1 -ProjectPath "C:\Projects\MyMachine" -Action Transfer -TargetIP "10.0.0.50" -InstallMode "InstallDuringTaskOperation"
```

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

For transfer operations, the script auto-generates a PIL file if none is provided:

```
Connection "Cpu", "/IF=TcpIp /IP=<TargetIP>", "/AM=* /SDT=5 /DAESSION=1"
Transfer "<RUCPackage>", "InstallMode=<Mode> ..."
```

This eliminates the need for manually creating PIL files.

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

### Add Custom Warning Limit

Create a new task or modify existing:

```json
"-MaxWarnings", "20"
```

### Use Specific Configuration

Add `-Configuration` argument:

```json
"-Configuration", "SimPC"
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
