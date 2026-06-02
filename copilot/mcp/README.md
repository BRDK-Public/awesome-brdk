# Model Context Protocol (MCP) Servers

MCP servers extend GitHub Copilot's capabilities by providing specialized tools and context for B&R Industrial Automation development.

## Available MCP Servers

Model Context Protocol servers for extended functionality:

### AS Help MCP

- **[AS Help MCP in Copilot](./as-help/)** - Search and retrieve B&R Automation Studio help documentation.
- GitHub Actions: **[as-help-mcp](https://github.com/br-automation-community/as-help-mcp/actions)**.

### BR Community MCP

- **[BR Community MCP in Copilot](./br-community/)** - Search and retrieve information from the B&R Automation Community forum.
- GitHub Repository: **[br-community-mcp](https://github.com/br-automation-community/br-community-mcp)**.

## What is MCP?

Model Context Protocol (MCP) is an open standard that enables AI assistants to securely access external tools and data sources. MCP servers provide:

- Custom tools and functions
- Access to external data sources
- Integration with B&R-specific documentation and community knowledge
- Enhanced context for code generation

## Installation

These examples use Windows executables only.

1. Download the `.exe` for the MCP server.
2. Place it in the matching folder under `%APPDATA%`, for example `%APPDATA%\as-help-mcp\`.
3. Copy the configuration from the server's `mcp.json` into `.vscode/mcp.json`.
4. In VS Code, click **Start** above the server name in `.vscode/mcp.json`.

### Configuration

MCP servers are configured in your project's `.vscode/mcp.json`:

```json
{
  "servers": {
    "as-help": {
      "command": "${env:APPDATA}\\as-help-mcp\\as-help-server.exe",
      "args": [
        "--help-root",
        "C:\\Program Files (x86)\\BRAutomation\\AS6\\Help-en\\Data",
        "--db-path",
        "${env:APPDATA}\\as-help-mcp\\data\\as6\\.ashelp_lance",
        "--metadata-dir",
        "${env:APPDATA}\\as-help-mcp\\data\\as6\\.ashelp_metadata",
        "--as-version",
        "6"
      ]
    },
    "br-community": {
      "command": "${env:APPDATA}\\br-community-mcp\\br-community-mcp.exe",
      "args": []
    }
  }
}
```

### Usage with Copilot

Once configured, MCP servers:
- Automatically integrate with GitHub Copilot
- Provide tools accessible via Copilot Chat
- Enhance context for code generation
- Work seamlessly with custom agents


## Contributing

To add a new MCP server:

1. Create a new directory under `mcp/`
2. Implement the MCP server following the protocol specification
3. Provide comprehensive documentation
4. Include executable-based configuration examples
5. Update this README
6. Submit a pull request

## Resources

- [MCP Specification](https://github.com/modelcontextprotocol/specification)
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)

For more information about integrating MCP servers with custom agents, see the [agents documentation](../docs/README.agents.md).
