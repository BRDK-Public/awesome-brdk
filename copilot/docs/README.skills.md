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
| [as-cli](../skills/as-cli/SKILL.md) | Run B&R Automation Studio CLI commands (as-cli) correctly. Use when: user wants to build, inspect, or modify an AS project from the terminal; list logical/hardware view; search symbols; connect to PLC; read/write/force PLC variables; read logbook or IO; add/remove/rename programs and packages; scan network; transfer project to PLC; generate PIP or RUC packages; read or modify XML config files (axis, OPC UA, mappMotion, etc.); read hardware module properties; parse Cpu.sw task classes; scan CPU directory for all configs; search config settings by keyword. | [as-cli repository](https://github.com/br-automation-com/as-cli) |
| [as-compile](../skills/as-compile/SKILL.md) | Build and transfer B&R Automation Studio projects to a PLC or ARsim simulator. Use when compiling AS projects, creating RUC packages, transferring to PLCs, cleaning build artifacts, or when user mentions build, compile, transfer, deploy, or download to PLC. | `scripts/README.md` |
| [as-userlog](../skills/as-userlog/SKILL.md) | Instrument B&R Automation Studio code with temporary UserLog calls for runtime verification and debugging. All logging uses DEBUG ID tagging for clean removal. | `userlog-library/AS4/UserLog/Binary.lby`<br />`userlog-library/AS4/UserLog/Help/LibUserLog.chm`<br />`userlog-library/AS4/UserLog/IecString/LICENSE`<br />`userlog-library/AS4/UserLog/IecString/Package.pkg`<br />`userlog-library/AS4/UserLog/IecString/README.md`<br />`userlog-library/AS4/UserLog/LICENSE`<br />`userlog-library/AS4/UserLog/README.md`<br />`userlog-library/AS4/UserLog/SG4/Arm/UserLog.br`<br />`userlog-library/AS4/UserLog/SG4/Arm/libUserLog.a`<br />`userlog-library/AS4/UserLog/SG4/UserLog.br`<br />`userlog-library/AS4/UserLog/SG4/UserLog.h`<br />`userlog-library/AS4/UserLog/SG4/libUserLog.a`<br />`userlog-library/AS4/UserLog/UserLog.fun`<br />`userlog-library/AS4/UserLog/UserLog.tmx`<br />`userlog-library/AS4/UserLog/UserLog.typ`<br />`userlog-library/AS4/UserLog/UserLog.var`<br />`userlog-library/AS6/UserLog/Binary.lby`<br />`userlog-library/AS6/UserLog/Help/LibUserLog.chm`<br />`userlog-library/AS6/UserLog/IecString/LICENSE`<br />`userlog-library/AS6/UserLog/IecString/Package.pkg`<br />`userlog-library/AS6/UserLog/IecString/README.md`<br />`userlog-library/AS6/UserLog/LICENSE`<br />`userlog-library/AS6/UserLog/README.md`<br />`userlog-library/AS6/UserLog/SG4/Arm/UserLog.br`<br />`userlog-library/AS6/UserLog/SG4/Arm/libUserLog.a`<br />`userlog-library/AS6/UserLog/SG4/UserLog.br`<br />`userlog-library/AS6/UserLog/SG4/UserLog.h`<br />`userlog-library/AS6/UserLog/SG4/libUserLog.a`<br />`userlog-library/AS6/UserLog/UserLog.fun`<br />`userlog-library/AS6/UserLog/UserLog.tmx`<br />`userlog-library/AS6/UserLog/UserLog.typ`<br />`userlog-library/AS6/UserLog/UserLog.var` |
