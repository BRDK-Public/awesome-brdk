---
name: as-cli
description: 'Run B&R Automation Studio CLI commands (as-cli) correctly. Use when: user wants to build, inspect, or modify an AS project from the terminal; list logical/hardware view; search symbols; connect to PLC; read/write/force PLC variables; read logbook or IO; add/remove/rename programs and packages; scan network; transfer project to PLC; generate PIP or RUC packages; read or modify XML config files (axis, OPC UA, mappMotion, etc.); read hardware module properties; parse Cpu.sw task classes; scan CPU directory for all configs; search config settings by keyword.'
argument-hint: 'Describe what you want to do with the AS project'
---

# AS-CLI — B&R Automation Studio Command-Line Tool

Use this skill to run `as-cli` commands against a B&R Automation Studio project. The CLI uses a per-project daemon with named pipes — the daemon starts automatically on first command.

## Quick Start

Run from any folder inside an AS project (the `.apj` file is found by walking up parent directories):

```
as-cli <command> <subcommand> [args] [options]
```

Global options: `--project <path.apj>`, `--bin-dir <path>`, `--format json|text`, `--timeout <ms>`, `--verbose`

## Commands Reference

### Project & Configuration

```bash
as-cli project status                        # Project name, dir, active config
as-cli project reload                        # Reload project from disk (picks up changes made in AS)
as-cli project close                         # Close project (daemon stays)

as-cli config list                           # All configs (CPU, AR version, GCC)
as-cli config set-active <name>              # Switch active config
as-cli config tree [name]                    # Config object tree
```

### Logical View — List, Add, Remove, Rename

```bash
as-cli logical list                          # All software objects (programs, libs, packages)
as-cli logical catalog                       # What can be added at root
as-cli logical catalog --parent MainPkg      # What can be added inside MainPkg
as-cli logical catalog --type StProgram      # Filter catalog by object type
as-cli logical add StProgram MyProg          # Add ST program at root
as-cli logical add StProgram MyProg --parent MainPkg  # Add under package
as-cli logical add EmptyPackage Utils        # Add empty package
as-cli logical add IecLibrary MyLib          # Add IEC library
as-cli logical add DataTypeFile AppTypes --parent Pkg  # Add .typ file
as-cli logical add VariableFile Globals      # Add .var file
as-cli logical remove MainPkg/OldProgram     # Delete object
as-cli logical rename MainPkg/Old NewName    # Rename object
as-cli logical set-description MainPkg/P "desc"  # Set description
as-cli logical undo                          # Undo last mutation
as-cli logical redo                          # Redo
```

**cwd auto-detection**: If you're inside a `Logical/` subfolder, `catalog` and `add` auto-detect `--parent` from your working directory.

**Catalog elements** (common): `StProgram`, `StProgramAllInOne`, `AnsicProgram`, `AnsiCppProgram`, `IecLibrary`, `AnsicLibrary`, `EmptyPackage`, `DataTypeFile`, `VariableFile`, `SimpleDataObject`, `FunFub`

**Context rules**: Programs/libs/packages go in packages or root. FunFub goes in libraries. Actions go in programs.

### Hardware View

```bash
as-cli hardware list                         # Physical module tree
```

### Build, RUC & PIP

```bash
as-cli build                                 # Incremental build
as-cli build rebuild                         # Full rebuild
as-cli build clean                           # Remove outputs
as-cli build ruc                             # Generate RUC package (incremental)
as-cli build ruc --rebuild                   # Full rebuild + RUC package
as-cli build pip --output ./pip              # Create PIP (offline install package)
as-cli build pip --output ./pip --no-build   # PIP without rebuild
as-cli build pip --output ./pip --install-mode AllowInitialInstallation
as-cli build pip --output ./pip --ignore-version --allow-downgrade
as-cli build sim                             # Build + install to ARSim simulation
as-cli build sim --no-build                  # Simulation install without rebuild
as-cli build sim --output ./my-sim           # Custom simulation output directory
as-cli build sim --no-start                  # Build but do not launch ARSim
as-cli build --filter errors                 # Show only errors
as-cli build --filter errors,warnings        # Show errors + warnings (no info)
as-cli build --filter warnings               # Show only warnings
as-cli build sim --filter errors             # Filter also works on sim/pip/ruc
```

