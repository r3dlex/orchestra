/**
 * TDD tests — imports REAL src/utils/intl.ts for measured coverage.
 */
import { describe, it, expect } from 'vitest'
import {
  getGraphemeSegmenter,
  firstGrapheme,
  lastGrapheme,
  getWordSegmenter,
  getRelativeTimeFormat,
  getTimeZone,
  getSystemLocaleLanguage,
} from '../src/utils/intl.js'

describe('getGraphemeSegmenter', () => {
  it('returns an Intl.Segmenter instance', () => {
    const s = getGraphemeSegmenter()
    expect(s).toBeInstanceOf(Intl.Segmenter)
  })
  it('returns the same instance on repeated calls (lazy init caching)', () => {
    expect(getGraphemeSegmenter()).toBe(getGraphemeSegmenter())
  })
  it('segments grapheme granularity', () => {
    const segs = [...getGraphemeSegmenter().segment('hello')]
    expect(segs).toHaveLength(5)
  })
})

describe('firstGrapheme', () => {
  it('returns first letter', () => {
    expect(firstGrapheme('hello')).toBe('h')
  })
  it('returns empty string for empty input', () => {
    expect(firstGrapheme('')).toBe('')
  })
  it('handles emoji as single grapheme', () => {
    const result = firstGrapheme('😀world')
    expect(result).toBe('😀')
  })
  it('handles family emoji cluster', () => {
    const family = '👨‍👩‍👧'
    expect(firstGrapheme(family + 'abc')).toBe(family)
  })
  it('returns only first char for ascii', () => {
    expect(firstGrapheme('abc')).toBe('a')
  })
})

describe('lastGrapheme', () => {
  it('returns last letter', () => {
    expect(lastGrapheme('hello')).toBe('o')
  })
  it('returns empty string for empty input', () => {
    expect(lastGrapheme('')).toBe('')
  })
  it('handles trailing emoji', () => {
    expect(lastGrapheme('hi😀')).toBe('😀')
  })
  it('returns only char for single char', () => {
    expect(lastGrapheme('x')).toBe('x')
  })
})

describe('getWordSegmenter', () => {
  it('returns an Intl.Segmenter instance', () => {
    expect(getWordSegmenter()).toBeInstanceOf(Intl.Segmenter)
  })
  it('returns the same instance (caching)', () => {
    expect(getWordSegmenter()).toBe(getWordSegmenter())
  })
})

describe('getRelativeTimeFormat', () => {
  it('returns an Intl.RelativeTimeFormat', () => {
    const rtf = getRelativeTimeFormat('long', 'always')
    expect(rtf).toBeInstanceOf(Intl.RelativeTimeFormat)
  })
  it('caches by style:numeric key', () => {
    const a = getRelativeTimeFormat('short', 'auto')
    const b = getRelativeTimeFormat('short', 'auto')
    expect(a).toBe(b)
  })
  it('returns different instances for different params', () => {
    const a = getRelativeTimeFormat('long', 'always')
    const b = getRelativeTimeFormat('narrow', 'always')
    expect(a).not.toBe(b)
  })
  it('formats a value correctly', () => {
    const rtf = getRelativeTimeFormat('long', 'always')
    const result = rtf.format(-1, 'day')
    expect(result).toMatch(/1 day ago/)
  })
})

describe('getTimeZone', () => {
  it('returns a non-empty string', () => {
    expect(typeof getTimeZone()).toBe('string')
    expect(getTimeZone().length).toBeGreaterThan(0)
  })
  it('caches the timezone (same value on repeated calls)', () => {
    expect(getTimeZone()).toBe(getTimeZone())
  })
  it('returns an IANA-style timezone', () => {
    // Should be something like 'America/New_York', 'UTC', 'Europe/London', etc.
    expect(getTimeZone()).toMatch(/^[A-Za-z]/)
  })
})

describe('getSystemLocaleLanguage', () => {
  it('returns a string or undefined', () => {
    const lang = getSystemLocaleLanguage()
    expect(lang === undefined || typeof lang === 'string').toBe(true)
  })
  it('returns the same value on repeated calls (caching)', () => {
    expect(getSystemLocaleLanguage()).toBe(getSystemLocaleLanguage())
  })
})
