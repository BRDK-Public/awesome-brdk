# Awesome BRDK <img src="https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg" alt="Awesome Badge"/> 

> 😎 A curated collection of B&R Denmark development resources

Welcome to the **Awesome BRDK** repository.

This project serves as a central hub for shareable B&R Industrial Automation developer content and resources.

## Contents

- [Custom Agents](/copilot/docs/README.agents.md)
- [Hooks](/copilot/docs/README.hooks.md)
- [Instructions](/copilot/docs/README.instructions.md)
- [Prompts](/copilot/docs/README.prompts.md)
- [Skills](/copilot/docs/README.skills.md)
- [MCP Servers](/copilot/mcp/README.md)
- [Tools](/tools/README.md)
- [Documentation](/docs/README.md)

## AS CLI

[as-cli](https://github.com/br-automation-com/as-cli) is the B&R Automation Studio command-line tool used by the [AS CLI skill](/copilot/skills/as-cli/SKILL.md). Agents can use the skill to run `as-cli` correctly for project inspection, builds, diagnostics, transfers, simulation, PLC access, and XML configuration work.

The CLI is also useful outside Copilot for DevOps and automation workflows: scripted local builds, RUC/PIP package generation, deployment checks, configuration inspection, and repeatable project diagnostics without opening Automation Studio.

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository (optional)
2. Create a feature branch
3. Add your resource (agent, instruction, prompt, skills etc.)
4. Update relevant README files (use the scripts in the [package.json](/copilot/scripts/package.json) to generate documentation for the [docs](/copilot/docs/) folder)
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
- [Skills](https://agentskills.io/specification)
- [B&R Industrial Automation](https://www.br-automation.com/)
