# SDM MCP Server 🔍

Model Context Protocol (MCP) server for B&R Industrial Automation PLCs system dump inspection.

## Link to the sdm-mcp repository

- GitHub Repository: **[sdm-mcp](https://github.com/BRDK-GitHub/sdm-mcp)**

## Add AS Help Configuration

Copy the configuration from [`mcp.json`](./mcp.json) in this directory and add it to your MCP settings:

**Note on File Downloads:**
If you use the `get_raw_dump` tool with Docker, you must mount a volume and set the `SDM_DUMP_DIR` environment variable to access the downloaded files on your host machine.

```json
{
  "servers": {
    "sdm": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-v",
        "${workspaceFolder}/dumps:/dumps",
        "-e",
        "SDM_DUMP_DIR=/dumps",
        "ghcr.io/brdk-github/sdm-mcp:latest"
      ]
    }
  }
}
```
