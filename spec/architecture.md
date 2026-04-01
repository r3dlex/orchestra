# Architecture Overview

## Source Recovery

The published `@anthropic-ai/claude-code` package (v2.1.88) ships as a single bundled `data/package/cli.js` (13MB, 16,667 lines of minified JS) with a 60MB source map (`data/package/cli.js.map`) containing **4,756 embedded source files** (1,902 application `.ts`/`.tsx` files + 2,850 `node_modules` files).

The source map uses **v3 format** with full `sourcesContent`, allowing complete reconstruction of the original TypeScript source tree via:

```js
const map = JSON.parse(fs.readFileSync('data/package/cli.js.map', 'utf8'));
for (let i = 0; i < map.sources.length; i++) {
  const content = map.sourcesContent[i];
  // Write to src/...
}
```

## Bundle Format

- **Runtime**: Node.js >= 18 (ESM, `"type": "module"`)
- **Bundler**: Bun's bundler (inferred from `bun.lock`, build artifacts)
- **Minification**: Variable/function names mangled, but structure preserved
- **Entry point**: `#!/usr/bin/env node` shebang, self-executing

## Module Organization (1,902 src/ files)

| Directory | Files | Purpose |
|-----------|-------|---------|
| `utils/` | 564 | Shared utilities (permissions, config, settings, models, file ops) |
| `components/` | 389 | React/Ink terminal UI components |
| `commands/` | 207 | Slash command implementations (~200+ commands) |
| `tools/` | 184 | Tool implementations (Bash, File ops, Web, Agent, etc.) |
| `services/` | 130 | Business logic (MCP, API, analytics, permissions) |
| `hooks/` | 104 | React hooks for state management and UI behavior |
| `ink/` | 96 | Custom Ink framework (terminal React renderer) |
| `bridge/` | 31 | Remote control / bridge mode |
| `constants/` | 21 | Application constants |
| `skills/` | 20 | Skill system (bundled and plugin skills) |
| `cli/` | 19 | CLI handlers (mcp, plugins, auth, etc.) |
| `keybindings/` | 14 | Keyboard shortcut system |
| `tasks/` | 12 | Background task management |
| `types/` | 11 | Core type definitions |
| `migrations/` | 11 | Settings/data migrations |
| `context/` | 9 | React context providers |
| `entrypoints/` | 8 | Bootstrap entry points |
| `memdir/` | 8 | Memory directory system |
| `state/` | 6 | Global app state (Zustand-like store) |
| `buddy/` | 6 | Buddy/teammate system |
| `vim/` | 5 | Vim mode input handling |
| Others | ~15 | voice, plugins, query, screens, schemas, etc. |

## Entry Point Flow

```
cli.tsx (fast-path dispatch)
  ├── --version → print and exit
  ├── --claude-in-chrome-mcp → Chrome MCP server
  ├── --computer-use-mcp → Computer Use MCP server
  ├── remote-control/bridge → bridge mode
  ├── --tmux + --worktree → tmux worktree fast path
  └── main.tsx (full CLI)
       ├── Parallel prefetch: MDM, keychain, GrowthBook
       ├── Load plugins, skills, MCP clients
       ├── Register tools + commands
       ├── Initialize AppStateStore
       └── Launch REPL (Ink renderer)
            ├── App.tsx (theme, context providers)
            └── REPL.tsx (interactive loop)
                 ├── PromptInput (user input + autocomplete)
                 ├── MessageList (conversation display)
                 └── query.ts (API call loop)
```

## Key Patterns

### Tool System
- Tools are generic with Zod schema validation for inputs
- Each tool has: `call()`, `description()`, `inputSchema`, `inputJSONSchema`
- Tools registered via `getTools()` factory composing: builtins + MCP tools + plugins
- Tool execution receives `ToolUseContext` with full session state

### Command System
- Three types: `PromptCommand` (sends to Claude), `LocalCommand` (runs locally), `LocalJSXCommand` (renders UI)
- Commands support skills (builtin, bundled, plugin)
- Skills can fork into sub-agents with separate context

### Permission System
- Mode-based: default, auto, bypass, plan
- Rule-based: alwaysAllow, alwaysDeny, alwaysAsk
- Interactive permission dialogs for sensitive operations
- Denial tracking with fallback-to-prompting

### State Management
- Single AppStateStore (Zustand-like pattern)
- Immutable state (DeepImmutable<T>) for React optimization
- Tracks: settings, model, permissions, tools, MCP, notifications, tasks, UI state
- Speculation state for parallel query pre-generation

### UI Framework
- Custom Ink implementation (React for terminals)
- Yoga layout engine for CSS-like box model
- Streaming tool output with progress callbacks
- 389 components for full terminal UI
