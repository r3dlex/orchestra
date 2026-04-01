/**
 * TDD tests — imports REAL src/utils/CircularBuffer.ts for measured coverage.
 */
import { describe, it, expect } from 'vitest'
import { CircularBuffer } from '../src/utils/CircularBuffer.js'

describe('CircularBuffer', () => {
  describe('add / length / toArray', () => {
    it('stores items in order', () => {
      const b = new CircularBuffer<number>(5)
      b.add(1); b.add(2); b.add(3)
      expect(b.toArray()).toEqual([1, 2, 3])
    })
    it('tracks length accurately', () => {
      const b = new CircularBuffer<number>(5)
      expect(b.length()).toBe(0)
      b.add(1)
      expect(b.length()).toBe(1)
    })
    it('evicts oldest when full', () => {
      const b = new CircularBuffer<number>(3)
      b.add(1); b.add(2); b.add(3); b.add(4)
      expect(b.toArray()).toEqual([2, 3, 4])
    })
    it('length never exceeds capacity', () => {
      const b = new CircularBuffer<number>(2)
      b.add(1); b.add(2); b.add(3)
      expect(b.length()).toBe(2)
    })
    it('returns empty array when empty', () => {
      expect(new CircularBuffer<number>(5).toArray()).toEqual([])
    })
    it('handles capacity of 1', () => {
      const b = new CircularBuffer<number>(1)
      b.add(1); b.add(2)
      expect(b.toArray()).toEqual([2])
      expect(b.length()).toBe(1)
    })
  })

  describe('addAll', () => {
    it('adds multiple items at once', () => {
      const b = new CircularBuffer<number>(5)
      b.addAll([1, 2, 3])
      expect(b.toArray()).toEqual([1, 2, 3])
    })
    it('evicts via addAll when overflow', () => {
      const b = new CircularBuffer<number>(3)
      b.addAll([1, 2, 3, 4])
      expect(b.toArray()).toEqual([2, 3, 4])
    })
    it('handles empty array', () => {
      const b = new CircularBuffer<number>(3)
      b.addAll([])
      expect(b.toArray()).toEqual([])
    })
  })

  describe('getRecent', () => {
    it('returns N most recent items', () => {
      const b = new CircularBuffer<number>(5)
      b.addAll([1, 2, 3, 4, 5])
      expect(b.getRecent(2)).toEqual([4, 5])
    })
    it('returns all items when count >= size', () => {
      const b = new CircularBuffer<number>(5)
      b.addAll([1, 2, 3])
      expect(b.getRecent(10)).toEqual([1, 2, 3])
    })
    it('returns correct items after wrap-around', () => {
      const b = new CircularBuffer<number>(3)
      b.addAll([1, 2, 3, 4, 5])
      expect(b.getRecent(3)).toEqual([3, 4, 5])
      expect(b.getRecent(2)).toEqual([4, 5])
    })
    it('returns empty when buffer is empty', () => {
      expect(new CircularBuffer<number>(5).getRecent(3)).toEqual([])
    })
    it('returns items in oldest-to-newest order', () => {
      const b = new CircularBuffer<string>(3)
      b.addAll(['a', 'b', 'c'])
      const recent = b.getRecent(3)
      expect(recent).toEqual(['a', 'b', 'c'])
    })
  })

  describe('clear', () => {
    it('removes all items', () => {
      const b = new CircularBuffer<number>(5)
      b.addAll([1, 2, 3])
      b.clear()
      expect(b.length()).toBe(0)
      expect(b.toArray()).toEqual([])
    })
    it('allows adding after clear', () => {
      const b = new CircularBuffer<number>(3)
      b.addAll([1, 2, 3])
      b.clear()
      b.add(4)
      expect(b.toArray()).toEqual([4])
    })
    it('getRecent returns empty after clear', () => {
      const b = new CircularBuffer<number>(3)
      b.addAll([1, 2, 3])
      b.clear()
      expect(b.getRecent(3)).toEqual([])
    })
  })
})
