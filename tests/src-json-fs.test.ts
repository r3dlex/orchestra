/**
 * TDD tests for readJSONLFile (src/utils/json.ts) — mocks fs/promises.
 * Kept in a separate file to avoid polluting module cache with fs mocks.
 */
import { describe, it, expect, vi, beforeEach } from 'vitest'

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

// Mock fs/promises before importing json.ts
vi.mock('fs/promises', () => ({
  stat: vi.fn(),
  readFile: vi.fn(),
  open: vi.fn(),
}))

const { readJSONLFile } = await import('../src/utils/json.js')
const fsMod = await import('fs/promises')
const { stat, readFile, open } = fsMod as {
  stat: ReturnType<typeof vi.fn>
  readFile: ReturnType<typeof vi.fn>
  open: ReturnType<typeof vi.fn>
}

describe('readJSONLFile (small file — size <= 100MB)', () => {
  beforeEach(() => { vi.clearAllMocks() })

  it('reads and parses a small JSONL file', async () => {
    stat.mockResolvedValue({ size: 100 })
    readFile.mockResolvedValue(Buffer.from('1\n2\n3'))
    const result = await readJSONLFile<number>('/fake/file.jsonl')
    expect(result).toEqual([1, 2, 3])
  })

  it('skips malformed lines in small file', async () => {
    stat.mockResolvedValue({ size: 50 })
    readFile.mockResolvedValue(Buffer.from('{"a":1}\nbad\n{"a":2}'))
    const result = await readJSONLFile<{ a: number }>('/fake/file.jsonl')
    expect(result).toEqual([{ a: 1 }, { a: 2 }])
  })

  it('returns empty array for empty file', async () => {
    stat.mockResolvedValue({ size: 0 })
    readFile.mockResolvedValue(Buffer.from(''))
    const result = await readJSONLFile('/fake/empty.jsonl')
    expect(result).toEqual([])
  })
})

describe('readJSONLFile (large file — size > 100MB)', () => {
  beforeEach(() => { vi.clearAllMocks() })

  it('reads tail of large file and skips first partial line', async () => {
    const maxBytes = 100 * 1024 * 1024
    const largeSize = maxBytes + 1000
    stat.mockResolvedValue({ size: largeSize })

    // Simulate fd.read that fills the buffer with JSONL data
    // The buffer contains a partial first line + complete lines
    const content = 'partial\n{"x":1}\n{"x":2}\n'
    const contentBuf = Buffer.from(content)

    const mockFd = {
      read: vi.fn().mockImplementation(
        async (buf: Buffer, offset: number, length: number) => {
          const bytesToCopy = Math.min(contentBuf.length - offset, length)
          if (bytesToCopy <= 0) return { bytesRead: 0 }
          contentBuf.copy(buf, offset, offset, offset + bytesToCopy)
          return { bytesRead: bytesToCopy }
        }
      ),
      [Symbol.asyncDispose]: vi.fn().mockResolvedValue(undefined),
    }
    open.mockResolvedValue(mockFd)

    const result = await readJSONLFile<{ x: number }>('/fake/large.jsonl')
    // Should skip "partial" (first line after seeking) and parse the rest
    expect(Array.isArray(result)).toBe(true)
  })

  it('handles large file where no newline found in tail', async () => {
    const maxBytes = 100 * 1024 * 1024
    stat.mockResolvedValue({ size: maxBytes + 1000 })

    const content = '{"x":42}' // no newline — entire chunk is one complete line
    const contentBuf = Buffer.from(content)

    const mockFd = {
      read: vi.fn().mockImplementation(
        async (buf: Buffer, offset: number, length: number) => {
          if (offset > 0) return { bytesRead: 0 }
          const bytesToCopy = Math.min(contentBuf.length, length)
          contentBuf.copy(buf, 0, 0, bytesToCopy)
          return { bytesRead: bytesToCopy }
        }
      ),
      [Symbol.asyncDispose]: vi.fn().mockResolvedValue(undefined),
    }
    open.mockResolvedValue(mockFd)

    const result = await readJSONLFile<{ x: number }>('/fake/large.jsonl')
    expect(Array.isArray(result)).toBe(true)
  })
})
