import { describe, it, expect } from 'vitest'
import fs from 'fs'

describe('SDK Type Definitions (data/package/sdk-tools.d.ts)', () => {
  const content = fs.readFileSync('data/package/sdk-tools.d.ts', 'utf8')

  it('should exist and be non-empty', () => {
    expect(content.length).toBeGreaterThan(0)
  })

  it('should be auto-generated from JSON Schema', () => {
    expect(content).toContain('json-schema-to-typescript')
    expect(content).toContain('DO NOT MODIFY IT BY HAND')
  })

  describe('Tool Input Types', () => {
    const inputTypes = [
      'AgentInput', 'BashInput', 'TaskOutputInput', 'ExitPlanModeInput',
      'FileEditInput', 'FileReadInput', 'FileWriteInput', 'GlobInput',
      'GrepInput', 'TaskStopInput', 'ListMcpResourcesInput', 'McpInput',
      'NotebookEditInput', 'ReadMcpResourceInput', 'TodoWriteInput',
      'WebFetchInput', 'WebSearchInput', 'AskUserQuestionInput',
      'ConfigInput', 'EnterWorktreeInput', 'ExitWorktreeInput',
    ]

    for (const type of inputTypes) {
      it(`should export ${type}`, () => {
        expect(content).toContain(`export interface ${type}`)
      })
    }
  })

  describe('Tool Output Types', () => {
    const outputTypes = [
      'BashOutput', 'ExitPlanModeOutput', 'FileEditOutput',
      'FileWriteOutput', 'GlobOutput', 'GrepOutput', 'TaskStopOutput',
      'NotebookEditOutput', 'TodoWriteOutput', 'WebFetchOutput',
      'AskUserQuestionOutput', 'ConfigOutput',
      'EnterWorktreeOutput', 'ExitWorktreeOutput',
    ]

    for (const type of outputTypes) {
      it(`should export ${type}`, () => {
        expect(content).toContain(`export interface ${type}`)
      })
    }
  })

  describe('Union Types', () => {
    it('should export ToolInputSchemas union', () => {
      expect(content).toContain('export type ToolInputSchemas')
    })

    it('should export ToolOutputSchemas union', () => {
      expect(content).toContain('export type ToolOutputSchemas')
    })

    it('should export AgentOutput as union type', () => {
      expect(content).toContain('export type AgentOutput')
    })

    it('should export FileReadOutput as union type', () => {
      expect(content).toContain('export type FileReadOutput')
    })

    it('should export ListMcpResourcesOutput as array type', () => {
      expect(content).toContain('ListMcpResourcesOutput')
    })
  })

  describe('Key Field Definitions', () => {
    it('BashInput should have command field', () => {
      const bashSection = content.substring(
        content.indexOf('export interface BashInput'),
        content.indexOf('}', content.indexOf('export interface BashInput')) + 1
      )
      expect(bashSection).toContain('command')
    })

    it('BashInput should have timeout and run_in_background', () => {
      expect(content).toContain('timeout?')
      expect(content).toContain('run_in_background?')
    })

    it('FileEditInput should have file_path, old_string, new_string', () => {
      const section = content.substring(
        content.indexOf('export interface FileEditInput'),
        content.indexOf('}', content.indexOf('export interface FileEditInput')) + 1
      )
      expect(section).toContain('file_path')
      expect(section).toContain('old_string')
      expect(section).toContain('new_string')
    })

    it('FileEditInput should have replace_all option', () => {
      const section = content.substring(
        content.indexOf('export interface FileEditInput'),
        content.indexOf('}', content.indexOf('export interface FileEditInput')) + 1
      )
      expect(section).toContain('replace_all?')
    })

    it('AgentInput should have description and prompt', () => {
      const section = content.substring(
        content.indexOf('export interface AgentInput'),
        content.indexOf('}', content.indexOf('export interface AgentInput')) + 1
      )
      expect(section).toContain('description')
      expect(section).toContain('prompt')
    })

    it('AgentInput should support model override options', () => {
      expect(content).toContain('"sonnet"')
      expect(content).toContain('"opus"')
      expect(content).toContain('"haiku"')
    })

    it('AgentInput should support isolation mode', () => {
      expect(content).toContain('"worktree"')
    })

    it('GrepInput should have pattern field', () => {
      const section = content.substring(
        content.indexOf('export interface GrepInput'),
        content.indexOf('}', content.indexOf('export interface GrepInput')) + 1
      )
      expect(section).toContain('pattern')
    })

    it('GrepInput should have output_mode options', () => {
      expect(content).toContain('"content"')
      expect(content).toContain('"files_with_matches"')
      expect(content).toContain('"count"')
    })

    it('FileReadOutput should have type discriminator variants', () => {
      expect(content).toContain('"text"')
      expect(content).toContain('"image"')
      expect(content).toContain('"notebook"')
      expect(content).toContain('"pdf"')
      expect(content).toContain('"file_unchanged"')
    })

    it('BashOutput should have stdout and stderr', () => {
      const section = content.substring(
        content.indexOf('export interface BashOutput'),
        content.indexOf('}', content.indexOf('export interface BashOutput')) + 1
      )
      expect(section).toContain('stdout')
      expect(section).toContain('stderr')
    })

    it('BashOutput should have backgroundTaskId', () => {
      const section = content.substring(
        content.indexOf('export interface BashOutput'),
        content.indexOf('}', content.indexOf('export interface BashOutput')) + 1
      )
      expect(section).toContain('backgroundTaskId?')
    })

    it('TodoWriteInput should have status enum values', () => {
      expect(content).toContain('"pending"')
      expect(content).toContain('"in_progress"')
      expect(content).toContain('"completed"')
    })

    it('EnterWorktreeInput should have optional name', () => {
      const section = content.substring(
        content.indexOf('export interface EnterWorktreeInput'),
        content.indexOf('}', content.indexOf('export interface EnterWorktreeInput')) + 1
      )
      expect(section).toContain('name?')
    })

    it('ExitWorktreeInput should have action field with keep/remove', () => {
      expect(content).toContain('"keep"')
      expect(content).toContain('"remove"')
    })

    it('AgentOutput should have usage with token counts', () => {
      expect(content).toContain('input_tokens')
      expect(content).toContain('output_tokens')
      expect(content).toContain('cache_read_input_tokens')
    })

    it('AgentOutput should have completed and async_launched statuses', () => {
      expect(content).toContain('"completed"')
      expect(content).toContain('"async_launched"')
    })

    it('FileWriteOutput should have type create/update', () => {
      expect(content).toContain('"create"')
      expect(content).toContain('"update"')
    })

    it('NotebookEditInput should have cell types', () => {
      expect(content).toContain('"code"')
      expect(content).toContain('"markdown"')
    })

    it('NotebookEditInput should have edit_mode variants', () => {
      expect(content).toContain('"replace"')
      expect(content).toContain('"insert"')
      expect(content).toContain('"delete"')
    })
  })
})
