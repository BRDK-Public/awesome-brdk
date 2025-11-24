# 📋 Instructions

Instruction files (`.instructions.md`) guide GitHub Copilot's behavior and provide context for code generation in B&R Industrial Automation projects.

## What are Instructions?

Instructions are markdown files that:
- Define coding standards and best practices
- Provide project-specific context
- Guide Copilot's code generation patterns
- Enforce organizational conventions

## Available Instructions

### AS Project Instructions

- **[as-project-code.instructions.md](./as-project-code.instructions.md)** - General coding guidelines for B&R projects
- **[as-project-hardware.instructions.md](./as-project-hardware.instructions.md)** - Hardware-specific development guidelines
- **[as-project-visu.instructions.md](./as-project-visu.instructions.md)** - Visualization and HMI development guidelines

## 📖 How to Use Instructions

### In Your Project

1. Copy relevant `.instructions.md` files to your project root or `.github/` directory
2. GitHub Copilot will automatically detect and apply them
3. Instructions work across all Copilot features (inline, chat, etc.)

### Creating Custom Instructions

Instructions use YAML frontmatter:

```markdown
---
description: Brief description of the instruction
applyTo: '**/*.{st,typ,var}'  # File pattern
---

# Your Instructions Here

Provide detailed guidelines, examples, and best practices.
```

## 🎯 Best Practices

- **Be Specific**: Provide concrete examples and patterns
- **Scope Appropriately**: Use `applyTo` patterns to target specific files
- **Keep Updated**: Review and update instructions as standards evolve
- **Layer Instructions**: Use multiple instruction files for different aspects

## 🤝 Contributing

To add new instructions:

1. Create a new `.instructions.md` file
2. Add YAML frontmatter with description and scope
3. Write clear, actionable guidelines
4. Include code examples
5. Update this README
6. Submit a pull request

For more information, see the [main documentation](../docs/README.instructions.md).
