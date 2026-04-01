import { describe, it, expect } from 'vitest'
import fs from 'fs'
import path from 'path'

describe('Source Map Extraction', () => {
  const mapPath = path.resolve('data/package/cli.js.map')

  it('should have a valid source map file', () => {
    expect(fs.existsSync(mapPath)).toBe(true)
  })

  it('should parse as valid JSON with v3 format', () => {
    const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'))
    expect(map.version).toBe(3)
    expect(map.sources).toBeDefined()
    expect(map.sourcesContent).toBeDefined()
    expect(map.mappings).toBeDefined()
  })

  it('should contain 4756 source entries', () => {
    const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'))
    expect(map.sources.length).toBe(4756)
    expect(map.sourcesContent.length).toBe(4756)
  })

  it('should contain 1902 application src/ files', () => {
    const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'))
    const srcFiles = map.sources.filter((s: string) => s.startsWith('../src/'))
    expect(srcFiles.length).toBe(1902)
  })

  it('should have sourcesContent for all application files', () => {
    const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'))
    let missingContent = 0
    for (let i = 0; i < map.sources.length; i++) {
      if (map.sources[i].startsWith('../src/') && !map.sourcesContent[i]) {
        missingContent++
      }
    }
    expect(missingContent).toBe(0)
  })

  it('should have extracted all src/ files to src/', () => {
    const srcDir = path.resolve('src')
    expect(fs.existsSync(srcDir)).toBe(true)

    let count = 0
    function countFiles(dir: string) {
      for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        if (entry.isDirectory()) countFiles(path.join(dir, entry.name))
        else count++
      }
    }
    countFiles(srcDir)
    expect(count).toBeGreaterThanOrEqual(1902)
  })

  it('should contain TypeScript and TSX files', () => {
    const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'))
    const srcFiles = map.sources.filter((s: string) => s.startsWith('../src/'))
    const tsFiles = srcFiles.filter((s: string) => s.endsWith('.ts'))
    const tsxFiles = srcFiles.filter((s: string) => s.endsWith('.tsx'))
    expect(tsFiles.length).toBe(1332)
    expect(tsxFiles.length).toBe(552)
  })

  it('should have expected top-level src directories', () => {
    const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'))
    const srcFiles = map.sources.filter((s: string) => s.startsWith('../src/'))
    const dirs = new Set<string>()
    srcFiles.forEach((s: string) => {
      const parts = s.replace('../src/', '').split('/')
      if (parts.length > 1) dirs.add(parts[0])
    })
    const expectedDirs = [
      'tools', 'commands', 'components', 'hooks', 'services',
      'utils', 'state', 'types', 'entrypoints', 'bridge',
      'ink', 'skills', 'cli', 'constants',
    ]
    for (const d of expectedDirs) {
      expect(dirs.has(d)).toBe(true)
    }
  })

  it('should map sources to extracted src/ files on disk', () => {
    const map = JSON.parse(fs.readFileSync(mapPath, 'utf8'))
    const srcFiles = map.sources.filter((s: string) => s.startsWith('../src/'))
    // Spot-check 5 known files exist in src/
    const knownFiles = [
      '../src/main.tsx',
      '../src/tools.ts',
      '../src/commands.ts',
      '../src/query.ts',
      '../src/utils/array.ts',
    ]
    for (const f of knownFiles) {
      if (srcFiles.includes(f)) {
        const diskPath = path.resolve('src', f.replace('../src/', ''))
        expect(fs.existsSync(diskPath), `Expected ${diskPath} to exist`).toBe(true)
      }
    }
  })
})