Exit code 0 = success, 1 = errors. Returns structured diagnostics (errors, warnings with file/line).

`--filter` controls which diagnostics are printed. Comma-separated values: `errors`, `warnings`, `info`. Default (no filter) shows all. Available on all build subcommands.

`build ruc` generates a RUCPackage.zip for Runtime Utility Center deployment using BR.AS.Build.exe.

`build pip` creates a PIP package (Project Installation Package) for offline/USB deployment. `--output` is required. **Fails if simulation is enabled** — disable it first with `as-cli sim disable`.

`build sim` builds the project and creates the ARSim simulation structure (same as "Transfer to simulation" in AS). Output goes to `Temp/Simulation/<Config>/<CPU>` by default, or use `--output` for a custom path. **Fails if simulation is not enabled** — enable it first with `as-cli sim enable`. After a successful build, the ARSim simulator is started automatically via `ar000loader.exe` (use `--no-start` to skip).

### Simulation Mode

```bash
as-cli sim enable                            # Enable simulation on the CPU + start ARSim if built
as-cli sim enable --no-start                 # Enable simulation but do not launch ARSim
as-cli sim disable                           # Disable simulation on the CPU + stop running ARSim
as-cli sim status                            # Query running ARSim status via service interface
as-cli sim status --port 4002 --ip 127.0.0.1 # Custom service interface endpoint
as-cli sim stop                              # Graceful stop via service interface (loader stays)
as-cli sim restart                           # Restart ARSim (normal)
as-cli sim restart --cold                    # Cold restart
as-cli sim restart --warm                    # Warm restart
as-cli sim restart --diagnostics             # Restart into DIAGNOSTICS mode
as-cli sim license                           # License status + remaining trial time (AR6+)
as-cli sim timefactor                        # Read current TimeZoom factor
as-cli sim timefactor -2                     # Set TimeZoom factor (-3..+3)
as-cli sim step 100                          # Run 100 system ticks then halt cyclic processing
as-cli sim step resume                       # Resume cyclic processing (0)
as-cli sim step exit                         # Exit single-step mode (-1)
as-cli sim step query                        # Query remaining single-steps
as-cli sim uptime                            # ARSim microsecond counter (AR A4.92+)
```

Toggles the `Simulation` hardware parameter on the main CPU module. `build sim` requires simulation enabled; `build pip` requires it disabled.

`sim enable` also launches the built simulator (`ar000loader.exe`) found in `Temp/Simulation/<ActiveConfig>/<CPU>` if it exists (use `--no-start` to skip); if the project hasn't been built for simulation yet, it reports that and you should run `as-cli build sim`. `sim disable` stops a running simulator via `ar000stop.exe` in the same folder. `build sim` auto-launches the simulator after a successful build unless `--no-start` is given.

**Auto-clean:** Switching between simulation and real hardware can make pre-compiled archives incompatible (e.g. sim x86 vs. target ARM). By default, `sim enable`/`sim disable` automatically runs a build clean after changing the mode. Use `--no-clean` to skip this.

**Status / service interface:** When the CLI starts ARSim (via `sim enable` or `build sim`), it launches `ar000loader.exe` with the service interface enabled (`-i127.0.0.1 -p4002`). `sim status` connects to that TCP interface, sends `<Status Command="10"/>`, and reports the AR state (`RUN`, `SERVICE`, `SHUTDOWN`, `START_PHASE0/1/2`, `DIAGNOSE`) plus the AR version. If ARSim was started outside the CLI without `-i`/`-p`, the service interface is not open and `sim status` reports it as unavailable — restart it with `as-cli sim enable`.

