# AS Help MCP Server

> 🔍 Search and retrieve information from B&R Automation Studio help documentation

An MCP (Model Context Protocol) server that provides GitHub Copilot with direct access to B&R Automation Studio help content, enabling context-aware assistance for B&R development.

## Features

- **Full-text search** of Automation Studio help documentation
- **Semantic search** for finding relevant topics
- **Context-aware** documentation retrieval
- **Parameter and function reference** lookup
- **Integration** with custom GitHub Copilot agents

## Prerequisites

Before installing this MCP server, ensure you have:

- ✅ **B&R Automation Studio** installed (with help documentation)
- ✅ **Docker Desktop** installed and running
- ✅ **VS Code** with GitHub Copilot extension
- ✅ Access to the AS Help Docker image

## Installation

### Step 1: Locate Your AS Help Directory

First, find your Automation Studio help documentation directory. The default location is:

```
C:\BRAutomation\AS<VERSION>\Help-en\Data
```

For example: `C:\BRAutomation\AS412\Help-en\Data`

### Step 2: Configure the MCP Server

1. **Open or create** `.vscode/mcp.json` in your project root
2. **Copy the configuration** from [`mcp.json`](./mcp.json) in this directory
3. **Update the configuration** with your specific paths:

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
        "C:\\BRAutomation\\AS412\\Help-en\\Data:/data/help:ro",  // ⬅️ UPDATE THIS PATH
        "-v",
        "ashelp-data:/data",
        "-e",
        "AS_HELP_ROOT=/data/help",
        "-e",
        "AS_HELP_FORCE_REBUILD=false",
        "ghcr.io/brdk-github/as-help-mcp:latest"
      ]
    }
  }
}
```

### Step 3: Customize Your Configuration

#### Update Help Documentation Path

Replace `C:\\BRAutomation\\AS412\\Help-en\\Data` with your actual AS help path:

```jsonc
// Example for AS 4.12
"C:\\BRAutomation\\AS412\\Help-en\\Data:/data/help:ro"

// Example for AS 4.11
"C:\\BRAutomation\\AS411\\Help-en\\Data:/data/help:ro"

// Example for different drive
"D:\\BRAutomation\\AS412\\Help-en\\Data:/data/help:ro"
```

**Note:** Use double backslashes (`\\`) in Windows paths within JSON.

#### Optional: Force Index Rebuild

To force rebuilding the search index on startup, change:

```jsonc
"AS_HELP_FORCE_REBUILD=false"
// to
"AS_HELP_FORCE_REBUILD=true"
```

### Step 4: Verify Installation

1. **Restart VS Code** to load the MCP configuration
2. **Open GitHub Copilot Chat** (Ctrl+I or Cmd+I)
3. **Test the server** by asking: "Search the AS help for motion axis configuration"

If configured correctly, Copilot will have access to search your Automation Studio help documentation.

## Configuration Reference

### Complete mcp.json Example

```jsonc
{
  "servers": {
    "as-help": {
      "command": "docker",
      "args": [
        "run",                                              // Run Docker container
        "--rm",                                             // Remove container after exit
        "-i",                                               // Interactive mode
        "-v",                                               // Mount volume
        "C:\\BRAutomation\\AS412\\Help-en\\Data:/data/help:ro",  // Help docs (read-only)
        "-v",                                               // Mount volume
        "ashelp-data:/data",                               // Persistent data volume
        "-e",                                               // Environment variable
        "AS_HELP_ROOT=/data/help",                         // Help root path
        "-e",                                               // Environment variable
        "AS_HELP_FORCE_REBUILD=false",                     // Force index rebuild
        "docker pull ghcr.io/brdk-github/as-help-mcp:latest"             // Docker image
      ]
    }
  }
}
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AS_HELP_ROOT` | Path to AS help documentation inside container | `/data/help` |
| `AS_HELP_FORCE_REBUILD` | Force rebuild of search index | `false` |

### Docker Volumes

| Volume | Purpose | Type |
|--------|---------|------|
| `C:\BRAutomation\AS412\Help-en\Data` | AS help documentation | Read-only mount |
| `ashelp-data` | Persistent index storage | Named volume |

## Usage

### With GitHub Copilot Chat

Once configured, you can ask Copilot questions about B&R documentation:

```
@workspace Search AS help for mapp Motion axis configuration
```

```
What are the parameters for TON timer?
```

```
How do I configure a gear ratio in ACP10?
```

### With Custom Agents

This MCP server integrates with the [AS Project Agent](../../agents/as-project.agent.md):

1. Install the AS Project Agent
2. The agent will automatically use this MCP server
3. Ask the agent B&R-specific questions

## Troubleshooting

### Docker Not Running

**Error:** `Cannot connect to the Docker daemon`

**Solution:** Start Docker Desktop and ensure it's running.

### Help Path Not Found

**Error:** `Volume path does not exist`

**Solution:** Verify your AS help path exists and update the configuration.

### Permission Issues

**Error:** `Permission denied`

**Solution:** Ensure Docker has permission to access the help directory. On Windows, check Docker Desktop settings > Resources > File Sharing.

### Server Not Loading

1. Check `.vscode/mcp.json` syntax is valid JSON
2. Restart VS Code
3. Check VS Code Developer Tools (Help > Toggle Developer Tools) for errors
4. Verify Docker image is accessible

### Index Issues

If search results are incomplete or outdated:

1. Set `AS_HELP_FORCE_REBUILD=true` in mcp.json
2. Restart VS Code
3. Wait for index to rebuild (first startup may take longer)
4. Set back to `false` for normal operation

## Advanced Configuration

### Multiple AS Versions

To support multiple Automation Studio versions, you can create multiple MCP server entries:

```jsonc
{
  "servers": {
    "as-help-412": {
      "command": "docker",
      "args": [
        // ... configuration for AS 4.12
        "C:\\BRAutomation\\AS412\\Help-en\\Data:/data/help:ro",
        // ...
      ]
    },
    "as-help-411": {
      "command": "docker",
      "args": [
        // ... configuration for AS 4.11
        "C:\\BRAutomation\\AS411\\Help-en\\Data:/data/help:ro",
        // ...
      ]
    }
  }
}
```

### Performance Tuning

For faster startup and better performance:

1. Use a persistent Docker volume for the index (already configured as `ashelp-data`)
2. Keep `AS_HELP_FORCE_REBUILD=false` after initial setup
3. Ensure Docker has adequate resources allocated

## Docker Image

### Building the Image

If you need to build the Docker image yourself, refer to the source repository for build instructions.

### Updating the Image

To update to the latest version:

```bash
docker pull docker pull ghcr.io/brdk-github/as-help-mcp:latest
```

## Related Resources

- [GitHub Copilot Documentation](https://docs.github.com/copilot)
- [Model Context Protocol](https://github.com/modelcontextprotocol/specification)
- [AS Project Agent](../../agents/as-project.agent.md)
- [Custom Agents Guide](../../docs/README.agents.md)

## Support

For issues or questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review the [MCP documentation](../../mcp/README.md)
3. Open an issue in the repository

## License

This MCP server configuration is part of the awesome-brdk project. See the main [LICENSE](../../../LICENSE) for details.
