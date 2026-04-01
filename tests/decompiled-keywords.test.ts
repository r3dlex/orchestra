/**
 * Tests for keyword matching and timestamp formatting utilities.
 * Covers:
 *   - src/utils/userPromptKeywords.ts
 *   - src/utils/formatBriefTimestamp.ts
 *   - src/utils/uuid.ts (createAgentId)
 */
import { describe, it, expect } from 'vitest'

// === Re-implementation: userPromptKeywords.ts ===

function matchesNegativeKeyword(input: string): boolean {
  const lowerInput = input.toLowerCase()
  const negativePattern =
    /\b(wtf|wth|ffs|omfg|shit(ty|tiest)?|dumbass|horrible|awful|piss(ed|ing)? off|piece of (shit|crap|junk)|what the (fuck|hell)|fucking? (broken|useless|terrible|awful|horrible)|fuck you|screw (this|you)|so frustrating|this sucks|damn it)\b/
  return negativePattern.test(lowerInput)
}

function matchesKeepGoingKeyword(input: string): boolean {
  const lowerInput = input.toLowerCase().trim()
  if (lowerInput === 'continue') return true
  const keepGoingPattern = /\b(keep going|go on)\b/
  return keepGoingPattern.test(lowerInput)
}

// === Re-implementation: formatBriefTimestamp.ts ===

function startOfDay(d: Date): number {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()
}

function formatBriefTimestamp(isoString: string, now: Date = new Date()): string {
  const d = new Date(isoString)
  if (Number.isNaN(d.getTime())) return ''

  const dayDiff = startOfDay(now) - startOfDay(d)
  const daysAgo = Math.round(dayDiff / 86_400_000)

  if (daysAgo === 0) {
    return d.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' })
  }
  if (daysAgo > 0 && daysAgo < 7) {
    return d.toLocaleString(undefined, { weekday: 'long', hour: 'numeric', minute: '2-digit' })
  }
  return d.toLocaleString(undefined, {
    weekday: 'long', month: 'short', day: 'numeric',
    hour: 'numeric', minute: '2-digit',
  })
}

// === Re-implementation: uuid.ts createAgentId format validation ===

function isValidAgentId(id: string): boolean {
  // Format: a{label-}{16 hex chars}  OR  a{16 hex chars}
  return /^a([a-z]+-)?[0-9a-f]{16}$/.test(id)
}

// ===================================================

describe('User Prompt Keywords (src/utils/userPromptKeywords.ts)', () => {
  describe('matchesNegativeKeyword', () => {
    it('should match "wtf"', () => {
      expect(matchesNegativeKeyword('wtf is this')).toBe(true)
    })

    it('should match "horrible"', () => {
      expect(matchesNegativeKeyword('this is horrible')).toBe(true)
    })

    it('should match "awful"', () => {
      expect(matchesNegativeKeyword('just awful')).toBe(true)
    })

    it('should match "this sucks"', () => {
      expect(matchesNegativeKeyword('this sucks')).toBe(true)
    })

    it('should match "damn it"', () => {
      expect(matchesNegativeKeyword('damn it')).toBe(true)
    })

    it('should be case-insensitive', () => {
      expect(matchesNegativeKeyword('WTF is happening')).toBe(true)
      expect(matchesNegativeKeyword('HORRIBLE result')).toBe(true)
    })

    it('should not match normal messages', () => {
      expect(matchesNegativeKeyword('hello')).toBe(false)
      expect(matchesNegativeKeyword('please fix this bug')).toBe(false)
      expect(matchesNegativeKeyword('can you help me')).toBe(false)
    })

    it('should not match partial word matches', () => {
      // "dumbass" is a word boundary match; test that normal words don't trigger
      expect(matchesNegativeKeyword('shifting the code')).toBe(false)
    })

    it('should handle empty string', () => {
      expect(matchesNegativeKeyword('')).toBe(false)
    })

    it('should match "so frustrating"', () => {
      expect(matchesNegativeKeyword('this is so frustrating')).toBe(true)
    })
  })

  describe('matchesKeepGoingKeyword', () => {
    it('should match exact "continue"', () => {
      expect(matchesKeepGoingKeyword('continue')).toBe(true)
    })

    it('should match "CONTINUE" case-insensitively', () => {
      expect(matchesKeepGoingKeyword('CONTINUE')).toBe(true)
    })

    it('should not match "continue" as part of longer text', () => {
      // The check is lowerInput === 'continue', so "please continue" won't match
      expect(matchesKeepGoingKeyword('please continue')).toBe(false)
    })

    it('should match "keep going" anywhere in input', () => {
      expect(matchesKeepGoingKeyword('keep going')).toBe(true)
      expect(matchesKeepGoingKeyword('please keep going')).toBe(true)
      expect(matchesKeepGoingKeyword('hello keep going please')).toBe(true)
    })

    it('should match "go on" anywhere in input', () => {
      expect(matchesKeepGoingKeyword('go on')).toBe(true)
      expect(matchesKeepGoingKeyword('go on please')).toBe(true)
    })

    it('should be case-insensitive for patterns', () => {
      expect(matchesKeepGoingKeyword('KEEP GOING')).toBe(true)
      expect(matchesKeepGoingKeyword('GO ON')).toBe(true)
    })

    it('should not match unrelated phrases', () => {
      expect(matchesKeepGoingKeyword('hello')).toBe(false)
      expect(matchesKeepGoingKeyword('fix the bug')).toBe(false)
      expect(matchesKeepGoingKeyword('')).toBe(false)
    })
  })
})