**Service-interface commands:** All of these talk to the same TCP service interface (default `127.0.0.1:4002`, override with `--ip`/`--port`):
- `sim stop` — graceful AR shutdown (loader keeps running; service interface still answers with `SHUTDOWN`). For a full kill use `sim disable` (`ar000stop.exe`).
- `sim restart [--cold|--warm|--diagnostics]` — restart the runtime; default is a normal restart.
- `sim license` — license validity and remaining trial seconds (AR6.00+).
- `sim timefactor [<-3..+3>]` — read (no arg) or set the TimeZoom factor: `+3` ASAP, `+2` 100×, `+1` 10×, `0` 1:1, `-1` 1/10, `-2` 1/100, `-3` 1/1000.
- `sim step <ticks>|resume|exit|query` — single-step control: run N ticks then halt, `resume` cyclic processing, `exit` single-step, or `query` remaining steps.
- `sim uptime` — ARSim microsecond counter (AR A4.92+).

### Transfer (Deployment to PLC)

```bash
as-cli transfer probe                        # Diagnostics for transfer readiness
as-cli transfer online --ip 10.0.0.1        # Online transfer to PLC
as-cli transfer online --ip 10.0.0.1 --no-build  # Transfer without rebuild
as-cli transfer online --ip 10.0.0.1 --install-mode ForceInitialInstallation
as-cli transfer online --ip 10.0.0.1 --strict-version --timeout 60
as-cli transfer online --ip 10.0.0.1 --allow-downgrade --reset-pv-values --no-init-exit
```

**probe** checks CPU hardware, interfaces, ProjectInstallation DLL availability, and files-to-transfer status.

**online** transfers the project directly to a connected PLC. `--ip` is required. Builds a RUC package first (skip with `--no-build`).

### Symbol Intelligence (requires built project)

```bash
as-cli symbol scopes                         # List all scopes (programs, libraries)
as-cli symbol search "motor" --scope "modules.main.main" --max 10
as-cli symbol variables --scope "modules.main.main"
as-cli symbol resolve "Logical.modules.main.main.interface"
as-cli symbol resolve-path "interface.status.emptying" --scope "modules.main.main"
as-cli symbol members "interface.status" --scope "modules.main.main"
```

**Scopes** are dot-separated paths under the logical view (e.g. `modules.main.main`). Use `symbol scopes` to discover them.

**resolve-path** walks a dotted expression segment by segment, resolving types at each level. Returns the type chain.

**members** lists struct/FB members at the end of a path — useful for autocomplete.

### PLC Online (requires PVI Manager running)

```bash
as-cli plc connect --ip 10.0.0.1            # Connect via ANSL/TCP (default port 11169)
as-cli plc connect --ip 10.0.0.1 --port 11170  # Custom port
as-cli plc status                            # CPU state, type, AR version
as-cli plc disconnect
```

### PLC Variables (requires PLC connection)

```bash
as-cli var read gTemperature                 # Read a global variable
as-cli var read gMotorSpeed --task Cyclic    # Read task-local variable
as-cli var write gSetpoint --value 100.5     # Write a variable
as-cli var write gEnable --value 1 --task Cyclic  # Write task-local variable
as-cli var force gOutput --value 1           # Force variable value
as-cli var unforce gOutput                   # Release force
as-cli var list                              # List all variables (max 200)
as-cli var list --filter "motor" --max 50    # Filtered list
as-cli var list --task Cyclic                # Task-local variables
as-cli var type gTemperature                 # Get type information
as-cli var read-multi gTemp gSpeed gPos      # Read multiple variables at once
as-cli var read-multi gTemp gSpeed --task Cyclic
as-cli var watch-start gTemp gSpeed --task Cyclic  # Start watching variables (cyclic)
as-cli var watch-start gTemp gSpeed --task Cyclic --refresh 500  # Custom refresh interval (ms, default: 200)
as-cli var watch-start gTemp gSpeed --task Cyclic --follow  # Stream changes live (Ctrl+C to stop)
as-cli var watch-poll                        # Poll for current watched values
as-cli var watch-stop                        # Stop all watches
as-cli var watch-stop gTemp --task Cyclic    # Stop specific watches
as-cli var resolve-task modules.main.main    # Resolve logical scope to PVI task name
```

