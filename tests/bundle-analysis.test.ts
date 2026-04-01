import { describe, it, expect } from 'vitest'
import fs from 'fs'
import path from 'path'

describe('Bundle Analysis (data/package/cli.js)', () => {
  const cliPath = path.resolve('data/package/cli.js')

  it('should exist and be executable', () => {
    expect(fs.existsSync(cliPath)).toBe(true)
    const stat = fs.statSync(cliPath)
    expect(stat.mode & 0o111).toBeGreaterThan(0) // executable bit
  })

  it('should start with node shebang', () => {
    const fd = fs.openSync(cliPath, 'r')
    const buf = Buffer.alloc(100)
    fs.readSync(fd, buf, 0, 100, 0)
    fs.closeSync(fd)
    expect(buf.toString('utf8').startsWith('#!/usr/bin/env node')).toBe(true)
  })

  it('should contain version identifier 2.1.88', () => {
    const fd = fs.openSync(cliPath, 'r')
    const buf = Buffer.alloc(500)
    fs.readSync(fd, buf, 0, 500, 0)
    fs.closeSync(fd)
    expect(buf.toString('utf8')).toContain('2.1.88')
  })

  it('should contain build timestamp', () => {
    const content = fs.readFileSync(cliPath, 'utf8')
    expect(content).toContain('2026-03-30T21:59:52Z')
  })

  it('should contain Anthropic copyright', () => {
    const fd = fs.openSync(cliPath, 'r')
    const buf = Buffer.alloc(300)
    fs.readSync(fd, buf, 0, 300, 0)
    fs.closeSync(fd)
    expect(buf.toString('utf8')).toContain('Anthropic PBC')
  })

  it('should be a single bundled file (no bare relative imports)', () => {
    const fd = fs.openSync(cliPath, 'r')
    const buf = Buffer.alloc(1000)
    fs.readSync(fd, buf, 0, 1000, 0)
    fs.closeSync(fd)
    const header = buf.toString('utf8')
    expect(header).not.toMatch(/^import .+ from '\.\//m)
  })

  it('should have a source map reference', () => {
    const mapPath = path.resolve('data/package/cli.js.map')
    expect(fs.existsSync(mapPath)).toBe(true)
    expect(fs.statSync(mapPath).size).toBeGreaterThan(1000000) // > 1MB
  })
})

describe('Package Manifest (data/package via source map)', () => {
  // The original package.json is our repo's package.json (which we've modified)
  // The original npm package manifest details are in the source map metadata
  // and inlined in cli.js. We verify from the bundle.
  const cliContent = fs.readFileSync('data/package/cli.js', 'utf8')

  it('should reference @anthropic-ai/claude-code package', () => {
    expect(cliContent).toContain('@anthropic-ai/claude-code')
  })

  it('should reference version 2.1.88', () => {
    expect(cliContent).toContain('2.1.88')
  })

  it('should reference the GitHub issues URL', () => {
    expect(cliContent).toContain('github.com/anthropics/claude-code/issues')
  })

  it('should reference the docs URL', () => {
    expect(cliContent).toContain('code.claude.com/docs')
  })
})

describe('Repo Package Manifest (package.json)', () => {
  const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'))

  it('should have correct package name', () => {
    expect(pkg.name).toBe('@anthropic-ai/claude-code')
  })

  it('should have correct version', () => {
    expect(pkg.version).toBe('2.1.88')
  })

  it('should have test script', () => {
    expect(pkg.scripts.test).toBeDefined()
    expect(pkg.scripts.test).toContain('vitest')
  })

  it('should use ESM', () => {
    expect(pkg.type).toBe('module')
  })

  it('should have vitest as dev dependency', () => {
    expect(pkg.devDependencies?.vitest).toBeDefined()
  })
})

describe('Vendor Binaries (data/package/vendor/)', () => {
  it('should have ripgrep binaries for multiple platforms', () => {
    const platforms = ['arm64-darwin', 'arm64-linux', 'x64-darwin', 'x64-linux']
    for (const platform of platforms) {
      const rgPath = path.resolve(`data/package/vendor/ripgrep/${platform}/rg`)
      expect(fs.existsSync(rgPath), `Missing rg for ${platform}`).toBe(true)
    }
  })

  it('should have audio-capture binaries for multiple platforms', () => {
    const platforms = ['arm64-darwin', 'x64-darwin', 'arm64-linux', 'x64-linux']
    for (const platform of platforms) {
      const acPath = path.resolve(`data/package/vendor/audio-capture/${platform}/audio-capture.node`)
      expect(fs.existsSync(acPath), `Missing audio-capture for ${platform}`).toBe(true)
    }
  })

  it('should have ripgrep COPYING license', () => {
    expect(fs.existsSync(path.resolve('data/package/vendor/ripgrep/COPYING'))).toBe(true)
  })
})
