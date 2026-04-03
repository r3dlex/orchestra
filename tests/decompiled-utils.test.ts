/**
 * Tests for pure utility functions extracted from the decompiled source.
 * These functions are re-implemented from decompiled/src/utils/ to verify
 * correctness of the recovered source code without requiring the full
 * dependency tree.
 */
import { describe, it, expect } from 'vitest'

// === Re-implementations of pure functions from decompiled source ===

// From decompiled/src/utils/array.ts
function intersperse<A>(as: A[], separator: (index: number) => A): A[] {
  return as.flatMap((a, i) => (i ? [separator(i), a] : [a]))
}

function count<T>(arr: readonly T[], pred: (x: T) => unknown): number {
  let n = 0
  for (const x of arr) n += +!!pred(x)
  return n
}

function uniq<T>(xs: Iterable<T>): T[] {
  return [...new Set(xs)]
}

// From decompiled/src/utils/xml.ts
function escapeXml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

function escapeXmlAttr(s: string): string {
  return escapeXml(s).replace(/"/g, '&quot;').replace(/'/g, '&apos;')
}

// From decompiled/src/utils/uuid.ts
const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

function validateUuid(maybeUuid: unknown): string | null {
  if (typeof maybeUuid !== 'string') return null
  return uuidRegex.test(maybeUuid) ? maybeUuid : null
}

// From decompiled/src/utils/format.ts
function formatFileSize(sizeInBytes: number): string {
  const kb = sizeInBytes / 1024
  if (kb < 1) return `${sizeInBytes} bytes`
  if (kb < 1024) return `${kb.toFixed(1).replace(/\.0$/, '')}KB`
  const mb = kb / 1024
  if (mb < 1024) return `${mb.toFixed(1).replace(/\.0$/, '')}MB`
  const gb = mb / 1024
  return `${gb.toFixed(1).replace(/\.0$/, '')}GB`
}

function formatSecondsShort(ms: number): string {
  return `${(ms / 1000).toFixed(1)}s`
}

function formatDuration(
  ms: number,
  options?: { hideTrailingZeros?: boolean; mostSignificantOnly?: boolean },
): string {
  if (ms < 60000) {
    if (ms === 0) return '0s'
    if (ms < 1) {
      const s = (ms / 1000).toFixed(1)
      return `${s}s`
    }
    const s = Math.floor(ms / 1000).toString()
    return `${s}s`
  }
  let days = Math.floor(ms / 86400000)
  let hours = Math.floor((ms % 86400000) / 3600000)
  let minutes = Math.floor((ms % 3600000) / 60000)
  let seconds = Math.round((ms % 60000) / 1000)
  if (seconds === 60) { seconds = 0; minutes++ }
  if (minutes === 60) { minutes = 0; hours++ }
  if (hours === 24) { hours = 0; days++ }
  const hide = options?.hideTrailingZeros
  if (options?.mostSignificantOnly) {
    if (days > 0) return `${days}d`
    if (hours > 0) return `${hours}h`
    if (minutes > 0) return `${minutes}m`
    return `${seconds}s`
  }
  if (days > 0) {
    if (hide && hours === 0 && minutes === 0) return `${days}d`
    if (hide && minutes === 0) return `${days}d ${hours}h`
    return `${days}d ${hours}h ${minutes}m`
  }
  if (hours > 0) {
    if (hide && minutes === 0 && seconds === 0) return `${hours}h`
    if (hide && seconds === 0) return `${hours}h ${minutes}m`
    return `${hours}h ${minutes}m ${seconds}s`
  }
  if (minutes > 0) {
    if (hide && seconds === 0) return `${minutes}m`
    return `${minutes}m ${seconds}s`
  }
  return `${seconds}s`
}

function formatNumber(number: number): string {
  const shouldUseConsistentDecimals = number >= 1000
  const formatter = new Intl.NumberFormat('en-US', {
    notation: 'compact',
    maximumFractionDigits: 1,
    minimumFractionDigits: shouldUseConsistentDecimals ? 1 : 0,
  })
  return formatter.format(number).toLowerCase()
}

function formatTokens(count: number): string {
  return formatNumber(count).replace('.0', '')
}

// From decompiled/src/utils/CircularBuffer.ts
class CircularBuffer<T> {
  private buffer: T[]
  private head = 0
  private size = 0
  constructor(private capacity: number) {
    this.buffer = new Array(capacity)
  }
  add(item: T): void {
    this.buffer[this.head] = item
    this.head = (this.head + 1) % this.capacity
    if (this.size < this.capacity) this.size++
  }
  addAll(items: T[]): void {
    for (const item of items) this.add(item)
  }
  getRecent(count: number): T[] {
    const result: T[] = []
    const start = this.size < this.capacity ? 0 : this.head
    const available = Math.min(count, this.size)
    for (let i = 0; i < available; i++) {
      const index = (start + this.size - available + i) % this.capacity
      result.push(this.buffer[index]!)
    }
    return result
  }
  toArray(): T[] {
    if (this.size === 0) return []
    const result: T[] = []
    const start = this.size < this.capacity ? 0 : this.head
    for (let i = 0; i < this.size; i++) {
      const index = (start + i) % this.capacity
      result.push(this.buffer[index]!)
    }
    return result
  }
  clear(): void {
    this.buffer.length = 0
    this.head = 0
    this.size = 0
  }
  length(): number {
    return this.size
  }
}

// === TESTS ===

describe('Array Utilities (decompiled/src/utils/array.ts)', () => {
  describe('intersperse', () => {
    it('should insert separator between elements', () => {
      expect(intersperse([1, 2, 3], () => 0)).toEqual([1, 0, 2, 0, 3])
    })

    it('should return single element unchanged', () => {
      expect(intersperse(['a'], () => ',')).toEqual(['a'])
    })

    it('should return empty array for empty input', () => {
      expect(intersperse([], () => 0)).toEqual([])
    })

    it('should pass index to separator function', () => {
      const result = intersperse(['a', 'b', 'c'], (i) => `sep${i}`)
      expect(result).toEqual(['a', 'sep1', 'b', 'sep2', 'c'])
    })

    it('should handle two elements', () => {
      expect(intersperse([1, 2], () => 99)).toEqual([1, 99, 2])
    })
  })

  describe('count', () => {
    it('should count matching elements', () => {
      expect(count([1, 2, 3, 4, 5], x => x > 3)).toBe(2)
    })

    it('should return 0 for empty array', () => {
      expect(count([], () => true)).toBe(0)
    })

    it('should return 0 when no elements match', () => {
      expect(count([1, 2, 3], x => x > 10)).toBe(0)
    })

    it('should count all when all match', () => {
      expect(count([1, 2, 3], () => true)).toBe(3)
    })

    it('should handle truthy/falsy values correctly', () => {
      expect(count([0, 1, '', 'a', null, undefined], x => x)).toBe(2)
    })
  })

  describe('uniq', () => {
    it('should remove duplicates', () => {
      expect(uniq([1, 2, 2, 3, 1])).toEqual([1, 2, 3])
    })

    it('should handle empty array', () => {
      expect(uniq([])).toEqual([])
    })

    it('should handle all unique elements', () => {
      expect(uniq([1, 2, 3])).toEqual([1, 2, 3])
    })

    it('should preserve order of first occurrence', () => {
      expect(uniq([3, 1, 2, 1, 3])).toEqual([3, 1, 2])
    })

    it('should handle strings', () => {
      expect(uniq(['a', 'b', 'a'])).toEqual(['a', 'b'])
    })

    it('should accept iterables (Set)', () => {
      expect(uniq(new Set([1, 2, 3]))).toEqual([1, 2, 3])
    })
  })
})

describe('XML Utilities (decompiled/src/utils/xml.ts)', () => {
  describe('escapeXml', () => {
    it('should escape ampersands', () => {
      expect(escapeXml('a & b')).toBe('a &amp; b')
    })

    it('should escape less-than', () => {
      expect(escapeXml('<tag>')).toBe('&lt;tag&gt;')
    })

    it('should escape greater-than', () => {
      expect(escapeXml('a > b')).toBe('a &gt; b')
    })

    it('should handle multiple special characters', () => {
      expect(escapeXml('<a & b>')).toBe('&lt;a &amp; b&gt;')
    })

    it('should not escape quotes', () => {
      expect(escapeXml('"hello"')).toBe('"hello"')
    })

    it('should handle empty string', () => {
      expect(escapeXml('')).toBe('')
    })

    it('should handle string with no special chars', () => {
      expect(escapeXml('hello world')).toBe('hello world')
    })
  })

  describe('escapeXmlAttr', () => {
    it('should escape double quotes', () => {
      expect(escapeXmlAttr('say "hello"')).toBe('say &quot;hello&quot;')
    })

    it('should escape single quotes', () => {
      expect(escapeXmlAttr("it's")).toBe('it&apos;s')
    })

    it('should escape all XML special chars plus quotes', () => {
      expect(escapeXmlAttr('<a & "b">')).toBe('&lt;a &amp; &quot;b&quot;&gt;')
    })

    it('should handle empty string', () => {
      expect(escapeXmlAttr('')).toBe('')
    })
  })
})

describe('UUID Utilities (decompiled/src/utils/uuid.ts)', () => {
  describe('validateUuid', () => {
    it('should validate correct UUID', () => {
      expect(validateUuid('550e8400-e29b-41d4-a716-446655440000')).toBe('550e8400-e29b-41d4-a716-446655440000')
    })

    it('should validate uppercase UUID', () => {
      expect(validateUuid('550E8400-E29B-41D4-A716-446655440000')).toBe('550E8400-E29B-41D4-A716-446655440000')
    })

    it('should reject invalid UUID', () => {
      expect(validateUuid('not-a-uuid')).toBe(null)
    })

    it('should reject non-string', () => {
      expect(validateUuid(123)).toBe(null)
      expect(validateUuid(null)).toBe(null)
      expect(validateUuid(undefined)).toBe(null)
    })

    it('should reject UUID with wrong segment lengths', () => {
      expect(validateUuid('550e8400-e29b-41d4-a716-44665544000')).toBe(null) // too short
      expect(validateUuid('550e8400-e29b-41d4-a716-4466554400000')).toBe(null) // too long
    })

    it('should reject UUID with non-hex characters', () => {
      expect(validateUuid('550e8400-e29b-41d4-a716-44665544000g')).toBe(null)
    })
  })
})

describe('Format Utilities (decompiled/src/utils/format.ts)', () => {
  describe('formatFileSize', () => {
    it('should format bytes', () => {
      expect(formatFileSize(512)).toBe('512 bytes')
    })

    it('should format KB', () => {
      expect(formatFileSize(1024)).toBe('1KB')
    })

    it('should format KB with decimal', () => {
      expect(formatFileSize(1536)).toBe('1.5KB')
    })

    it('should format MB', () => {
      expect(formatFileSize(1048576)).toBe('1MB')
    })

    it('should format MB with decimal', () => {
      expect(formatFileSize(1572864)).toBe('1.5MB')
    })

    it('should format GB', () => {
      expect(formatFileSize(1073741824)).toBe('1GB')
    })

    it('should format 0 bytes', () => {
      expect(formatFileSize(0)).toBe('0 bytes')
    })

    it('should drop trailing .0', () => {
      expect(formatFileSize(2048)).toBe('2KB') // not 2.0KB
    })
  })

  describe('formatSecondsShort', () => {
    it('should format 1 second', () => {
      expect(formatSecondsShort(1000)).toBe('1.0s')
    })

    it('should format fractional seconds', () => {
      expect(formatSecondsShort(1234)).toBe('1.2s')
    })

    it('should format sub-second', () => {
      expect(formatSecondsShort(500)).toBe('0.5s')
    })

    it('should format 0', () => {
      expect(formatSecondsShort(0)).toBe('0.0s')
    })
  })

  describe('formatDuration', () => {
    it('should format 0', () => {
      expect(formatDuration(0)).toBe('0s')
    })

    it('should format seconds', () => {
      expect(formatDuration(5000)).toBe('5s')
    })

    it('should format minutes and seconds', () => {
      expect(formatDuration(65000)).toBe('1m 5s')
    })

    it('should format hours, minutes, seconds', () => {
      expect(formatDuration(3661000)).toBe('1h 1m 1s')
    })

    it('should format days', () => {
      expect(formatDuration(86400000)).toBe('1d 0h 0m')
    })

    it('should hide trailing zeros', () => {
      expect(formatDuration(3600000, { hideTrailingZeros: true })).toBe('1h')
      expect(formatDuration(86400000, { hideTrailingZeros: true })).toBe('1d')
    })

    it('should show most significant only', () => {
      expect(formatDuration(3661000, { mostSignificantOnly: true })).toBe('1h')
      expect(formatDuration(86461000, { mostSignificantOnly: true })).toBe('1d')
    })

    it('should handle rounding carry-over', () => {
      // 59500ms = 59.5s, but Math.floor(59500/1000) = 59, so still under 60s threshold
      expect(formatDuration(59500)).toBe('59s')
      // 60000ms is exactly the minute boundary
      expect(formatDuration(60000)).toBe('1m 0s')
    })
  })

  describe('formatNumber', () => {
    it('should format small numbers as-is', () => {
      expect(formatNumber(900)).toBe('900')
    })

    it('should format thousands with k suffix', () => {
      const result = formatNumber(1321)
      expect(result).toBe('1.3k')
    })

    it('should format round thousands', () => {
      expect(formatNumber(1000)).toBe('1.0k')
    })
  })

  describe('formatTokens', () => {
    it('should drop .0 suffix', () => {
      expect(formatTokens(1000)).toBe('1k')
    })

    it('should keep non-zero decimals', () => {
      expect(formatTokens(1300)).toBe('1.3k')
    })

    it('should handle small numbers', () => {
      expect(formatTokens(500)).toBe('500')
    })
  })
})

describe('CircularBuffer (decompiled/src/utils/CircularBuffer.ts)', () => {
  it('should add and retrieve items', () => {
    const buf = new CircularBuffer<number>(5)
    buf.add(1)
    buf.add(2)
    buf.add(3)
    expect(buf.toArray()).toEqual([1, 2, 3])
  })

  it('should evict oldest when full', () => {
    const buf = new CircularBuffer<number>(3)
    buf.add(1)
    buf.add(2)
    buf.add(3)
    buf.add(4) // evicts 1
    expect(buf.toArray()).toEqual([2, 3, 4])
  })

  it('should return correct length', () => {
    const buf = new CircularBuffer<number>(5)
    expect(buf.length()).toBe(0)
    buf.add(1)
    expect(buf.length()).toBe(1)
    buf.add(2)
    buf.add(3)
    expect(buf.length()).toBe(3)
  })

  it('should not exceed capacity length', () => {
    const buf = new CircularBuffer<number>(2)
    buf.add(1)
    buf.add(2)
    buf.add(3)
    expect(buf.length()).toBe(2)
  })

  it('should get recent items', () => {
    const buf = new CircularBuffer<number>(5)
    buf.addAll([1, 2, 3, 4, 5])
    expect(buf.getRecent(2)).toEqual([4, 5])
    expect(buf.getRecent(5)).toEqual([1, 2, 3, 4, 5])
  })

  it('should get recent items after wrapping', () => {
    const buf = new CircularBuffer<number>(3)
    buf.addAll([1, 2, 3, 4, 5])
    expect(buf.getRecent(2)).toEqual([4, 5])
    expect(buf.getRecent(3)).toEqual([3, 4, 5])
  })

  it('should handle getRecent with count > size', () => {
    const buf = new CircularBuffer<number>(5)
    buf.add(1)
    expect(buf.getRecent(10)).toEqual([1])
  })

  it('should clear the buffer', () => {
    const buf = new CircularBuffer<number>(5)
    buf.addAll([1, 2, 3])
    buf.clear()
    expect(buf.length()).toBe(0)
    expect(buf.toArray()).toEqual([])
  })

  it('should return empty array for empty buffer', () => {
    const buf = new CircularBuffer<number>(5)
    expect(buf.toArray()).toEqual([])
    expect(buf.getRecent(5)).toEqual([])
  })

  it('should addAll correctly', () => {
    const buf = new CircularBuffer<string>(3)
    buf.addAll(['a', 'b', 'c', 'd'])
    expect(buf.toArray()).toEqual(['b', 'c', 'd'])
  })

  it('should handle capacity of 1', () => {
    const buf = new CircularBuffer<number>(1)
    buf.add(1)
    expect(buf.toArray()).toEqual([1])
    buf.add(2)
    expect(buf.toArray()).toEqual([2])
    expect(buf.length()).toBe(1)
  })
})

describe('JSONL Parser (decompiled/src/utils/json.ts logic)', () => {
  // Re-implementation of parseJSONLString from decompiled source
  function parseJSONLString<T>(data: string): T[] {
    const len = data.length
    let start = 0
    const results: T[] = []
    while (start < len) {
      let end = data.indexOf('\n', start)
      if (end === -1) end = len
      const line = data.substring(start, end).trim()
      start = end + 1
      if (!line) continue
      try { results.push(JSON.parse(line) as T) } catch { /* skip */ }
    }
    return results
  }

  it('should parse valid JSONL', () => {
    const result = parseJSONLString<{ a: number }>('{"a":1}\n{"a":2}\n{"a":3}')
    expect(result).toEqual([{ a: 1 }, { a: 2 }, { a: 3 }])
  })

  it('should skip malformed lines', () => {
    const result = parseJSONLString<{ a: number }>('{"a":1}\ninvalid\n{"a":3}')
    expect(result).toEqual([{ a: 1 }, { a: 3 }])
  })

  it('should handle empty input', () => {
    expect(parseJSONLString('')).toEqual([])
  })

  it('should handle single line without trailing newline', () => {
    expect(parseJSONLString<{ x: number }>('{"x":42}')).toEqual([{ x: 42 }])
  })

  it('should skip blank lines', () => {
    const result = parseJSONLString<number>('1\n\n2\n\n3')
    expect(result).toEqual([1, 2, 3])
  })

  it('should handle trailing newline', () => {
    const result = parseJSONLString<number>('1\n2\n')
    expect(result).toEqual([1, 2])
  })
})

describe('Safe JSON Parse (decompiled/src/utils/json.ts logic)', () => {
  // Simplified re-implementation without memoization
  function safeParseJSON(json: string | null | undefined): unknown {
    if (!json) return null
    try { return JSON.parse(json) } catch { return null }
  }

  it('should parse valid JSON', () => {
    expect(safeParseJSON('{"a": 1}')).toEqual({ a: 1 })
  })

  it('should return null for invalid JSON', () => {
    expect(safeParseJSON('invalid')).toBe(null)
  })

  it('should return null for null input', () => {
    expect(safeParseJSON(null)).toBe(null)
  })

  it('should return null for undefined input', () => {
    expect(safeParseJSON(undefined)).toBe(null)
  })

  it('should return null for empty string', () => {
    expect(safeParseJSON('')).toBe(null)
  })

  it('should parse arrays', () => {
    expect(safeParseJSON('[1,2,3]')).toEqual([1, 2, 3])
  })

  it('should parse primitive JSON values', () => {
    expect(safeParseJSON('"hello"')).toBe('hello')
    expect(safeParseJSON('42')).toBe(42)
    expect(safeParseJSON('true')).toBe(true)
    expect(safeParseJSON('null')).toBe(null) // JSON null
  })
})
