# AS Help MCP Server 🔍

Model Context Protocol (MCP) server for searching and retrieving B&R Automation Studio help documentation. Optimized for 100K+ help files with instant startup and powerful full-text search.

## Overview

The AS Help MCP server provides GitHub Copilot with access to your local B&R Automation Studio help documentation through:

- 🔍 **Full-text search** using SQLite FTS5 with BM25 ranking
- 📊 **Smart ranking** - title matches weighted 10x higher than content
- ⚡ **Instant startup** - database loads in <1 second after first build
- 📝 **Auto-reindex** - detects XML changes via MD5 hash and rebuilds only when needed
- 🔢 **HelpID lookup** - retrieve pages by their numeric HelpID
- 🔗 **Online help links** - auto-generates URLs to B&R online help (AS4/AS6 via `AS_HELP_VERSION` env var)
- 🏗️ **Breadcrumb navigation** - hierarchical context with cycle detection
- 📈 **Statistics** - 107K+ pages indexed with parent-child relationships
- 🐳 **Docker support** - multi-arch images (amd64/arm64)
- 🚀 **Parallel indexing** - 8 threads for fast HTML text extraction

## Installation

### Prerequisites

Before installing this MCP server, ensure you have:

- ✅ **B&R Automation Studio** installed (with help documentation)
- ✅ **Docker Desktop** installed and running ([Download](https://www.docker.com/products/docker-desktop/))
- ✅ **VS Code** with GitHub Copilot extension
- ✅ Access to the AS Help Docker image at `ghcr.io/brdk-github/as-help-mcp:latest`

### Step 1: Configure MCP Settings

1. **Open VS Code Settings** (File > Preferences > Settings or `Ctrl+,`)
2. **Search for** `mcp` in the settings search bar
3. **Find** "GitHub Copilot > Mcp: Servers"
4. **Click** "Edit in settings.json"

Alternatively, directly open `.vscode/mcp.json` in your workspace or `%APPDATA%\Code\User\globalStorage\github.copilot-chat\mcp.json` for global configuration.

### Step 2: Add AS Help Configuration

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
        "C:\\Program Files (x86)\\BRAutomation\\AS6\\Help-en\\Data:/data/help",
        "-v",
        "ashelp-data:/data",
        "-e",
        "AS_HELP_ROOT=/data/help",
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

**Important:** Update the paths and version to match your Automation Studio installation:

**For AS 4.x:**
```jsonc
"-v", "C:\\BRAutomation\\AS412\\Help-en\\Data:/data/help",
"-e", "AS_HELP_VERSION=4",
```

**For AS 6.x:**
```jsonc
"-v", "C:\\Program Files (x86)\\BRAutomation\\AS6\\Help-en\\Data:/data/help",
"-e", "AS_HELP_VERSION=6",
```

**Note:** Use double backslashes (`\\`) in Windows paths within JSON.

### Step 3: Restart VS Code

After saving the configuration, restart VS Code to activate the MCP server.

### Step 4: Verify Installation

1. **Open GitHub Copilot Chat** (`Ctrl+I` or `Cmd+I`)
2. **Test the server** by asking: "Search the AS help for mapp Motion axis configuration"

If configured correctly, Copilot will have access to search your Automation Studio help documentation.

## Configuration Reference

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `AS_HELP_ROOT` | ✅ Yes | - | Path to B&R help `Data` directory containing `brhelpcontent.xml` |
| `AS_HELP_VERSION` | No | `4` | Automation Studio version for online help URLs (`4` or `6`) |
| `AS_HELP_FORCE_REBUILD` | No | `false` | Force rebuild search index (set `true` for first run) |
| `AS_HELP_DB_PATH` | No | `{AS_HELP_ROOT}/.ashelp_search.db` | Custom database location |
| `AS_HELP_METADATA_DIR` | No | `{AS_HELP_ROOT}/.ashelp_metadata` | Metadata directory (for read-only mounts) |

### Docker Volumes

The configuration uses two volume mounts:

1. **Help files** (required): Maps your AS help directory to `/data/help` in the container
   - Example: `C:\\Program Files (x86)\\BRAutomation\\AS6\\Help-en\\Data:/data/help`
2. **Database persistence** (recommended): `ashelp-data:/data` - stores the search index between container runs

### First Run

On the first run, the server will:
1. Parse `brhelpcontent.xml` 
2. Extract text from HTML files using 8 parallel threads
3. Build SQLite FTS5 search index with BM25 ranking
4. **This takes 5-10 minutes** ⏱️

Subsequent runs start in **<3 seconds** using the cached database.

### Force Rebuild

To rebuild the index (e.g., after AS help update), set `AS_HELP_FORCE_REBUILD=true`:

```jsonc
{
  "servers": {
    "as-help": {
      "command": "docker",
      "args": [
        // ... other args ...
        "-e",
        "AS_HELP_FORCE_REBUILD=true",  // Set to true to rebuild
        "-e",
        "AS_HELP_VERSION=6",
        "ghcr.io/brdk-github/as-help-mcp:latest"
      ]
    }
  }
}
```

Remember to set it back to `false` after the rebuild completes.

## Available MCP Tools

The AS Help MCP server provides the following tools to GitHub Copilot:

| Tool | Description |
|------|-------------|
| `search_help` | Full-text search with BM25 ranking. Returns page_ids only - must call `get_page_by_id` for content. |
| `get_page_by_id` | Get full page content (plain text or HTML). Call for EACH page needed. |
| `get_page_by_help_id` | Retrieve page by HelpID number (e.g., `3002099`) |
| `get_breadcrumb` | Get hierarchical navigation path (rarely needed - included in search results) |
| `get_help_statistics` | Get content statistics (page counts, sections, HelpIDs) |

## Available MCP Prompts

| Prompt | Description |
|--------|-------------|
| `help_search` | Search for a topic and get structured results with page IDs, breadcrumb paths, HelpIDs, and brief summaries. |
| `help_details` | Deep research a topic - retrieves and synthesizes content from multiple pages into a comprehensive answer. |

### Using the `help_search` Prompt

This prompt provides a structured way to search the documentation:

**Input:** A topic to search for (e.g., "MC_BR_MoveAbsolute", "axis error handling", "mapp View")

**Output:** Comprehensive list of matching pages with:
- **Page ID** - For use with `get_page_by_id` to retrieve full content
- **Help Path** - Full breadcrumb showing navigation hierarchy  
- **Online Help** - Direct URL to B&R online help (shareable link)
- **HelpID** - Numeric ID for context-sensitive help integration
- **File Path** - Relative path to the HTML file
- **Type** - Whether it's a Page or Section

**Example:**
```
Prompt: help_search
Topic: "Power Panel T50"

Results:
### Type overview
- **Page ID**: `ec2ece5b-8409-4311-b4b1-e61194a8502b`
- **Help Path**: Hardware > Power Panel > Power Panel T50 > Device description > Type overview
- **Online Help**: https://help.br-automation.com/#/en/6/hardware/powerpanel_t50/type_overview.html
- **HelpID**: None
- **File Path**: `hardware/powerpanel_t50/type_overview.html`
- **Type**: Page
```

### Using the `help_details` Prompt

This prompt performs deep research by reading multiple pages and synthesizing information:

**Input:** A topic requiring thorough explanation (e.g., "MC_BR_MoveAbsolute", "recipe management", "OPC UA server configuration")

**Workflow:**
1. Searches for the main topic (limit=10)
2. Retrieves full content from 3-5 most relevant pages
3. Expands search with related terms (error codes, examples, related features)
4. Retrieves additional relevant pages
5. Synthesizes all information into a comprehensive answer

**Output:** A detailed explanation including:
- **Overview** - High-level summary
- **Key Details** - Core technical information from multiple sources
- **Parameters / Configuration** - Settings and options
- **Usage Examples** - Code examples from documentation
- **Error Handling** - Troubleshooting and error codes
- **Related Topics** - Links to related pages with URLs
- **Sources** - List of all consulted pages with links

**Best for:** Complex topics requiring understanding from multiple documentation pages, function blocks with parameters and error codes, or features spanning multiple areas.

### Search Ranking

Search results are **ranked using BM25** (Best Match 25), a probabilistic ranking algorithm:

- **Title matches**: Weighted **10x** higher than content matches
- **Term frequency**: More occurrences = higher rank
- **Document length normalization**: Short documents with matches rank higher
- **Inverse document frequency**: Rare terms boost ranking more than common terms

Results are returned **sorted by relevance** (best matches first).

## Usage Examples

### With GitHub Copilot Chat

Once configured, you can ask Copilot questions about B&R documentation:

```
Search AS help for mapp Motion axis configuration
```

```
What are the parameters for TON timer?
```

```
How do I configure a gear ratio in ACP10?
```

```
Explain MC_BR_MoveAbsolute function block in detail
```

### With Custom Agents

This MCP server integrates with the [AS Project Agent](../../agents/as-project.agent.md):

1. Install the AS Project Agent
2. The agent will automatically use this MCP server
3. Ask the agent B&R-specific questions

## Advanced Configuration

### Multiple AS Versions

To support multiple Automation Studio versions, create multiple MCP server entries:

```jsonc
{
  "servers": {
    "as-help-4": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "C:\\BRAutomation\\AS412\\Help-en\\Data:/data/help",
        "-v", "ashelp-data-4:/data",
        "-e", "AS_HELP_ROOT=/data/help",
        "-e", "AS_HELP_FORCE_REBUILD=false",
        "-e", "AS_HELP_VERSION=4",
        "ghcr.io/brdk-github/as-help-mcp:latest"
      ]
    },
    "as-help-6": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "C:\\Program Files (x86)\\BRAutomation\\AS6\\Help-en\\Data:/data/help",
        "-v", "ashelp-data-6:/data",
        "-e", "AS_HELP_ROOT=/data/help",
        "-e", "AS_HELP_FORCE_REBUILD=false",
        "-e", "AS_HELP_VERSION=6",
        "ghcr.io/brdk-github/as-help-mcp:latest"
      ]
    }
  }
}
```

