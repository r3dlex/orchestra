# State Management Specification

## AppStateStore

Claude Code uses a single centralized store (Zustand-like pattern) for all application state.

### Store Pattern
- `createStore()` creates a mutable store with immutable snapshots
- All mutations go through state reducers
- State is `DeepImmutable<T>` for React optimization
- Subscribers watch for changes and trigger side effects

### Key State Slices

#### Settings
- Loaded from `~/.claude/settings.json`
- Overridable by: MDM policies, env vars, CLI flags, GrowthBook feature flags
- Change detection for live UI updates

#### Model Selection
- Main loop model + per-session overrides
- Supports: sonnet, opus, haiku variants
- Model aliases and version resolution

#### Permission Context
- Permission mode: default, auto, bypass, plan
- Rules: alwaysAllow, alwaysDeny, alwaysAsk
- Denial tracking with fallback behavior
- Hook-based pre-approval for analyzable patterns

#### Tool Registry
- Active tools list with schemas
- MCP tool connections
- Plugin-provided tools
- Deferred tool resolution

#### Conversation State
- Message history with metadata
- File history snapshots
- Content replacements
- Speculation state (parallel pre-generation)

#### MCP Connections
- Active MCP server list
- Resource discovery results
- Connection health status

#### UI State
- Theme configuration
- Expanded views and selections
- Footer focus state
- Notification queue
- Task list

### Speculation State

Claude Code implements speculative execution:
- Predicts next assistant turn while user types
- Boundaries detect breaks (tool calls, prompts, edits)
- On next input, merges prefetched messages
- Pipelined suggestions allow typing during speculation

### State Subscribers

`onChangeAppState.ts` watches for mutations and triggers:
- Settings persistence to disk
- Tool list refresh
- MCP connection updates
- UI re-renders
