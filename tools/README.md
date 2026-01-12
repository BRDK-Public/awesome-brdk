# Tools

This directory contains utility scripts and tools relevant for B&R related workflows.


## copilot-wrapper.ps1

This PowerShell script provides a wrapper function for the `copilot` CLI to handle SSL certificate issues by temporarily disabling TLS validation (`NODE_TLS_REJECT_UNAUTHORIZED = '0'`).

This is specifically useful for users getting `unable to fetch` errors when using copilot and Zscaler on the same machine.

### Usage:

To use this wrapper, you need to dot-source the script in your PowerShell profile or current session.

Add the following line to your PowerShell profile (usually `$PROFILE`):

```powershell
. "path\to\awesome-brdk\tools\copilot-wrapper.ps1"
```

Once loaded, you can use the `copilot` command as usual, and it will automatically handle the environment variable setup.

---
## install-certs-wsl.ps1

This script automatically exports a root certificate (e.g., Zscaler) from the Windows Certificate Store and installs it into a WSL distribution. This fixes SSL certificate errors (like `self signed certificate in certificate chain`) when running tools like `curl`, `wget`, `git`, or `apt` inside WSL behind a corporate proxy.

It uses `wslpath` to correctly resolve file paths between Windows and Linux, ensuring compatibility regardless of mount points or username differences.

### Usage:

Run the script from PowerShell:

```powershell
.\install-certs-wsl.ps1
```

### Arguments:

You **do not** need arguments if:
*   You are using **Zscaler** (the script defaults to searching for `*Zscaler Root CA*`).
*   You want to install it in your **default** WSL distribution.

You **do** need arguments if:
*   **Different Certificate:** If your company uses a different proxy or CA, provide its name:
    ```powershell
    .\install-certs-wsl.ps1 -CertSubject "MyCompany Root CA"
    ```
*   **Specific Distro:** If you want to install it in a specific distro (not your default one):
    ```powershell
    .\install-certs-wsl.ps1 -Distro Ubuntu-20.04
    ```

---

## invoke-as-build.ps1

PowerShell script for building and transferring B&R Automation Studio projects. Features auto-detection of AS/PVI installations from registry, configuration discovery by parsing project files, auto-generated PIL files for transfers, and VS Code problem matcher integration for errors/warnings. This script can also be used with "tasks" in .vscode [see here](./.vscode/tasks.json)

### Usage

```powershell
# Build with auto-detection
powershell -ExecutionPolicy Bypass -File .vscode/scripts/invoke-as-build.ps1 -ProjectPath .

# Build all configurations
powershell -ExecutionPolicy Bypass -File .vscode/scripts/invoke-as-build.ps1 -ProjectPath . -Configuration all

# Build with warnings visible
powershell -ExecutionPolicy Bypass -File .vscode/scripts/invoke-as-build.ps1 -ProjectPath . -ShowWarnings

# Build and transfer to specific PLC
powershell -ExecutionPolicy Bypass -File .vscode/scripts/invoke-as-build.ps1 -ProjectPath . -Action BuildAndTransfer -TargetIP 192.168.1.100

# Transfer with custom install mode
powershell -ExecutionPolicy Bypass -File .vscode/scripts/invoke-as-build.ps1 -ProjectPath . -Action Transfer -TargetIP 10.0.0.50 -InstallMode InstallDuringTaskOperation
```

### Arguments:

The `invoke-as-build.ps1` script supports these parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-ProjectPath` | Path to project directory | Required |
| `-Configuration` | Config name or "all" | Auto-detect |
| `-Action` | Build, Rebuild, Clean, Transfer, BuildAndTransfer | Build |
| `-ShowWarnings` | Display warnings in output | Off |
| `-TargetIP` | Target IP for transfer | 127.0.0.1 |
| `-InstallMode` | Consistent or InstallDuringTaskOperation | Consistent |
| `-PILFile` | Custom PIL file (optional) | Auto-generate |
| `-NoClean` | Skip cleaning before build | Off |
| `-BuildPIP` | Generate Project Installation Package | Off |


---

