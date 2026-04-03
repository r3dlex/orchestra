/**
 * TDD tests — imports REAL src/utils/uuid.ts for measured coverage.
 */
import { describe, it, expect } from 'vitest'
import { validateUuid, createAgentId } from '../src/utils/uuid.js'

describe('validateUuid', () => {
  it('accepts valid lowercase UUID', () => {
    const u = '550e8400-e29b-41d4-a716-446655440000'
    expect(validateUuid(u)).toBe(u)
  })
  it('accepts valid uppercase UUID', () => {
    const u = '550E8400-E29B-41D4-A716-446655440000'
    expect(validateUuid(u)).toBe(u)
  })
  it('accepts mixed-case UUID', () => {
    const u = '550e8400-E29B-41d4-a716-446655440000'
    expect(validateUuid(u)).toBe(u)
  })
  it('rejects non-string', () => {
    expect(validateUuid(123)).toBe(null)
    expect(validateUuid(null)).toBe(null)
    expect(validateUuid(undefined)).toBe(null)
    expect(validateUuid({})).toBe(null)
  })
  it('rejects wrong segment count', () => {
    expect(validateUuid('550e8400-e29b-41d4-a716')).toBe(null)
  })
  it('rejects too-short last segment', () => {
    expect(validateUuid('550e8400-e29b-41d4-a716-44665544000')).toBe(null)
  })
  it('rejects too-long last segment', () => {
    expect(validateUuid('550e8400-e29b-41d4-a716-4466554400000')).toBe(null)
  })
  it('rejects non-hex characters', () => {
    expect(validateUuid('550e8400-e29b-41d4-a716-44665544000g')).toBe(null)
  })
  it('rejects empty string', () => {
    expect(validateUuid('')).toBe(null)
  })
})

describe('createAgentId', () => {
  it('generates id starting with "a"', () => {
    expect(createAgentId().startsWith('a')).toBe(true)
  })
  it('generates id with 16 hex chars after "a" (no label)', () => {
    const id = createAgentId()
    expect(/^a[0-9a-f]{16}$/.test(id)).toBe(true)
  })
  it('includes label when provided', () => {
    const id = createAgentId('compact')
    expect(id.startsWith('acompact-')).toBe(true)
  })
  it('has 16 hex chars after "label-" when label provided', () => {
    const id = createAgentId('fork')
    expect(/^afork-[0-9a-f]{16}$/.test(id)).toBe(true)
  })
  it('generates different ids each call', () => {
    const ids = new Set(Array.from({ length: 10 }, () => createAgentId()))
    expect(ids.size).toBe(10)
  })
})
