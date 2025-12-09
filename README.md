# Awesome BRDK <img src="https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg" alt="Awesome Badge"/> 

> 😎 A curated collection of B&R Denmark development resources

Welcome to the **Awesome BRDK** repository.

This project serves as a central hub for shareable B&R Industrial Automation developer content and resources.

## Contents

- [Custom Agents](#custom-agents)
- [Instructions](#instructions)
- [Prompts](#prompts)
- [MCP Servers](#mcp-servers)
- [Documentation](#documentation)
- [Contributing](#contributing)

## Custom Agents

Specialized GitHub Copilot agents for B&R development:

- **[AS Project Agent](./copilot/agents/as-project.agent.md)** - Custom agent for Automation Studio project development with B&R systems

[📚 More about Custom Agents](./copilot/agents/README.md)

## Instructions

Instruction files to guide GitHub Copilot's behavior in B&R projects:

- **[AS Project Code Instructions](./copilot/instructions/as-project-code.instructions.md)** - General coding guidelines
- **[AS Project Hardware Instructions](./copilot/instructions/as-project-hardware.instructions.md)** - Hardware-specific development
- **[AS Project Visualization Instructions](./copilot/instructions/as-project-visu.instructions.md)** - HMI and visualization development

[📚 More about Instructions](./copilot/instructions/README.md)

## Prompts

Reusable prompt templates for common B&R development tasks:

- **[Create Equipment Module](./copilot/prompts/create-em.prompt.md)** - Template for creating equipment modules

[📚 More about Prompts](./copilot/prompts/README.md)

## MCP Servers

Model Context Protocol servers for extended functionality:

### AS Help MCP:
- **[AS Help MCP in Copilot](./copilot/mcp/as-help/)** - Search and retrieve B&R Automation Studio help documentation 
- GitHub Repository: **[as-help-mcp](https://github.com/BRDK-GitHub/as-help-mcp)** - Link to the GitHub repository

### AR ANSL MCP:
- **[AR ANSL MCP in Copilot](./copilot/mcp/ar-ansl/)** - ANSL connection to a B&R PLC or the Simulator.
- GitHub Repository: **[ar-ansl-mcp](https://github.com/BRDK-GitHub/ar-ansl-mcp)** - Link to the GitHub repository

[📚 More about MCP Servers](./copilot/mcp/README.md)

## Collections

Curated resource collections for specific scenarios:

- **[AS Project Collection](./copilot/collections/as-project.collection.yml)** - Complete toolkit for Automation Studio development

[📚 More about Collections](./copilot/collections/README.md)

## Tools

Utility scripts and helper tools:

- **[Copilot Wrapper](./tools/README.md)** - PowerShell wrapper for handling SSL/TLS in corporate environments

## Documentation

- **[BRDK Coding Guidelines](./docs/BRDK_Coding_Guideline.md)** - Comprehensive B&R coding standards
- **[MappView Coding Guidelines](./docs/MappView_Coding_Guideline_External.md)** - HMI development guidelines
- **[Copilot Documentation](./copilot/docs/)** - Guides for all Copilot resources

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Add your resource (agent, instruction, prompt, etc.)
4. Update relevant README files
5. Submit a pull request

Please ensure your contributions:
- Follow existing patterns and conventions
- Include comprehensive documentation
- Are tested and validated
- Benefit the wider BRDK community

## License

See [LICENSE](./LICENSE) for details.

## Related Resources

- [GitHub Copilot Documentation](https://docs.github.com/copilot)
- [Awesome Copilot](https://github.com/github/awesome-copilot)
- [Model Context Protocol](https://github.com/modelcontextprotocol)
- [B&R Industrial Automation](https://www.br-automation.com/)
