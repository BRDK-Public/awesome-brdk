# AS Help MCP Server 🔍

Model Context Protocol (MCP) server for ANSL connection to a B&R PLC or the Simulator. 

## Link to the ar-ansl-mcp repository

- GitHub Repository: **[ar-ansl-mcp](https://github.com/BRDK-GitHub/ar-ansl-mcp)**

## Add AS Help Configuration

Copy the configuration from [`mcp.json`](./mcp.json) in this directory and add it to your MCP settings:

```jsonc
{
  "servers": {
      "ar-ansl": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--add-host", "host.docker.internal:host-gateway",
        "-e", "ANSL_LIB_PATH=/app/lib/libANSLUIF.so",
        "ghcr.io/brdk-github/ar-ansl-mcp:latest"
      ]
    } 
  }
}
```