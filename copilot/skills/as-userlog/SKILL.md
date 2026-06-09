---
name: as-userlog
description: Instrument B&R Automation Studio code with temporary UserLog calls for runtime verification and debugging. All logging uses DEBUG ID tagging for clean removal.
---

# UserLog

UserLog is a **verification/debugging tool**. Do NOT add permanent UserLog calls unless the user requests it. All debug logging MUST use DEBUG ID tagging for clean removal.

## When to Use UserLog

Use UserLog when **ANSL is not enough** — specifically:
- **Timing-dependent logic** (timers, delays, pulses) — ANSL round-trips (~2s) are too slow for sub-second events
- **Cross-task synchronization** — ANSL reads one variable at a time; UserLog captures events across all tasks with PLC-clock timestamps
- **Event sequences** — transient signals that ANSL can't observe

UserLog entries are timestamped by the PLC's real-time clock at the exact scan cycle, giving millisecond-accurate event ordering.

## Debug Session Lifecycle

```
1. Generate unique DEBUG ID (random alphanumeric, e.g., "a1b2c3d4")
2. Ensure UserLog library is installed (see "Installing the Library" below)
3. Add debug variables to .var file — tag every line with (* DEBUG ID: <id> *)
4. Add logbook creation to _INIT — tag every line with // DEBUG ID: <id>
5. Add UserLogCustom calls — tag every line with // DEBUG ID: <id>
6. Build and Transfer → read logs via the `as-logbook` MCP server → analyze → fix → repeat
7. Clean up: run debug line removal (see `as-compile` skill) with the DEBUG ID
```

> **MANDATORY GATE — DO NOT SKIP:** Before adding ANY debug code (steps 3-5), you MUST complete step 2 first. Check if UserLog is installed. If missing, add it and build to verify. Only then proceed to instrumentation. Skipping this leads to silent failures.

> **READING LOGS:** ALWAYS use `read_logbook` from the `as-logbook` MCP server to read entries. NEVER use `read_logger` from the `ar-ansl` MCP server — it cannot decode UserLog formatted messages and returns empty text.

## Installing the Library

The UserLog library is a non-system library bundled with this skill:
- **AS4 projects**: `.github/skills/as-userlog/userlog-library/AS4/UserLog`
- **AS6 projects**: `.github/skills/as-userlog/userlog-library/AS6/UserLog`

### Steps
1. **Check** if UserLog is already present (see `as-compile` skill for library management commands). Exit code 0 = present, 1 = missing.
2. **Determine source path**: Read the `.apj` file for `<?AutomationStudio Version="4.x"?>` or `6.x` → use `AS4` or `AS6` subfolder.
3. **Add** UserLog with the library management script (see `as-compile` skill). This auto-resolves dependencies (`ArEventLog`, `sys_lib`, `astime`).
4. **Build** to verify (see `as-compile` skill).

### Dependencies
| Library | Type | Notes |
|---------|------|-------|
| `ArEventLog` | B&R system | Version >= 4.21.0 |
| `sys_lib` | B&R system | Any version |
| `astime` | B&R system | Any version |

All dependencies are resolved automatically by the add action.

## API Reference

### UserLogBasic — Simple message logging
```iec-st
status := UserLogBasic(
    Severity,   // DINT: severity level (use UserLogSeverityEnum)
    Code,       // UINT: event code 0..65535
    Message     // STRING: event description
);
```
Writes to the default `$arlogusr` (User) logbook. Returns 0 on success, error constant on failure.

### UserLogAdvanced — Message with runtime values
```iec-st
VAR
    logValues : UserLogFormatType;
END_VAR

logValues.i[0] := axisPosition;
logValues.f[0] := temperature;
logValues.s[0] := 'Axis1';

status := UserLogAdvanced(
    USERLOG_SEVERITY_WARNING, 
    200, 
    'Axis %s pos=%i temp=%f', 
    logValues
);
```
Format specifiers: `%b` (BOOL), `%f` (LREAL), `%i` (DINT), `%s` (STRING). Up to 6 of each (index 0..5).

