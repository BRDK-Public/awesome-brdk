# 🤖 Custom Agents

Custom agents for GitHub Copilot, making it easy to "specialize" your Copilot coding agent through simple file-based configuration for B&R Industrial Automation development.

## Available Agents

### [AS Project Agent](./as-project.agent.md)

A specialized agent for Automation Studio project development with B&R systems.

**Installation:**
- [![Install in VS Code](https://img.shields.io/badge/VS_Code-Install-0098FF?style=flat-square&logo=visualstudiocode&logoColor=white)](https://aka.ms/awesome-copilot/install/agent?url=vscode%3Achat-agent%2Finstall%3Furl%3Dhttps%3A%2F%2Fraw.githubusercontent.com%2FBRDK-GitHub%2Fawesome-brdk%2Fmain%2Fcopilot%2Fagents%2Fas-project.agent.md)
- [![Install in VS Code Insiders](https://img.shields.io/badge/VS_Code_Insiders-Install-24bfa5?style=flat-square&logo=visualstudiocode&logoColor=white)](https://aka.ms/awesome-copilot/install/agent?url=vscode-insiders%3Achat-agent%2Finstall%3Furl%3Dhttps%3A%2F%2Fraw.githubusercontent.com%2FBRDK-GitHub%2Fawesome-brdk%2Fmain%2Fcopilot%2Fagents%2Fas-project.agent.md)

**Features:**
- Automation Studio project assistance
- B&R-specific code generation
- Integration with B&R help system via MCP

## 📖 How to Use Custom Agents

### Installation

1. Click the **VS Code** or **VS Code Insiders** install button for your desired agent
2. Alternatively, download the `*.agent.md` file and add it to your repository

### MCP Server Setup

- Each agent may require one or more MCP servers to function
- Click the MCP server link to view it on the GitHub MCP registry
- Follow the guide on how to add the MCP server to your repository

### Activation

- Access installed agents through the VS Code Chat interface
- Assign them in GitHub Copilot Chat
- Available through Copilot CLI (coming soon)
- Agents will have access to tools from configured MCP servers

## 🤝 Contributing

To add a new agent:

1. Create a new `.agent.md` file following the existing format
2. Add appropriate metadata and instructions
3. Update this README with the new agent
4. Submit a pull request

For more information, see the [main documentation](../docs/README.agents.md).
