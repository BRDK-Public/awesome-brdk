# 💬 Prompts

Reusable prompt templates for common B&R Industrial Automation development tasks with GitHub Copilot.

## What are Prompts?

Prompts are markdown files containing template prompts that can be used with GitHub Copilot Chat to accomplish specific tasks efficiently and consistently.

## Available Prompts

### [create-em.prompt.md](./create-em.prompt.md)

Template for creating equipment modules in B&R projects.

**Use Case:** Quickly scaffold new equipment module structures with proper patterns

## 📖 How to Use Prompts

### In VS Code

1. Open the prompt file
2. Copy the relevant prompt section
3. Paste into GitHub Copilot Chat
4. Customize variables (marked with `{{variable}}`)
5. Execute the prompt

### Direct Usage

Many prompts can be used directly:
1. Open GitHub Copilot Chat (`Ctrl+I` or `Cmd+I`)
2. Type `/` to see available slash commands
3. Reference the prompt or paste the template

## 🏗️ Prompt Structure

Prompts typically include:

```markdown
# Prompt Title

## Description
What this prompt does

## Usage
How to use it

## Template
The actual prompt template

## Examples
Sample outputs or variations
```

## 🎯 Best Practices

- **Be Clear**: Use clear, specific language
- **Provide Context**: Include necessary background information
- **Use Variables**: Mark customizable parts with `{{variable}}`
- **Include Examples**: Show expected input/output
- **Version Control**: Update prompts as patterns evolve

## 🤝 Contributing

To add a new prompt:

1. Create a new `.prompt.md` file
2. Use the standard structure (description, usage, template, examples)
3. Test the prompt with various scenarios
4. Update this README
5. Submit a pull request

For more information, see the [main documentation](../docs/README.prompts.md).