### UserLogCustom — Full control (preferred for debugging)
```iec-st
status := UserLogCustom(
    'MyLogbook',                    // Logbook name (max 10 chars)
    USERLOG_SEVERITY_ERROR,         // Severity
    10,                             // Facility (0..4095)
    300,                            // Code (0..65535)
    0,                              // Origin record ID (0 if none)
    'MainTask',                     // Object name (optional, '' if none)
    'Critical failure: code=%i',    // Message with format specifiers
    logValues                       // Format values
);
```

### UserLogCreate — Create a custom logbook (INIT only)
```iec-st
result := UserLogCreate('MyLog', 65536);  // name max 10 chars, size min 4096 bytes
```

### Severity Levels
| Constant | Value | Use for |
|----------|-------|---------|
| `USERLOG_SEVERITY_SUCCESS` | 0 | Operation completed / traces |
| `USERLOG_SEVERITY_INFORMATION` | 1 | User-facing info / milestones |
| `USERLOG_SEVERITY_WARNING` | 2 | Non-critical issue / unexpected conditions |
| `USERLOG_SEVERITY_ERROR` | 3 | Recoverable error |
| `USERLOG_SEVERITY_CRITICAL` | 4 | Unrecoverable error |

> **NOTE:** There is no DEBUG severity. The minimum usable severity is `USERLOG_SEVERITY_SUCCESS` (0).

### Important Notes
- `UserLogBasic` and `UserLogAdvanced` write to the built-in `User` logbook
- Maximum message length: 120 characters (`USERLOG_MESSAGE_LENGTH`)
- Format string max values per type: 6 (index 0..5, `USERLOG_FORMAT_INDEX`)
- String format values max length: 80 characters (`USERLOG_FORMAT_LENGTH`)
- All UserLog functions are **synchronous** — they execute immediately
- Error return constants: `USERLOG_ERROR_IDENT`, `USERLOG_ERROR_WRITE`, `USERLOG_ERROR_CREATE`
- Use `UserLogCreate` only in INIT routines; logbook persists across warm restarts

## Agentic Debugging Workflow

### DEBUG ID Tagging Rules

**Every line** you add for debugging MUST end with a DEBUG ID comment:

In `.st` files (Structured Text):
```iec-st
logValues.i[0] := batchTarget; // DEBUG ID: a1b2c3d4e5f6
UserLogCustom('debugging', USERLOG_SEVERITY_INFORMATION, 0, 4000, 0, '', 'BATCH_START target=%i', logValues); // DEBUG ID: a1b2c3d4e5f6
```

In `.var` files (Variable declarations):
```iec-st
logValues : UserLogFormatType; (* DEBUG ID: a1b2c3d4e5f6 *)
logStatus : UDINT; (* DEBUG ID: a1b2c3d4e5f6 *)
```

> **CRITICAL**: Never modify an existing line to add debugging — always add new lines. This ensures cleanup only removes what was added.

### Step 1: Add Logging Variables

Add variables **inside an existing `VAR` block** in the task's `.var` file (skip any that already exist). **Tag each new line.**

**Always needed:**
```iec-st
    logStatus : UDINT; (* DEBUG ID: <id> *)
```

