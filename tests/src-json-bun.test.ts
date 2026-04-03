/**
 * Tests for the Bun-specific JSONL path in src/utils/json.ts.
 * Sets globalThis.Bun BEFORE the top-level import so the IIFE picks it up.
 */
import { describe, it, expect, vi } from 'vitest'

vi.mock('../src/utils/slowOperations.js', () => ({
  jsonStringify: JSON.stringify,
  jsonParse: JSON.parse,
  clone: structuredClone,
  cloneDeep: (v: unknown) => JSON.parse(JSON.stringify(v)),
  slowLogging: () => ({ [Symbol.dispose]() {} }),
  SLOW_OPERATION_THRESHOLD_MS: Infinity,
  callerFrame: () => '',
}))

vi.mock('../src/utils/log.js', () => ({
  logError: vi.fn(),
  logForDebugging: vi.fn(),
}))

// Set Bun global BEFORE the module is imported so the IIFE sees it.
type ParseChunkResult = {
  values: unknown[]
  error: null | Error
  read: number
  done: boolean
}

const mockParseChunk = vi.fn(
  (data: string | Buffer, offset = 0): ParseChunkResult => {
    const str =
      typeof data === 'string' ? data.slice(offset) : data.toString('utf8').slice(offset)
    const lines = str.split('\n').filter(l => l.trim())
    const values: unknown[] = []
    for (const line of lines) {
      try {
        values.push(JSON.parse(line))
      } catch {
        /* skip */
      }
    }
    return { values, error: null, read: data.length as number, done: true }
  },
)

;(globalThis as Record<string, unknown>).Bun = {
  JSONL: { parseChunk: mockParseChunk },
}

// Import AFTER Bun global is set
const { parseJSONL } = await import('../src/utils/json.js')

describe('parseJSONL (Bun path — bunJSONLParse truthy)', () => {
  it('parses multiple lines via Bun.JSONL.parseChunk', () => {
    const result = parseJSONL<number>('1\n2\n3')
    expect(result).toEqual([1, 2, 3])
  })

  it('handles parseChunk returning error with partial result (mid-stream error)', () => {
    const data = '1\n2\n3'
    mockParseChunk
      .mockReturnValueOnce({
        values: [1],
        error: new Error('mid parse error'),
        read: 2, // stopped at offset 2 (after "1\n")
        done: false,
      })
      .mockReturnValueOnce({
        values: [2],
        error: null,
        read: data.length,
        done: true,
      })
    const result = parseJSONL<number>(data)
    expect(Array.isArray(result)).toBe(true)
    expect(result).toContain(1)
  })

  it('handles parseChunk with error but read >= data length (treats as done)', () => {
    mockParseChunk.mockReturnValueOnce({
      values: [42],
      error: new Error('at end'),
      read: 99999,
      done: false,
    })
    const result = parseJSONL<number>('42')
    expect(result).toEqual([42])
  })

  it('handles parseChunk with done=true (stops scanning)', () => {
    mockParseChunk.mockReturnValueOnce({
      values: [10, 20],
      error: new Error('done'),
      read: 0,
      done: true,
    })
    const result = parseJSONL<number>('10\n20')
    expect(result).toEqual([10, 20])
  })

  it('handles Buffer input via Bun path', () => {
    mockParseChunk.mockReturnValueOnce({
      values: [{ a: 1 }],
      error: null,
      read: 7,
      done: true,
    })
    const result = parseJSONL<{ a: number }>(Buffer.from('{"a":1}'))
    expect(result).toEqual([{ a: 1 }])
  })
})