**Variable names** can be plain (`gTemperature`) or task-qualified (`Cyclic:gTemperature`). Use `--task` for task-local scope.

**Watch** uses PVI cyclic refresh for efficient monitoring. `watch-start --follow` streams value changes to stdout until Ctrl+C — no manual polling needed. The `--follow` client sends keepalive signals every 60 seconds to prevent the daemon from timing out during long idle periods.

### Logbook (requires PLC connection)

```bash
as-cli logbook list                          # Available logbooks
as-cli logbook read --count 20 --level error # Read system logbook filtered
as-cli logbook read arlogusr --count 50     # Read user logbook
as-cli logbook export --path log.csv --out-format csv
as-cli logbook export arlogusr --path user.json --out-format json
```

Standard logbooks: `arlogsys` (system, default), `arlogusr` (user).

### Module Operations (requires PLC connection)

```bash
as-cli module list                           # List all modules on the PLC
as-cli module upload TCData                  # Upload (read) module from PLC to temp file
as-cli module upload TCData --output ./tc.br # Upload to specific file
```

**module upload** reads a module's binary content from the PLC and saves it locally. Default output is a temp directory.

### IO Data Points (requires PLC connection)

```bash
as-cli io list                               # All IO points
as-cli io list --direction input             # Only inputs
as-cli io read MyDigitalInput                # Read one point
as-cli io read-all --direction output        # Read all outputs
as-cli io read-all --filter "Motor"          # Read filtered by name
as-cli io force MyOutput --value 1           # Force value
as-cli io unforce MyOutput                   # Release force
```

### Network Discovery (requires PVI Manager, no PLC connection needed)

```bash
as-cli network scan                          # SNMP broadcast for B&R devices
as-cli network scan --timeout 10000          # Longer timeout
as-cli network scan --adapter AA:BB:CC:DD:EE:FF  # Specific adapter
as-cli network adapters                      # List local adapters
```

### XML Config

Read, display, and modify AS configuration files via the native IConfigurationModel API through the daemon. All `xml` commands require a project open.

```bash
# Read project config file
as-cli xml read -f Config_1.axis             # Show config tree (* = explicitly set)
as-cli xml read -f UaCsConfig.uacfg --format json  # JSON output
as-cli xml read -f Config_1.axis --show-invisible   # Include hidden parameters

# Hardware modules — list, read, and set (uses IHardwareConfiguration API)
as-cli xml hw-list                           # List modules with type/version
as-cli xml hw-list --format json
as-cli xml hw-read X20CP1686X                # Module config (all parameters)
as-cli xml hw-read X20CP1686X --group FileDevices  # Filter to a specific group
as-cli xml hw-read X20CP1686X --show-invisible     # Include invisible params
as-cli xml hw-read X20DI9371 --format json
as-cli xml hw-set X20CP1686X "FileDeviceName2=USER"              # Set one value
as-cli xml hw-set X20CP1686X "FTP/ActivateFtpServer=1" "SNTP/ActivateSntpServer=1"  # Set multiple

# Set values in project config files
as-cli xml set -f UaCsConfig.uacfg "Network/TcpPort=4841"
as-cli xml set -f Config_1.axis "BaseType=LinearBounded" "MovementLimits/Position/LowerLimit=-500"

# CPU software configuration (reads from active config)
as-cli xml cpu-sw                            # Task classes, libraries, modules
as-cli xml cpu-sw --format json

# Scan — batch parse all config files in a CPU directory
as-cli xml scan Physical/Config1/X20CP0484   # Full report: Cpu.sw + Hardware + all configs
as-cli xml scan Physical/Config1             # Auto-detects CPU subfolder
as-cli xml scan --format json                # Scan active config's CPU dir

# Search — find settings by keyword across all configs
as-cli xml search Physical/Config1 security  # Find all security-related settings
as-cli xml search Physical/Config1 tcp       # Find TCP port and URL settings
as-cli xml search Physical/Config1 ftp       # Find FTP-related configs
as-cli xml search Physical/Config1 anonymous --format json
```