**Only if using `UserLogAdvanced` or `UserLogCustom` with format specifiers** (NOT needed for `UserLogBasic`):
```iec-st
    logValues : UserLogFormatType; (* DEBUG ID: <id> *)
```
> ⚠️ `UserLogFormatType` is only available if the UserLog library was installed **from source** (via this skill's bundled library). Binary-only installations do not expose this type. If unavailable, use `UserLogBasic` instead.

**Only in the one task that creates the custom logbook** (Step 2):
```iec-st
    ArEventLogCreate_0 : ArEventLogCreate; (* DEBUG ID: <id> *)
```

> `.var` files support multiple `VAR ... END_VAR` blocks — if no suitable block exists, you may append a new one at the end of the file.

### Step 2: Create the Custom Logbook in INIT

Only one task needs to create a given logbook. **Tag each new line:**

```iec-st
PROGRAM _INIT
    ArEventLogCreate_0.Execute := TRUE; // DEBUG ID: <id>
    ArEventLogCreate_0.Name := 'debugging'; // DEBUG ID: <id>
    ArEventLogCreate_0.Size := 200000; // DEBUG ID: <id>
    ArEventLogCreate_0.Persistence := arEVENTLOG_PERSISTENCE_VOLATILE; // DEBUG ID: <id>
    WHILE NOT ArEventLogCreate_0.Done AND ArEventLogCreate_0.StatusID = 0 DO // DEBUG ID: <id>
        ArEventLogCreate_0(); // DEBUG ID: <id>
    END_WHILE; // DEBUG ID: <id>
    ArEventLogCreate_0.Execute := FALSE; // DEBUG ID: <id>
END_PROGRAM
```

> **Note:** The WHILE loop exits when `Done=TRUE` (success) OR when `StatusID` becomes non-zero (any error, including `arEVENTLOG_ERR_LOGBOOK_EXISTS`). This prevents infinite blocking.

### Step 3: Insert Log Calls

Use `UserLogCustom` to write to the `debugging` logbook. **Tag every line.**

```iec-st
// Simple message
UserLogCustom('debugging', USERLOG_SEVERITY_INFORMATION, 0, 1000, 0, '', 'Machine initialized', logValues); // DEBUG ID: <id>

// Message with integer values
logValues.i[0] := currentState; // DEBUG ID: <id>
logValues.i[1] := errorCode; // DEBUG ID: <id>
UserLogCustom('debugging', USERLOG_SEVERITY_WARNING, 0, 1001, 0, '', 'State=%i error=%i', logValues); // DEBUG ID: <id>

// Message with mixed types
logValues.s[0] := 'Axis1'; // DEBUG ID: <id>
logValues.f[0] := position; // DEBUG ID: <id>
logValues.i[0] := status; // DEBUG ID: <id>
UserLogCustom('debugging', USERLOG_SEVERITY_INFORMATION, 0, 1002, 0, '', '%s pos=%f status=%i', logValues); // DEBUG ID: <id>
```

### Step 4: Build, Deploy, Read Logs

```
1. Build and Transfer (see `as-compile` skill)
2. read_logbook(ip_address="127.0.0.1", logbook="debugging", max_entries=20) via the `as-logbook` MCP server
3. Analyze entries → fix code → repeat from step 1
```

Useful filters:
- `severity: "warning"` — only warnings and errors
- `search: "Axis1"` — text search on message or object name
- `after_time: "2026-03-27T14:30:00"` — only entries after a timestamp

### Step 5: Clean Up Debug Lines

When debugging is complete, remove all tagged lines using the debug line cleanup script (see `as-compile` skill), then rebuild.

## Conventions

- **Event codes 1000-1999**: Agent debug traces (temporary, remove after debugging)
- **Event codes 0-999**: Application events (permanent)
- **Logbook name**: Use `debugging` for agent debug sessions
- **Severity guide**: `SUCCESS` for traces, `INFORMATION` for milestones, `WARNING` for unexpected conditions, `ERROR` for failures
- **One DEBUG ID per session**: All debug lines in a single session share the same ID

## Multi-Task Logging

Multiple tasks can write to the **same** custom logbook — no extra setup needed. Just use `UserLogCustom('debugging', ...)` from any task. The log entry's object field automatically records which task wrote it.

Each task needs its own `logValues` and `logStatus` variables declared in its `.var` file. The logbook creation only needs to happen in **one** task.

## Key Rules

- **Every debug line MUST have a DEBUG ID comment** — enables automated cleanup
- **Never modify existing lines** — only add new lines
- **One DEBUG ID per session** — all debug lines share the same ID
- **Multiple tasks can write to the same logbook** — each needs its own `logValues`/`logStatus` vars
- **Logbook creation only in one task** — other tasks just call `UserLogCustom`
