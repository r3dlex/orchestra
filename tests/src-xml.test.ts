/**
 * TDD tests — imports REAL src/utils/xml.ts for measured coverage.
 */
import { describe, it, expect } from 'vitest'
import { escapeXml, escapeXmlAttr } from '../src/utils/xml.js'

describe('escapeXml', () => {
  it('escapes ampersands', () => {
    expect(escapeXml('a & b')).toBe('a &amp; b')
  })
  it('escapes less-than', () => {
    expect(escapeXml('<tag>')).toBe('&lt;tag&gt;')
  })
  it('escapes greater-than', () => {
    expect(escapeXml('a > b')).toBe('a &gt; b')
  })
  it('escapes multiple special chars', () => {
    expect(escapeXml('<a & b>')).toBe('&lt;a &amp; b&gt;')
  })
  it('does not escape double quotes', () => {
    expect(escapeXml('"hello"')).toBe('"hello"')
  })
  it('does not escape single quotes', () => {
    expect(escapeXml("it's fine")).toBe("it's fine")
  })
  it('handles empty string', () => {
    expect(escapeXml('')).toBe('')
  })
  it('leaves plain text unchanged', () => {
    expect(escapeXml('hello world')).toBe('hello world')
  })
  it('handles multiple ampersands', () => {
    expect(escapeXml('a & b & c')).toBe('a &amp; b &amp; c')
  })
})

describe('escapeXmlAttr', () => {
  it('escapes double quotes', () => {
    expect(escapeXmlAttr('say "hello"')).toBe('say &quot;hello&quot;')
  })
  it('escapes single quotes', () => {
    expect(escapeXmlAttr("it's")).toBe('it&apos;s')
  })
  it('escapes all XML special chars + quotes', () => {
    expect(escapeXmlAttr('<a & "b">')).toBe('&lt;a &amp; &quot;b&quot;&gt;')
  })
  it('handles empty string', () => {
    expect(escapeXmlAttr('')).toBe('')
  })
  it('escapes ampersand before quoting', () => {
    // & must become &amp; not &amp;amp;
    expect(escapeXmlAttr('&"')).toBe('&amp;&quot;')
  })
  it('leaves plain text unchanged', () => {
    expect(escapeXmlAttr('hello')).toBe('hello')
  })
})
