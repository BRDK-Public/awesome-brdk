# BR Community MCP Server

Model Context Protocol (MCP) server for searching and retrieving information from the B&R Automation Community forum.

## Link to the br-community-mcp repository

- GitHub Repository: **[br-community-mcp](https://github.com/br-automation-community/br-community-mcp)**

## Add BR Community Configuration

Download `br-community-mcp.exe`, place it in `%APPDATA%\br-community-mcp\`, then copy the configuration from [`mcp.json`](./mcp.json) into your MCP settings.

```jsonc
{
  "servers": {
    "br-community": {
      "command": "${env:APPDATA}\\br-community-mcp\\br-community-mcp.exe",
      "args": []
    }
  }
}
```

Use this MCP when you need forum discussions, solved topics, latest topics, top topics, or category information from the B&R Automation Community.
