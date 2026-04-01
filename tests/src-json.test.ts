/**
 * TDD tests — imports REAL src/utils/json.ts and src/utils/jsonRead.ts.
 * Stubs bun:bundle transitive deps.
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

const { safeParseJSON, safeParseJSONC, parseJSONL, addItemToJSONCArray } = await import('../src/utils/json.js')
const { stripBOM } = await import('../src/utils/jsonRead.js')

describe('safeParseJSON', () => {
  it('parses valid JSON object', () => {
    expect(safeParseJSON('{"a":1}')).toEqual({ a: 1 })
  })
  it('parses array', () => {
    expect(safeParseJSON('[1,2,3]')).toEqual([1, 2, 3])
  })
  it('parses string value', () => {
    expect(safeParseJSON('"hello"')).toBe('hello')
  })
  it('parses number', () => {
    expect(safeParseJSON('42')).toBe(42)
  })
  it('parses boolean', () => {
    expect(safeParseJSON('true')).toBe(true)
  })
  it('returns null for invalid JSON', () => {
    expect(safeParseJSON('invalid', false)).toBe(null)
  })
  it('returns null for null input', () => {
    expect(safeParseJSON(null)).toBe(null)
  })
  it('returns null for undefined input', () => {
    expect(safeParseJSON(undefined)).toBe(null)
  })
  it('returns null for empty string', () => {
    expect(safeParseJSON('')).toBe(null)
  })
  it('caches result (LRU cache)', () => {
    // Calling twice with same input should use cache
    const json = '{"cached":true}'
    expect(safeParseJSON(json)).toEqual({ cached: true })
    expect(safeParseJSON(json)).toEqual({ cached: true })
  })
  it('strips BOM before parsing', () => {
    const withBOM = '\uFEFF{"a":1}'
    expect(safeParseJSON(withBOM)).toEqual({ a: 1 })
  })
  it('parses JSON null correctly', () => {
    // JSON.parse("null") === null — still returns null via the ok:true path
    expect(safeParseJSON('null')).toBe(null)
  })
})

describe('safeParseJSONC', () => {
  it('parses standard JSON', () => {
    expect(safeParseJSONC('{"a":1}')).toEqual({ a: 1 })
  })
  it('parses JSON with line comments', () => {
    expect(safeParseJSONC('{"a":1 // comment\n}')).toEqual({ a: 1 })
  })
  it('parses JSON with block comments', () => {
    expect(safeParseJSONC('{"a":1 /* block */}')).toEqual({ a: 1 })
  })
  it('returns null for null input', () => {
    expect(safeParseJSONC(null)).toBe(null)
  })
  it('returns null for undefined input', () => {
    expect(safeParseJSONC(undefined)).toBe(null)
  })
  it('returns null for empty string', () => {
    expect(safeParseJSONC('')).toBe(null)
  })
  it('strips BOM before parsing', () => {
    expect(safeParseJSONC('\uFEFF{"b":2}')).toEqual({ b: 2 })
  })
})

describe('parseJSONL (string path)', () => {
  it('parses multiple JSON lines', () => {
    expect(parseJSONL<number>('1\n2\n3')).toEqual([1, 2, 3])
  })
  it('skips malformed lines', () => {
    expect(parseJSONL<number>('1\nbad\n3')).toEqual([1, 3])
  })
  it('handles empty input', () => {
    expect(parseJSONL('')).toEqual([])
  })
  it('handles trailing newline', () => {
    expect(parseJSONL<number>('1\n2\n')).toEqual([1, 2])
  })
  it('skips blank lines', () => {
    expect(parseJSONL<number>('1\n\n2')).toEqual([1, 2])
  })
  it('handles single line without newline', () => {
    expect(parseJSONL<{ x: number }>('{"x":42}')).toEqual([{ x: 42 }])
  })
  it('parses objects', () => {
    const result = parseJSONL<{ a: number }>('{"a":1}\n{"a":2}')
    expect(result).toEqual([{ a: 1 }, { a: 2 }])
  })
})

