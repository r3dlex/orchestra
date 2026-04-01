# Command System Specification

## Overview

Commands are user-invocable actions triggered by typing `/command-name` in the REPL. Claude Code has ~200+ registered commands spanning built-in operations, skills, plugins, and MCP-provided commands.

## Command Types

### PromptCommand
Sends content to Claude's API for generation.
- `getPromptForCommand()` returns `ContentBlockParam[]`
- Has access to: file system, tools, current messages
- Can specify: `allowedTools`, `model` override, `effort`, `context` (inline vs. fork)

### LocalCommand
Synchronous local execution returning text.
- `call()` executes immediately
- Returns `LocalCommandResult` (text, compact, or skip)

### LocalJSXCommand
Renders React/Ink UI then calls implementation.
- `call()` returns `React.ReactNode`
- Supports UI-driven workflows (dialogs, forms, selections)
- `onDone()` callback controls completion

## Command Properties

```typescript
interface Command {
  name: string;                    // Display name
  description: string;             // Help text
  aliases?: string[];              // Alternative names
  isEnabled?: boolean;             // Can be disabled
  isHidden?: boolean;              // Hidden from command palette
  isImmediate?: boolean;           // Execute without confirmation
  isSensitive?: boolean;           // Requires extra permission
  argDescription?: string;         // Argument help text
  restrictedToAuthTypes?: string[]; // Auth-gated
}
```

## Skill System

Skills are a superset of commands with additional capabilities:
- **Builtin skills** - shipped with Claude Code
- **Bundled skills** - loaded from skill directories
- **Plugin skills** - from installed plugins
- **Forking support** - skills can run in sub-agents with separate context

### Skill Properties
- `paths` - glob patterns for path-based visibility
- `context` - "inline" (same conversation) or "fork" (sub-agent)
- `model` - model override for this skill
- `effort` - computation effort level

## Command Registration Flow

1. `commands.ts` exports `getCommands()` factory
2. Called during `main.tsx` initialization
3. Commands stored in `ToolUseContext.options.commands`
4. UI renders via `UnifiedSuggestions` hook
5. User types `/command-name` to invoke

## Notable Commands

- `/help` - Show help information
- `/bug` - Report a bug
- `/clear` - Clear conversation
- `/commit` - Create git commit
- `/review-pr` - Review a pull request
- `/compact` - Compact conversation history
- `/model` - Switch model
- `/mode` - Change permission mode
- `/config` - View/edit settings
- `/mcp` - Manage MCP servers
- `/plugin` - Manage plugins
- `/agents` - List configured agents
