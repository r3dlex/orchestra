/**
 * TDD tests — imports REAL src/utils/array.ts for measured coverage.
 */
import { describe, it, expect } from 'vitest'
import { intersperse, count, uniq } from '../src/utils/array.js'

describe('intersperse', () => {
  it('inserts separator between all elements', () => {
    expect(intersperse([1, 2, 3], () => 0)).toEqual([1, 0, 2, 0, 3])
  })
  it('passes element index to separator', () => {
    expect(intersperse(['a', 'b', 'c'], i => `|${i}|`)).toEqual(['a', '|1|', 'b', '|2|', 'c'])
  })
  it('returns single element unchanged', () => {
    expect(intersperse(['x'], () => ',')).toEqual(['x'])
  })
  it('returns empty array for empty input', () => {
    expect(intersperse([], () => 0)).toEqual([])
  })
  it('works with two elements', () => {
    expect(intersperse([1, 2], () => 99)).toEqual([1, 99, 2])
  })
})

describe('count', () => {
  it('counts elements matching predicate', () => {
    expect(count([1, 2, 3, 4, 5], x => x > 3)).toBe(2)
  })
  it('returns 0 for empty array', () => {
    expect(count([], () => true)).toBe(0)
  })
  it('returns 0 when nothing matches', () => {
    expect(count([1, 2, 3], x => x > 10)).toBe(0)
  })
  it('counts all when everything matches', () => {
    expect(count([1, 2, 3], () => true)).toBe(3)
  })
  it('treats falsy non-null as 0', () => {
    // +!!false === 0, +!!0 === 0
    expect(count([0, '', false, null, undefined] as unknown[], x => x)).toBe(0)
  })
  it('treats truthy values as 1', () => {
    expect(count([1, 'a', true, {}, []], x => x)).toBe(5)
  })
})

describe('uniq', () => {
  it('removes duplicate numbers', () => {
    expect(uniq([1, 2, 2, 3, 1])).toEqual([1, 2, 3])
  })
  it('returns empty array for empty input', () => {
    expect(uniq([])).toEqual([])
  })
  it('preserves order of first occurrence', () => {
    expect(uniq([3, 1, 2, 1, 3])).toEqual([3, 1, 2])
  })
  it('handles all-unique input', () => {
    expect(uniq([1, 2, 3])).toEqual([1, 2, 3])
  })
  it('works with strings', () => {
    expect(uniq(['a', 'b', 'a'])).toEqual(['a', 'b'])
  })
  it('accepts any Iterable (e.g. Set)', () => {
    expect(uniq(new Set([1, 2, 3]))).toEqual([1, 2, 3])
  })
})
