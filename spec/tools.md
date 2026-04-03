# Tool System Specification

## Overview

Claude Code exposes a set of tools to the language model, each with typed inputs (Zod schemas) and typed outputs. The tool system is the primary mechanism for Claude to interact with the filesystem, shell, web, and user.

## Tool Registry

Tools are constructed by `getTools()` in `tools.ts`, composing:
1. **Builtin tools** - hardcoded in the source
2. **MCP tools** - from connected MCP servers
3. **Plugin tools** - from installed plugins
4. **Synthetic tools** - conditional (e.g., output tool)

## Core Tools

### File Operations
| Tool | Input Type | Output Type | Description |
|------|-----------|-------------|-------------|
| `Read` | `FileReadInput` | `FileReadOutput` | Read files (text, image, PDF, notebook) |
| `Edit` | `FileEditInput` | `FileEditOutput` | Find-and-replace in files |
| `Write` | `FileWriteInput` | `FileWriteOutput` | Create/overwrite files |
| `Glob` | `GlobInput` | `GlobOutput` | Find files by pattern |
| `Grep` | `GrepInput` | `GrepOutput` | Search file contents (ripgrep) |
| `NotebookEdit` | `NotebookEditInput` | `NotebookEditOutput` | Edit Jupyter notebooks |

### Execution
| Tool | Input Type | Output Type | Description |
|------|-----------|-------------|-------------|
| `Bash` | `BashInput` | `BashOutput` | Execute shell commands |
| `Agent` | `AgentInput` | `AgentOutput` | Spawn sub-agents |
| `TaskOutput` | `TaskOutputInput` | N/A | Read background task output |
| `TaskStop` | `TaskStopInput` | `TaskStopOutput` | Stop background tasks |

### Web
| Tool | Input Type | Output Type | Description |
|------|-----------|-------------|-------------|
| `WebFetch` | `WebFetchInput` | `WebFetchOutput` | Fetch and process URLs |
| `WebSearch` | `WebSearchInput` | `WebSearchOutput` | Web search |

### User Interaction
| Tool | Input Type | Output Type | Description |
|------|-----------|-------------|-------------|
| `AskUserQuestion` | `AskUserQuestionInput` | `AskUserQuestionOutput` | Multi-choice questions |
| `TodoWrite` | `TodoWriteInput` | `TodoWriteOutput` | Task list management |

### Planning & Workspace
| Tool | Input Type | Output Type | Description |
|------|-----------|-------------|-------------|
| `ExitPlanMode` | `ExitPlanModeInput` | `ExitPlanModeOutput` | Exit plan mode |
| `EnterWorktree` | `EnterWorktreeInput` | `EnterWorktreeOutput` | Create git worktree |
| `ExitWorktree` | `ExitWorktreeInput` | `ExitWorktreeOutput` | Leave git worktree |

### MCP
| Tool | Input Type | Output Type | Description |
|------|-----------|-------------|-------------|
| `ListMcpResources` | `ListMcpResourcesInput` | `ListMcpResourcesOutput` | List MCP resources |
| `ReadMcpResource` | `ReadMcpResourceInput` | `ReadMcpResourceOutput` | Read MCP resource |
| MCP tools | `McpInput` | `McpOutput` | Dynamic MCP server tools |

### Configuration
| Tool | Input Type | Output Type | Description |
|------|-----------|-------------|-------------|
| `Config` | `ConfigInput` | `ConfigOutput` | Get/set settings |

## Tool Execution Context (ToolUseContext)

Every tool receives a `ToolUseContext` containing:
- `commands` - registered commands
- `tools` - all available tools
- `mcpClients` - MCP server connections
- `messages` - conversation history
- `options` - session options
- `abortController` - cancellation signal
- `canUseTool` - permission checker
- `requestPrompt` - interactive prompt callback
- `notify` - notification system
- File caches and read limits

## Agent Sub-system

The `Agent` tool spawns sub-agents with:
- **Model override**: sonnet, opus, haiku
- **Background execution**: async with output file polling
- **Isolation**: git worktree for safe parallel work
- **Specialized types**: general-purpose, Explore, Plan, etc.

## Output Variants

### FileReadOutput (discriminated union on `type`)
- `"text"` - plain text with line numbers
- `"image"` - base64 encoded image with dimensions
- `"notebook"` - Jupyter notebook cells
- `"pdf"` - base64 encoded PDF
- `"parts"` - extracted PDF page images
- `"file_unchanged"` - file hasn't changed since last read

### AgentOutput (discriminated union on `status`)
- `"completed"` - synchronous result with content and usage
- `"async_launched"` - background task with output file path

## Bash Tool Features
- Sandboxed execution (can be bypassed with `dangerouslyDisableSandbox`)
- Background execution with `run_in_background`
- Timeout support (max 600,000ms = 10 minutes)
- Raw output path for large outputs
- Structured content blocks for rich output
