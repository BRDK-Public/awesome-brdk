---
name: as-compile
description: Build and transfer B&R Automation Studio projects to a PLC or simulator using BR.AS.Build.exe and PVITransfer.exe command-line tools. Use when compiling Automation Studio projects, creating RUC packages, transferring to PLCs, or cleaning build artifacts.
---

# AS Compile

This skill enables building and transferring B&R Automation Studio projects using command-line tools. It supports compiling projects, generating RUC packages, and transferring them to PLCs or simulators.

## When to Use This Skill

Use this skill when you need to:
- Build an Automation Studio project from the command line
- Generate a RUC package for deployment
- Transfer a compiled project to a PLC or simulator
- Clean build artifacts (temporary files, binaries, diagnostics)
- Perform a full project rebuild

## Prerequisites

- B&R Automation Studio 6 installed (default path: `C:\Program Files (x86)\BRAutomation\AS6`)
- PVI 6 installed for transfer operations (default path: `C:\Program Files (x86)\BRAutomation\PVI6`)
- Valid Automation Studio project (`.apj` file)
- For transfers: A configured `.pil` file with transfer parameters

## Core Capabilities

### 1. Build Project
Use `BR.AS.Build.exe` to compile the project and generate a RUC package.

**Default Path:** `C:\Program Files (x86)\BRAutomation\AS6\bin-en\BR.AS.Build.exe`

**Command:**
```cmd
"<PathToAS>\BR.AS.Build.exe" "<PathToProject.apj>" -c "<Configuration>" -t "<TempPath>" -o "<OutputPath>" -buildMode "Build" -buildRUCPackage
```

**Arguments:**
| Argument | Description |
|----------|-------------|
| `-h / -?` | Displays help information |
| `-c <config>` | Name of the configuration to build (found in `LastUser.set` as "ActiveConfigurationName") |
| `-t <directory>` | Temporary directory |
| `-o <directory>` | Output directory (typically the `\Binaries` folder) |
| `-all` | Project rebuild (cleans binary and parts of temporary files) |
| `-X` | Create cross reference data only |
| `-clean` | Cleans the Binary and parts of the Temp folder |
| `-clean-temporary` | Cleans the Temp folder |
| `-clean-binary` | Cleans the Binary folder |
| `-clean-generated` | Cleans the `Temp\Includes` and `Temp\Archives\<ConfigName>` folder |
| `-clean-diagnosis` | Cleans the Diagnosis folder |
| `-cleanAll` | Cleans Temp, Binaries, Diagnosis, and remaining temporary folders |
| `-buildMode "<mode>"` | Defines the build mode (use `"Build"`) |
| `-buildRUCPackage` | Flag to create a RUC Package during build |

### 2. Transfer to PLC
Use `PVITransfer.exe` with a PIL file to transfer the generated package to a PLC or simulator.

**Default Path:** `C:\Program Files (x86)\BRAutomation\PVI6\PVI\Tools\PVITransfer\PVITransfer.exe`

**Command:**
```cmd
"<PathToPVI>\PVI\Tools\PVITransfer\PVITransfer.exe" -silent "<PathToPILFile.pil>"
```

**Note:** You must create a `.pil` file defining the transfer parameters (source RUC package, destination, install mode).

## Usage Examples

### Example 1: Build Project
Build a project for the SimPC configuration:
```cmd
"C:\Program Files (x86)\BRAutomation\AS6\bin-en\BR.AS.Build.exe" "C:\Projects\MyMachine\MyMachine.apj" -c "SimPC" -t "C:\Projects\MyMachine\Temp" -o "C:\Projects\MyMachine\Binaries" -buildMode "Build" -buildRUCPackage
```

### Example 2: Transfer Project
Transfer to PLC using a PIL file:
```cmd
"C:\Program Files (x86)\BRAutomation\PVI6\PVI\Tools\PVITransfer\PVITransfer.exe" -silent "C:\Projects\MyMachine\Transfer.pil"
```

### Example 3: Rebuild Project
Force a complete rebuild with `-all`:
```cmd
"C:\Program Files (x86)\BRAutomation\AS6\bin-en\BR.AS.Build.exe" "C:\Projects\MyMachine\MyMachine.apj" -c "SimPC" -t "C:\Projects\MyMachine\Temp" -o "C:\Projects\MyMachine\Binaries" -buildMode "Build" -buildRUCPackage -all
```

### Example 4: Clean Project
Clean all build artifacts (useful for resolving strange errors):
```cmd
"C:\Program Files (x86)\BRAutomation\AS6\bin-en\BR.AS.Build.exe" "C:\Projects\MyMachine\MyMachine.apj" -c "SimPC" -t "C:\Projects\MyMachine\Temp" -cleanAll
```

## Guidelines

1. **Find the active configuration** - Check the `LastUser.set` file in the project root folder for "ActiveConfigurationName"
2. **Use `-cleanAll` for strange errors** - When encountering unexplained build errors, clean all artifacts first
3. **Always specify temp and output paths** - Use `-t` and `-o` to control where build artifacts are stored
4. **Create RUC packages for deployment** - Always include `-buildRUCPackage` when preparing for transfer
5. **Prepare PIL files in advance** - Transfer operations require a properly configured `.pil` file

## Common Patterns

### Pattern: Full Build and Transfer Workflow
```cmd
REM Step 1: Clean previous build
"C:\Program Files (x86)\BRAutomation\AS6\bin-en\BR.AS.Build.exe" "C:\Projects\MyMachine\MyMachine.apj" -c "SimPC" -t "C:\Projects\MyMachine\Temp" -cleanAll

REM Step 2: Build with RUC package
"C:\Program Files (x86)\BRAutomation\AS6\bin-en\BR.AS.Build.exe" "C:\Projects\MyMachine\MyMachine.apj" -c "SimPC" -t "C:\Projects\MyMachine\Temp" -o "C:\Projects\MyMachine\Binaries" -buildMode "Build" -buildRUCPackage

REM Step 3: Transfer to PLC
"C:\Program Files (x86)\BRAutomation\PVI6\PVI\Tools\PVITransfer\PVITransfer.exe" -silent "C:\Projects\MyMachine\Transfer.pil"
```

### Pattern: Incremental Build
```cmd
REM Build without cleaning (faster for iterative development)
"C:\Program Files (x86)\BRAutomation\AS6\bin-en\BR.AS.Build.exe" "C:\Projects\MyMachine\MyMachine.apj" -c "SimPC" -t "C:\Projects\MyMachine\Temp" -o "C:\Projects\MyMachine\Binaries" -buildMode "Build" -buildRUCPackage
```

### Pattern: Clean Specific Artifacts
```cmd
REM Clean only generated files (keeps binaries)
"C:\Program Files (x86)\BRAutomation\AS6\bin-en\BR.AS.Build.exe" "C:\Projects\MyMachine\MyMachine.apj" -c "SimPC" -t "C:\Projects\MyMachine\Temp" -clean-generated
```

## Limitations

- Requires B&R Automation Studio and PVI to be installed locally
- Transfer operations require a pre-configured `.pil` file
- Configuration name must match an existing configuration in the project
- Command paths may vary based on Automation Studio version and installation location
