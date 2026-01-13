---
name: as-compile
description: Build and transfer B&R Automation Studio projects to a PLC or ARsim simulator. Use when compiling AS projects, creating RUC packages, transferring to PLCs, cleaning build artifacts, or when user mentions build, compile, transfer, deploy, or download to PLC.
compatibility: Windows only. Requires B&R Automation Studio 4.x/6.x and PVI installed. PowerShell 5.1+.
metadata:
  author: brdk
  version: "1.0"
---

# AS Compile

Build and transfer B&R Automation Studio projects using PowerShell with auto-detection of AS/PVI installations, configuration discovery, and auto-generated PIL files.

## When to Use This Skill

- Build an Automation Studio project
- Build all configurations in a project
- Read build errors and fix them in source code
- Generate a RUC package for deployment
- Transfer a compiled project to a PLC or ARsim simulator
- Clean build artifacts (Temp, Binaries, Diagnosis)

## Script

Run the build script from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/invoke-as-build.ps1 -ProjectPath <project-path> [options]
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-ProjectPath` | Path to AS project directory (required) | - |
| `-Action` | Build, Transfer, BuildAndTransfer, Clean, Rebuild | Build |
| `-Configuration` | Configuration name, or "all" for all | Auto-detect |
| `-TargetIP` | IP address for transfer | 127.0.0.1 |
| `-ShowWarnings` | Display warnings in output | Off |
| `-NoClean` | Skip cleaning before build | Off |
| `-InstallMode` | Consistent or InstallDuringTaskOperation | Consistent |
| `-PILFile` | Custom PIL file path | Auto-generate |
| `-BuildPIP` | Generate Project Installation Package | Off |

## Examples

### Build Project
```powershell
powershell -ExecutionPolicy Bypass -File scripts/invoke-as-build.ps1 -ProjectPath .
```

### Build All Configurations
```powershell
powershell -ExecutionPolicy Bypass -File scripts/invoke-as-build.ps1 -ProjectPath . -Configuration all
```

### Rebuild (Clean + Build)
```powershell
powershell -ExecutionPolicy Bypass -File scripts/invoke-as-build.ps1 -ProjectPath . -Action Rebuild
```

### Clean Build Artifacts
```powershell
powershell -ExecutionPolicy Bypass -File scripts/invoke-as-build.ps1 -ProjectPath . -Action Clean
```

### Transfer to ARsim (localhost)
```powershell
powershell -ExecutionPolicy Bypass -File scripts/invoke-as-build.ps1 -ProjectPath . -Action Transfer
```

### Build and Transfer to PLC
```powershell
powershell -ExecutionPolicy Bypass -File scripts/invoke-as-build.ps1 -ProjectPath . -Action BuildAndTransfer -TargetIP 192.168.1.100
```

### Build with Warnings Visible
```powershell
powershell -ExecutionPolicy Bypass -File scripts/invoke-as-build.ps1 -ProjectPath . -ShowWarnings
```

## Guidelines

1. **Auto-detection** - AS/PVI paths and versions are detected from Windows registry
2. **Configuration discovery** - Active config read from LastUser.set, or use first available
3. **Fix errors in code** - Build errors like `error 1126: Expecting ';'` indicate source file issues
4. **Transfer skips on errors** - BuildAndTransfer shows info message if build has errors
5. **Use Clean for strange errors** - Resolves unexplained build failures
6. **No PIL file needed** - Transfers auto-generate PIL based on target IP

## Output

- Errors displayed in red (always shown)
- Warnings displayed in yellow (only with `-ShowWarnings`)
- Build summary shows error/warning counts per configuration
- Exit code 0 on success, non-zero on failure

## Limitations

- Windows only (registry-based AS/PVI detection)
- Requires B&R Automation Studio and PVI installed locally
- PowerShell 5.1 or later required
