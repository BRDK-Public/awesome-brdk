# 🔌 Model Context Protocol (MCP) Servers

MCP servers extend GitHub Copilot's capabilities by providing specialized tools and context for B&R Industrial Automation development.

## What is MCP?

Model Context Protocol (MCP) is an open standard that enables AI assistants to securely access external tools and data sources. MCP servers provide:

- Custom tools and functions
- Access to external data sources
- Integration with B&R-specific systems
- Enhanced context for code generation

## GitHub Container Registry (GHCR) Authentication

Many of our MCP servers are distributed as Docker images via GitHub Container Registry. To use them, you need to authenticate Docker with GitHub.

1.  Create a **Personal Access Token (Classic)** with `read:packages` scope.
    *   Follow the guide here: [Creating a personal access token (classic)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic)
    *   **Important:** Ensure your token has an expiration date set.

2.  Authenticate Docker using your username and the token:
    ```bash
    docker login -u <YOUR_GITHUB_USERNAME> ghcr.io
    ```
    When prompted for the password, paste your Personal Access Token.

## 📖 How to Use MCP Servers

### Installation

1. Navigate to the MCP server directory
2. Follow the installation instructions in the server's README
3. Start Docker Desktop 
4. Configure the server in `.vscode/mcp.json`
5. Click "Start" just over the server name in `.vscode/mcp.json`

### Configuration

MCP servers are configured in your project's `.vscode/mcp.json`:

```json
{
  "servers": {
    "server1-name": {
      "command": "docker",
      "args": [
        "arg1", 
        "arg2",
        "arg2"
        ]
    },
    "server2-name": {
      "command": "docker",
      "args": [
        "arg1", 
        "arg2",
        "arg2"
        ]
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
