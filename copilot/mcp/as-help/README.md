# AS Help MCP Server

Model Context Protocol (MCP) server for searching and retrieving B&R Automation Studio help documentation.

## Link to the as-help-mcp workflow

- GitHub Actions: **[as-help-mcp](https://github.com/br-automation-community/as-help-mcp/actions)**

## Add AS Help Configuration

Download the Windows executable from the workflow artifact or release asset, place it in `%APPDATA%\as-help-mcp\`, then copy the configuration from [`mcp.json`](./mcp.json) into your MCP settings.

```jsonc
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

        // Optional: enable hybrid search with a local Ollama embedding model.
        // Install Ollama, then run: ollama pull nomic-embed-text
        // ,"--create-embeddings",
        // "true"
      ]

      // Optional embedding environment for Ollama:
      // ,"env": {
      //   "EMBEDDING_API_ENDPOINT": "http://localhost:11434",
      //   "EMBEDDING_API_KEY": "ollama",
      //   "EMBEDDING_MODEL": "nomic-embed-text",
      //   "EMBEDDING_DIMENSIONS": "768",
      //   "EMBEDDING_BATCH_SIZE": "100",
      //   "EMBEDDING_MAX_CHARS": "4000"
      // }
    }
  }
}
```

Update `--help-root` to match the installed Automation Studio help data folder, for example `C:\\BRAutomation\\AS412\\Help-en\\Data` for AS 4.x.