**Hardware commands** (`hw-list`, `hw-read`, `hw-set`) use the native `IHardwareConfiguration` API — they find modules by name from the open project's active hardware structure. No `-f` file path needed. Changes via `hw-set` are persisted automatically to the `.hw` file by the AS runtime. Only works on **existing** configuration entries (cannot add new dynamic nodes like FileDevice3).

**Paths for `set`** use `/`-separated group IDs matching the config tree (e.g. `Security/MessageSecurity/SecurityPolicies/None`). Use `read --format json` to discover valid paths and allowed values.

**Text output** shows a tree with `*` marking explicitly set values. JSON output provides nested `settings` arrays with `id`, `value`, `isDefault`, `allowedValues`.

**`cpu-sw`** reads from the active configuration's CPU — no file path needed.

**`scan`** accepts an optional directory; if omitted, it auto-detects the active config's CPU directory.

**Search** matches against node IDs, display names, descriptions, and values across all config files found by scan.

### Version & Daemon Management

```bash
as-cli version                               # CLI version and AS installation info
as-cli daemon status                         # All running daemons
as-cli daemon stop --project MyProject.apj   # Stop specific daemon
```

Daemons auto-exit after 30 minutes idle. Each project gets its own daemon. Active `--follow` sessions send keepalive signals to prevent idle timeout — the daemon will never shut down while a streaming client is connected.

## Output Formats

- **text** (default): Human-readable, indented
- **json**: Machine-parseable envelope `{ "success": true, "data": ... }` or `{ "success": false, "error": { "code": "...", "message": "..." } }`

Always use `--format json` when parsing output programmatically.

## Help

```bash
as-cli help                                  # All commands
as-cli help logical                          # Detailed logical help
as-cli help --format json                    # Machine-readable help (full command metadata)
```

## Common Workflows

**Explore a project:**
```bash
as-cli project status
as-cli config list
as-cli logical list
as-cli hardware list
```

**Add a program and build:**
```bash
as-cli logical add StProgram MotorCtrl --parent MainPackage
as-cli build
```

**Build and deploy:**
```bash
as-cli build rebuild
as-cli transfer online --ip 10.0.0.1
# or offline:
as-cli build pip --output ./pip-package
```

**Debug symbols after build:**
```bash
as-cli symbol scopes
as-cli symbol variables --scope "modules.main.main"
as-cli symbol resolve-path "interface.cmd.start" --scope "modules.main.main"
```

**Read and write PLC variables:**
```bash
as-cli plc connect --ip 10.0.0.1
as-cli var list --filter "motor"
as-cli var read gMotorSpeed
as-cli var write gMotorSpeed --value 1500
as-cli var read-multi gTemp gSpeed gPos
as-cli plc disconnect
```

**Read PLC logbook errors:**
```bash
as-cli plc connect --ip 10.0.0.1
as-cli logbook read --level error --count 50
as-cli plc disconnect
```

**Inspect and modify config files:**
```bash
as-cli xml read -f Config_1.axis             # Read current axis config
as-cli xml read -f Config_1.axis --format json  # Get paths for scripting
as-cli xml set -f Config_1.axis "BaseType=LinearBounded"
```

**Explore hardware configuration:**
```bash
as-cli xml hw-list                                   # List all modules in project
as-cli xml hw-read X20CP1686X                        # Read module config via API
as-cli xml hw-read X20CP1686X --group FileDevices    # Filter to specific group
as-cli xml hw-set X20CP1686X "FileDeviceName2=USER"  # Modify existing entry
as-cli xml cpu-sw                                    # View task classes & modules
```

**Scan and search all configs:**
```bash
as-cli xml scan Physical/Config1/X20CP1686X         # Overview of everything
as-cli xml search Physical/Config1 security          # Find security settings
as-cli xml search Physical/Config1 "opc" --format json  # JSON for scripting
```
