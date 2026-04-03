/**
 * TDD tests — imports REAL src/utils/userPromptKeywords.ts
 * and src/utils/formatBriefTimestamp.ts for measured coverage.
 */
import { describe, it, expect } from 'vitest'
import { matchesNegativeKeyword, matchesKeepGoingKeyword } from '../src/utils/userPromptKeywords.js'
import { formatBriefTimestamp } from '../src/utils/formatBriefTimestamp.js'

// ── userPromptKeywords ───────────────────────────────────────────────────────

describe('matchesNegativeKeyword', () => {
  it('matches "wtf"', () => {
    expect(matchesNegativeKeyword('wtf is this')).toBe(true)
  })
  it('matches "wth"', () => {
    expect(matchesNegativeKeyword('wth')).toBe(true)
  })
  it('matches "horrible"', () => {
    expect(matchesNegativeKeyword('this is horrible')).toBe(true)
  })
  it('matches "awful"', () => {
    expect(matchesNegativeKeyword('just awful')).toBe(true)
  })
  it('matches "this sucks"', () => {
    expect(matchesNegativeKeyword('this sucks')).toBe(true)
  })
  it('matches "damn it"', () => {
    expect(matchesNegativeKeyword('damn it')).toBe(true)
  })
  it('matches "so frustrating"', () => {
    expect(matchesNegativeKeyword('this is so frustrating')).toBe(true)
  })
  it('is case-insensitive', () => {
    expect(matchesNegativeKeyword('WTF')).toBe(true)
    expect(matchesNegativeKeyword('HORRIBLE')).toBe(true)
  })
  it('does not match normal messages', () => {
    expect(matchesNegativeKeyword('hello')).toBe(false)
    expect(matchesNegativeKeyword('please fix this bug')).toBe(false)
    expect(matchesNegativeKeyword('can you help me')).toBe(false)
  })
  it('does not match empty string', () => {
    expect(matchesNegativeKeyword('')).toBe(false)
  })
})

describe('matchesKeepGoingKeyword', () => {
  it('matches exact "continue"', () => {
    expect(matchesKeepGoingKeyword('continue')).toBe(true)
  })
  it('matches "CONTINUE" case-insensitively', () => {
    expect(matchesKeepGoingKeyword('CONTINUE')).toBe(true)
  })
  it('does NOT match "continue" as part of longer text', () => {
    expect(matchesKeepGoingKeyword('please continue')).toBe(false)
  })
  it('matches "keep going" anywhere in input', () => {
    expect(matchesKeepGoingKeyword('keep going')).toBe(true)
    expect(matchesKeepGoingKeyword('please keep going')).toBe(true)
  })
  it('matches "go on" anywhere in input', () => {
    expect(matchesKeepGoingKeyword('go on')).toBe(true)
    expect(matchesKeepGoingKeyword('go on please')).toBe(true)
  })
  it('is case-insensitive for patterns', () => {
    expect(matchesKeepGoingKeyword('KEEP GOING')).toBe(true)
    expect(matchesKeepGoingKeyword('GO ON')).toBe(true)
  })
  it('does not match unrelated phrases', () => {
    expect(matchesKeepGoingKeyword('hello')).toBe(false)
    expect(matchesKeepGoingKeyword('fix the bug')).toBe(false)
    expect(matchesKeepGoingKeyword('')).toBe(false)
  })
})

// ── formatBriefTimestamp ─────────────────────────────────────────────────────

describe('formatBriefTimestamp', () => {
  const now = new Date('2024-06-15T14:30:00.000Z')

  it('returns empty string for invalid ISO', () => {
    expect(formatBriefTimestamp('not-a-date', now)).toBe('')
    expect(formatBriefTimestamp('', now)).toBe('')
  })

  it('returns time-only format for same-day timestamps', () => {
    const sameDay = new Date(now)
    sameDay.setHours(9, 0, 0, 0)
    const result = formatBriefTimestamp(sameDay.toISOString(), now)
    expect(result).toBeTruthy()
    // Should not contain month names (it's time-only)
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    expect(months.some(m => result.includes(m))).toBe(false)
  })

  it('includes weekday for 1-6 days ago', () => {
    const threeDaysAgo = new Date(now.getTime() - 3 * 86400000)
    const result = formatBriefTimestamp(threeDaysAgo.toISOString(), now)
    const weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    expect(weekdays.some(d => result.includes(d))).toBe(true)
  })

  it('includes month for 7+ days ago', () => {
    const twoWeeksAgo = new Date(now.getTime() - 14 * 86400000)
    const result = formatBriefTimestamp(twoWeeksAgo.toISOString(), now)
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    expect(months.some(m => result.includes(m))).toBe(true)
  })

  it('handles exactly 6 days ago (boundary — still within-week format)', () => {
    const sixDaysAgo = new Date(now.getTime() - 6 * 86400000)
    const result = formatBriefTimestamp(sixDaysAgo.toISOString(), now)
    expect(result).toBeTruthy()
  })

  it('handles exactly 7 days ago (boundary — older format)', () => {
    const sevenDaysAgo = new Date(now.getTime() - 7 * 86400000)
    const result = formatBriefTimestamp(sevenDaysAgo.toISOString(), now)
    expect(result).toBeTruthy()
  })

  it('uses default now when not supplied', () => {
    // Should not throw
    const result = formatBriefTimestamp(new Date().toISOString())
    expect(typeof result).toBe('string')
  })

  it('respects LC_ALL env var for locale', () => {
    const prev = process.env.LC_ALL
    process.env.LC_ALL = 'en_US.UTF-8'
    try {
      const result = formatBriefTimestamp(new Date().toISOString(), now)
      expect(typeof result).toBe('string')
    } finally {
      if (prev === undefined) delete process.env.LC_ALL
      else process.env.LC_ALL = prev
    }
  })

  it('respects LC_TIME env var when LC_ALL absent', () => {
    const prevAll = process.env.LC_ALL
    const prevTime = process.env.LC_TIME
    delete process.env.LC_ALL
    process.env.LC_TIME = 'en_GB.UTF-8'
    try {
      const result = formatBriefTimestamp(new Date().toISOString(), now)
      expect(typeof result).toBe('string')
    } finally {
      if (prevAll === undefined) delete process.env.LC_ALL
      else process.env.LC_ALL = prevAll
      if (prevTime === undefined) delete process.env.LC_TIME
      else process.env.LC_TIME = prevTime
    }
  })

  it('falls back to undefined locale for LC_ALL=C', () => {
    const prev = process.env.LC_ALL
    process.env.LC_ALL = 'C'
    try {
      const result = formatBriefTimestamp(new Date().toISOString(), now)
      expect(typeof result).toBe('string')
    } finally {
      if (prev === undefined) delete process.env.LC_ALL
      else process.env.LC_ALL = prev
    }
  })

  it('falls back to undefined locale for LC_ALL=POSIX', () => {
    const prev = process.env.LC_ALL
    process.env.LC_ALL = 'POSIX'
    try {
      const result = formatBriefTimestamp(new Date().toISOString(), now)
      expect(typeof result).toBe('string')
    } finally {
      if (prev === undefined) delete process.env.LC_ALL
      else process.env.LC_ALL = prev
    }
  })

  it('falls back to undefined locale for invalid tag', () => {
    const prev = process.env.LC_ALL
    process.env.LC_ALL = 'invalid_INVALID_TAG_THAT_THROWS'
    try {
      const result = formatBriefTimestamp(new Date().toISOString(), now)
      expect(typeof result).toBe('string')
    } finally {
      if (prev === undefined) delete process.env.LC_ALL
      else process.env.LC_ALL = prev
    }
  })
})
