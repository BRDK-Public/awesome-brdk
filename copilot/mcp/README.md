# 🔌 Model Context Protocol (MCP) Servers

MCP servers extend GitHub Copilot's capabilities by providing specialized tools and context for B&R Industrial Automation development.

## What is MCP?

Model Context Protocol (MCP) is an open standard that enables AI assistants to securely access external tools and data sources. MCP servers provide:

- Custom tools and functions
- Access to external data sources
- Integration with B&R-specific systems
- Enhanced context for code generation

## Available MCP Servers

### [AS Help Server](./as-help/)

Search and retrieve information from B&R Automation Studio help documentation.

**Features:**
- Full-text search of AS help content
- Context-aware documentation retrieval
- Parameter and function reference lookup
- Integration with custom agents

**Documentation:** [as-help/README.md](./as-help/README.md)

## 📖 How to Use MCP Servers

### Installation

1. Navigate to the MCP server directory
2. Follow the installation instructions in the server's README
3. Configure the server in `.vscode/mcp.json`

### Configuration

MCP servers are configured in your project's `.vscode/mcp.json`:

```json
{
  "servers": {
    "server-name": {
      "command": "command",
      "args": ["arg1", "arg2"],
      "env": {
        "ENV_VAR": "value"
      }
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

## 🏗️ MCP Server Structure

Each MCP server typically includes:

- `server.py` or equivalent - Main server implementation
- `README.md` - Documentation and setup guide
- `mcp.json` - Configuration template
- `setup.ps1` / `setup.sh` - Installation scripts
- `requirements.txt` or `package.json` - Dependencies

## 🤝 Contributing

To add a new MCP server:

1. Create a new directory under `mcp/`
2. Implement the MCP server following the protocol specification
3. Provide comprehensive documentation
4. Include setup scripts and configuration examples
5. Update this README
6. Submit a pull request

## 📚 Resources

- [MCP Specification](https://github.com/modelcontextprotocol/specification)
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)

For more information about integrating MCP servers with custom agents, see the [agents documentation](../docs/README.agents.md).
