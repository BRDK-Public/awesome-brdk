# 📚 Collections

Curated collections of related GitHub Copilot resources for B&R Industrial Automation development.

## What are Collections?

Collections group related agents, instructions, and prompts together for specific development scenarios. They provide a complete toolkit for particular types of projects or tasks.

## Available Collections

### [AS Project Collection](./as-project.collection.yml)

A comprehensive collection for Automation Studio project development.

**Includes:**
- Custom agents for B&R development
- Project-specific instructions
- Code generation prompts
- Hardware and visualization guidelines

**Documentation:** [as-project.md](./as-project.md)

## 📖 How to Use Collections

1. Review the collection YAML file to see what resources are included
2. Read the collection documentation (`.md` file) for detailed usage
3. Install the referenced agents and instructions
4. Apply the collection to your project

## 🏗️ Collection Structure

Collections are defined in YAML format with the following structure:

```yaml
name: Collection Name
description: Brief description
resources:
  agents:
    - path/to/agent.md
  instructions:
    - path/to/instruction.md
  prompts:
    - path/to/prompt.md
```

## 🤝 Contributing

To create a new collection:

1. Define your collection in a `.collection.yml` file
2. Create a documentation file (`.md`) explaining the collection
3. Reference existing resources or create new ones
4. Update this README
5. Submit a pull request

For more information, see the [main documentation](../docs/README.collections.md).
