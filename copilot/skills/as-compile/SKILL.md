---
name: as-compile
description: Build and transfer B&R Automation Studio projects to a PLC or simulator using VS Code tasks. Use when compiling Automation Studio projects, creating RUC packages, transferring to PLCs, or cleaning build artifacts.
---

# AS Compile

This skill enables building and transferring B&R Automation Studio projects using VS Code tasks. It provides auto-detection of AS/PVI installations, configuration discovery, and auto-generated PIL files for transfers.

## When to Use This Skill

Use this skill when you need to:
- Build an Automation Studio project from VS Code
- Build all configurations in a project
- Use the output to read build errors and correct them
- Generate a RUC package for deployment
- Transfer a compiled project to a PLC or simulator
- Enforce warning thresholds (quality gates)
- Clean build artifacts (temporary files, binaries, diagnostics)

## Prerequisites

- B&R Automation Studio 4.x or 6.x installed
- PVI 4.x or 6.x installed (for transfer operations)
- PowerShell 5.1 or later
- VS Code with the `.vscode` folder configured

## Core Capabilities

### 1. Build Project
Compile the project with automatic AS version detection and configuration discovery.

```
Run task: AS: Build
```

### 2. Build All Configurations
Build every configuration defined in the project.

```
Run task: AS: Build All Configurations
```

### 3. Rebuild Project
Force a complete rebuild with clean.

```
Run task: AS: Rebuild
```

### 4. Clean Project
Remove all build artifacts (Temp, Binaries, Diagnosis folders).

```
Run task: AS: Clean
```

### 5. Transfer to PLC
Transfer to a PLC or ARsim. PIL file is auto-generated.

```
Run task: AS: Transfer
```

### 6. Build and Transfer
Build and transfer in a single operation.

```
Run task: AS: Build and Transfer
```

### 7. Build with Warning Limit
Build with quality gate - fails if warnings exceed threshold.

```
Run task: AS: Build with Warning Limit
```

## Usage Examples

### Example 1: Simple Build
```
Run task: AS: Build
```
Auto-detects AS version and configuration from LastUser.set.

### Example 2: Build All Configurations
```
Run task: AS: Build All Configurations
```
Builds every configuration in the project for CI/CD validation.

### Example 3: Deploy to ARsim
```
Run task: AS: Build and Transfer
```
Builds and transfers to localhost (127.0.0.1).

### Example 4: Deploy to Physical PLC
```
Run task: AS: Build and Transfer (Interactive)
Enter configuration: MyConfig
Enter IP: 192.168.1.100
```

## Guidelines

1. **Let auto-detection work** - AS/PVI paths and versions are detected automatically from registry
2. **Use Build All Configurations** - For CI/CD pipelines to validate all configs compile
3. **Set warning limits** - Use warning threshold for quality gates in automated builds
4. **No PIL file needed** - Transfers auto-generate PIL files based on target IP
5. **Fix Build errors in the code** - When output indicate an error in the source code files (like: \Logical\Main\Main\Main.st: (Ln: 182, Col: 5) error 1126:Expecting ';' or ':=' before 'END_FOR'.), fix them and perform a new build  
6. **Use Clean for strange errors** - When encountering unexplained build errors

## Common Patterns

### Pattern: CI/CD Build All
```
Run task: AS: Build All Configurations
```
Builds every configuration to ensure all variants compile.

### Pattern: Quality Gate Build
```
Run task: AS: Build with Warning Limit
Enter: 0
```
Fails build if any warnings exist (zero-warning policy).

### Pattern: Clean Rebuild and Transfer
```
Run task: AS: Clean
Run task: AS: Build and Transfer
```

## Limitations

- Requires B&R Automation Studio and PVI to be installed locally
- PowerShell 5.1 or later required
- Windows only (registry-based detection)
- Tasks must be run from VS Code
