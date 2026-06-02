# 🎯 Agent Skills

Agent Skills are self-contained folders with instructions and bundled resources that enhance AI capabilities for specialized tasks. Based on the [Agent Skills specification](https://agentskills.io/specification), each skill contains a `SKILL.md` file with detailed instructions that agents load on-demand.

Skills differ from other primitives by supporting bundled assets (scripts, code samples, reference data) that agents can utilize when performing specialized tasks.
### How to Use Agent Skills

**What's Included:**
- Each skill is a folder containing a `SKILL.md` instruction file
- Skills may include helper scripts, code templates, or reference data
- Skills follow the Agent Skills specification for maximum compatibility

**When to Use:**
- Skills are ideal for complex, repeatable workflows that benefit from bundled resources
- Use skills when you need code templates, helper utilities, or reference data alongside instructions
- Skills provide progressive disclosure - loaded only when needed for specific tasks

**Usage:**
- Browse the skills table below to find relevant capabilities
- Copy the skill folder to your local skills directory
- Reference skills in your prompts or let the agent discover them automatically

| Name | Description | Bundled Assets |
| ---- | ----------- | -------------- |
| [as-cli](../skills/as-cli/SKILL.md) | Use the B&R Automation Studio CLI for headless project inspection, builds, diagnostics, and repeatable Automation Studio workflows. Use when users mention as-cli, Automation Studio CLI, project status, configuration listing, symbol lookup, build diagnostics, or scripted AS project automation. | None |
| [as-compile](../skills/as-compile/SKILL.md) | Build and transfer B&R Automation Studio projects to a PLC or ARsim simulator. Use when compiling AS projects, creating RUC packages, transferring to PLCs, cleaning build artifacts, or when user mentions build, compile, transfer, deploy, or download to PLC. | `scripts/README.md` |
