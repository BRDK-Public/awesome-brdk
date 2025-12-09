# AS Help MCP Server 🔍

Model Context Protocol (MCP) server for searching and retrieving B&R Automation Studio help documentation.

## Link to the as-help-mcp repository

- GitHub Repository: **[as-help-mcp](https://github.com/BRDK-GitHub/as-help-mcp)**

## Add AS Help Configuration

Copy the configuration from [`mcp.json`](./mcp.json) in this directory and add it to your MCP settings:

```jsonc
{
  "servers": {
     "as-help": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "-v",
        "C:\\Program Files (x86)\\BRAutomation\\AS6\\Help-en\\Data:/data/help:ro",
        "-v",
        "ashelp-data:/data/db",
        "-e",
        "AS_HELP_FORCE_REBUILD=false",
        "-e",
        "AS_HELP_VERSION=6",
        "ghcr.io/brdk-github/as-help-mcp:latest"
      ]
    } 
  }
}
```