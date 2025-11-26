# Tools

This directory contains utility scripts and tools relevant for B&R related workflows.

## copilot-wrapper.ps1

This PowerShell script provides a wrapper function for the `copilot` CLI to handle SSL certificate issues by temporarily disabling TLS validation (`NODE_TLS_REJECT_UNAUTHORIZED = '0'`).

This is specifically useful for users getting `unable to fetch` errors when using copilot and Zscaler on the same machine.

### Usage

To use this wrapper, you need to dot-source the script in your PowerShell profile or current session.

Add the following line to your PowerShell profile (usually `$PROFILE`):

```powershell
. "path\to\awesome-brdk\tools\copilot-wrapper.ps1"
```

Once loaded, you can use the `copilot` command as usual, and it will automatically handle the environment variable setup.

```powershell
copilot ...
```