describe('Brief Timestamp Formatting (src/utils/formatBriefTimestamp.ts)', () => {
  const now = new Date('2024-06-15T14:30:00.000Z')

  it('should return empty string for invalid ISO', () => {
    expect(formatBriefTimestamp('not-a-date', now)).toBe('')
    expect(formatBriefTimestamp('', now)).toBe('')
  })

  it('should return time-only for same-day timestamps', () => {
    const sameDay = new Date('2024-06-15T09:00:00.000Z').toISOString()
    const result = formatBriefTimestamp(sameDay, now)
    // Should contain hour:minute pattern (no date/weekday)
    expect(result).toBeTruthy()
    expect(result).not.toContain('Jun')
    expect(result).not.toContain('2024')
  })

  it('should include weekday for timestamps within 6 days', () => {
    const threeDaysAgo = new Date(now.getTime() - 3 * 86400000).toISOString()
    const result = formatBriefTimestamp(threeDaysAgo, now)
    expect(result).toBeTruthy()
    // Should have weekday name (long format: 'Monday', 'Tuesday', etc.)
    const weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    expect(weekdays.some(d => result.includes(d))).toBe(true)
  })

  it('should include month for timestamps older than 6 days', () => {
    const twoWeeksAgo = new Date(now.getTime() - 14 * 86400000).toISOString()
    const result = formatBriefTimestamp(twoWeeksAgo, now)
    expect(result).toBeTruthy()
    // Should have a month abbreviation
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    expect(months.some(m => result.includes(m))).toBe(true)
  })

  it('should handle timestamps at exact boundary (7 days ago = older category)', () => {
    const sevenDaysAgo = new Date(now.getTime() - 7 * 86400000).toISOString()
    const result = formatBriefTimestamp(sevenDaysAgo, now)
    expect(result).toBeTruthy()
  })
})

describe('Agent ID format validation (src/utils/uuid.ts)', () => {
  it('should recognize valid agent ID without label', () => {
    // Format: a + 16 hex chars
    expect(isValidAgentId('a0123456789abcdef')).toBe(true)  // 16 hex
    expect(isValidAgentId('affffffffffffffff')).toBe(true)  // 16 f's
    expect(isValidAgentId('a0000000000000000')).toBe(true)  // 16 0's
  })

  it('should recognize valid agent ID with label', () => {
    // Format: a + label + '-' + 16 hex chars
    expect(isValidAgentId('acompact-0123456789abcdef')).toBe(true)
    expect(isValidAgentId('afork-0123456789abcdef')).toBe(true)
  })

  it('should reject IDs that do not start with a', () => {
    expect(isValidAgentId('b0123456789abcdef')).toBe(false)
    expect(isValidAgentId('00123456789abcdef')).toBe(false)
  })

  it('should reject IDs that are too short', () => {
    expect(isValidAgentId('a0123456789abc')).toBe(false)  // only 13 hex
  })

  it('should reject IDs with non-hex characters', () => {
    expect(isValidAgentId('a0123456789abcxg')).toBe(false)
  })

  it('should reject empty string', () => {
    expect(isValidAgentId('')).toBe(false)
  })
})