describe('safeParseJSON (large input > 8KB — bypasses LRU)', () => {
  it('parses large JSON bypassing cache', () => {
    const large = JSON.stringify({ data: 'x'.repeat(9000) })
    const result = safeParseJSON(large)
    expect((result as Record<string, unknown>).data).toBe('x'.repeat(9000))
  })
  it('returns null for large invalid JSON', () => {
    const large = 'invalid' + 'x'.repeat(9000)
    expect(safeParseJSON(large, false)).toBe(null)
  })
})

describe('addItemToJSONCArray', () => {
  it('creates new array for empty content', () => {
    const result = addItemToJSONCArray('', 'item1')
    expect(JSON.parse(result)).toEqual(['item1'])
  })
  it('creates new array for whitespace content', () => {
    const result = addItemToJSONCArray('   ', 'item1')
    expect(JSON.parse(result)).toEqual(['item1'])
  })
  it('appends to existing array', () => {
    const result = addItemToJSONCArray('["a","b"]', 'c')
    expect(JSON.parse(result)).toEqual(['a', 'b', 'c'])
  })
  it('adds first item to empty array', () => {
    const result = addItemToJSONCArray('[]', 'first')
    expect(JSON.parse(result)).toEqual(['first'])
  })
  it('preserves existing items', () => {
    const result = addItemToJSONCArray('[1,2,3]', 4)
    expect(JSON.parse(result)).toEqual([1, 2, 3, 4])
  })
  it('replaces non-array content with single-item array', () => {
    const result = addItemToJSONCArray('{"not":"array"}', 'item')
    expect(JSON.parse(result)).toEqual(['item'])
  })
  it('handles BOM in content', () => {
    const result = addItemToJSONCArray('\uFEFF["x"]', 'y')
    expect(JSON.parse(result)).toEqual(['x', 'y'])
  })
  it('falls back to new array on parse error', () => {
    const result = addItemToJSONCArray('definitely not json!!!', 'item')
    expect(JSON.parse(result)).toEqual(['item'])
  })
  it('handles object items', () => {
    const result = addItemToJSONCArray('[{"a":1}]', { b: 2 })
    expect(JSON.parse(result)).toEqual([{ a: 1 }, { b: 2 }])
  })
})

describe('parseJSONL (Buffer path)', () => {
  it('parses buffer with multiple lines', () => {
    const buf = Buffer.from('1\n2\n3')
    const result = parseJSONL<number>(buf)
    expect(result).toEqual([1, 2, 3])
  })
  it('skips malformed lines in buffer', () => {
    const buf = Buffer.from('1\nbad\n3')
    const result = parseJSONL<number>(buf)
    expect(result).toEqual([1, 3])
  })
  it('strips BOM from buffer', () => {
    const bom = Buffer.from([0xef, 0xbb, 0xbf])
    const data = Buffer.from('{"x":1}\n{"x":2}')
    const buf = Buffer.concat([bom, data])
    const result = parseJSONL<{ x: number }>(buf)
    expect(result).toEqual([{ x: 1 }, { x: 2 }])
  })
  it('handles empty buffer', () => {
    expect(parseJSONL(Buffer.from(''))).toEqual([])
  })
  it('handles buffer with no trailing newline', () => {
    const buf = Buffer.from('42')
    expect(parseJSONL<number>(buf)).toEqual([42])
  })
})

describe('stripBOM (jsonRead.ts)', () => {
  it('strips UTF-8 BOM from start', () => {
    expect(stripBOM('\uFEFFhello')).toBe('hello')
  })
  it('leaves strings without BOM unchanged', () => {
    expect(stripBOM('hello')).toBe('hello')
  })
  it('handles empty string', () => {
    expect(stripBOM('')).toBe('')
  })
  it('only strips leading BOM, not interior', () => {
    expect(stripBOM('a\uFEFFb')).toBe('a\uFEFFb')
  })
})
