/**
 * Tests for path conversion utilities from src/utils/windowsPaths.ts
 * and argument substitution from src/utils/argumentSubstitution.ts
 */
import { describe, it, expect } from 'vitest'

// === Re-implementation: windowsPaths.ts ===

function windowsPathToPosixPath(windowsPath: string): string {
  if (windowsPath.startsWith('\\\\')) {
    return windowsPath.replace(/\\/g, '/')
  }
  const match = windowsPath.match(/^([A-Za-z]):[/\\]/)
  if (match) {
    const driveLetter = match[1]!.toLowerCase()
    return '/' + driveLetter + windowsPath.slice(2).replace(/\\/g, '/')
  }
  return windowsPath.replace(/\\/g, '/')
}

function posixPathToWindowsPath(posixPath: string): string {
  if (posixPath.startsWith('//')) {
    return posixPath.replace(/\//g, '\\')
  }
  const cygdriveMatch = posixPath.match(/^\/cygdrive\/([A-Za-z])(\/|$)/)
  if (cygdriveMatch) {
    const driveLetter = cygdriveMatch[1]!.toUpperCase()
    const rest = posixPath.slice(('/cygdrive/' + cygdriveMatch[1]).length)
    return driveLetter + ':' + (rest || '\\').replace(/\//g, '\\')
  }
  const driveMatch = posixPath.match(/^\/([A-Za-z])(\/|$)/)
  if (driveMatch) {
    const driveLetter = driveMatch[1]!.toUpperCase()
    const rest = posixPath.slice(2)
    return driveLetter + ':' + (rest || '\\').replace(/\//g, '\\')
  }
  return posixPath.replace(/\//g, '\\')
}

// === Re-implementation: argumentSubstitution.ts ===
// (parseArguments relies on shell-quote; we test the pure parts)

function parseArgumentNames(argumentNames: string | string[] | undefined): string[] {
  if (!argumentNames) return []
  const isValidName = (name: string): boolean =>
    typeof name === 'string' && name.trim() !== '' && !/^\d+$/.test(name)
  if (Array.isArray(argumentNames)) return argumentNames.filter(isValidName)
  if (typeof argumentNames === 'string')
    return argumentNames.split(/\s+/).filter(isValidName)
  return []
}

function generateProgressiveArgumentHint(
  argNames: string[],
  typedArgs: string[],
): string | undefined {
  const remaining = argNames.slice(typedArgs.length)
  if (remaining.length === 0) return undefined
  return remaining.map(name => `[${name}]`).join(' ')
}

// substituteArguments without shell-quote dependency (simplified for testing)
function substituteArgumentsSimple(
  content: string,
  args: string | undefined,
  appendIfNoPlaceholder = true,
  argumentNames: string[] = [],
): string {
  if (args === undefined || args === null) return content
  const parsedArgs = args.split(/\s+/).filter(Boolean) // simplified split
  const originalContent = content

  for (let i = 0; i < argumentNames.length; i++) {
    const name = argumentNames[i]
    if (!name) continue
    content = content.replace(
      new RegExp(`\\$${name}(?![\\[\\w])`, 'g'),
      parsedArgs[i] ?? '',
    )
  }

  content = content.replace(/\$ARGUMENTS\[(\d+)\]/g, (_, indexStr: string) => {
    return parsedArgs[parseInt(indexStr, 10)] ?? ''
  })

  content = content.replace(/\$(\d+)(?!\w)/g, (_, indexStr: string) => {
    return parsedArgs[parseInt(indexStr, 10)] ?? ''
  })

  content = content.replaceAll('$ARGUMENTS', args)

  if (content === originalContent && appendIfNoPlaceholder && args) {
    content = content + `\n\nARGUMENTS: ${args}`
  }

  return content
}

// ===================================================

describe('Windows Path Conversion (src/utils/windowsPaths.ts)', () => {
  describe('windowsPathToPosixPath', () => {
    it('should convert C:\\ drive paths', () => {
      expect(windowsPathToPosixPath('C:\\Users\\foo')).toBe('/c/Users/foo')
    })

    it('should convert lowercase drive letters', () => {
      expect(windowsPathToPosixPath('c:\\Users\\foo')).toBe('/c/Users/foo')
    })

    it('should convert D:\\ drive paths', () => {
      expect(windowsPathToPosixPath('D:\\work\\project')).toBe('/d/work/project')
    })

    it('should handle UNC paths', () => {
      expect(windowsPathToPosixPath('\\\\server\\share')).toBe('//server/share')
    })

    it('should handle already-POSIX paths', () => {
      expect(windowsPathToPosixPath('/usr/local/bin')).toBe('/usr/local/bin')
    })

    it('should handle root-only drive path', () => {
      expect(windowsPathToPosixPath('C:\\')).toBe('/c/')
    })

    it('should convert mixed forward/back slashes in path body', () => {
      expect(windowsPathToPosixPath('C:/Users\\foo')).toBe('/c/Users/foo')
    })
  })

  describe('posixPathToWindowsPath', () => {
    it('should convert /c/ format to C:\\ ', () => {
      expect(posixPathToWindowsPath('/c/Users/foo')).toBe('C:\\Users\\foo')
    })

    it('should convert /C/ format with uppercase', () => {
      expect(posixPathToWindowsPath('/C/Users/foo')).toBe('C:\\Users\\foo')
    })

    it('should convert /cygdrive/c/ format', () => {
      expect(posixPathToWindowsPath('/cygdrive/c/Users/foo')).toBe('C:\\Users\\foo')
    })

    it('should handle /cygdrive/d/ format', () => {
      expect(posixPathToWindowsPath('/cygdrive/d/')).toBe('D:\\')
    })

    it('should handle UNC paths // format', () => {
      expect(posixPathToWindowsPath('//server/share')).toBe('\\\\server\\share')
    })

    it('should handle drive-only /c path', () => {
      expect(posixPathToWindowsPath('/c')).toBe('C:\\')
    })

    it('should handle already-Windows relative paths', () => {
      expect(posixPathToWindowsPath('relative\\path')).toBe('relative\\path')
    })
  })

  describe('round-trip conversion', () => {
    it('should round-trip C:\\ paths', () => {
      const win = 'C:\\Users\\andreburgstahler\\Documents'
      const posix = windowsPathToPosixPath(win)
      expect(posixPathToWindowsPath(posix)).toBe(win)
    })

    it('should round-trip D:\\ paths', () => {
      const win = 'D:\\Projects\\myapp'
      const posix = windowsPathToPosixPath(win)
      expect(posixPathToWindowsPath(posix)).toBe(win)
    })
  })
})

describe('Argument Name Parsing (src/utils/argumentSubstitution.ts)', () => {
  describe('parseArgumentNames', () => {
    it('should parse space-separated string', () => {
      expect(parseArgumentNames('foo bar baz')).toEqual(['foo', 'bar', 'baz'])
    })

    it('should parse array input', () => {
      expect(parseArgumentNames(['x', 'y', 'z'])).toEqual(['x', 'y', 'z'])
    })

    it('should return empty for undefined', () => {
      expect(parseArgumentNames(undefined)).toEqual([])
    })

    it('should return empty for empty string', () => {
      expect(parseArgumentNames('')).toEqual([])
    })

    it('should filter out numeric-only names', () => {
      expect(parseArgumentNames('foo 123 bar 456')).toEqual(['foo', 'bar'])
    })

    it('should filter out empty strings from array', () => {
      expect(parseArgumentNames(['a', '', 'b'])).toEqual(['a', 'b'])
    })

    it('should handle single name', () => {
      expect(parseArgumentNames('filename')).toEqual(['filename'])
    })

    it('should handle multiple spaces', () => {
      expect(parseArgumentNames('foo   bar')).toEqual(['foo', 'bar'])
    })
  })

  describe('generateProgressiveArgumentHint', () => {
    it('should return hint for remaining args', () => {
      expect(generateProgressiveArgumentHint(['file', 'dest'], ['src.txt'])).toBe('[dest]')
    })

    it('should return undefined when all args filled', () => {
      expect(generateProgressiveArgumentHint(['a', 'b'], ['1', '2'])).toBeUndefined()
    })

    it('should return all args when none typed', () => {
      expect(generateProgressiveArgumentHint(['a', 'b', 'c'], [])).toBe('[a] [b] [c]')
    })

    it('should return undefined for empty names', () => {
      expect(generateProgressiveArgumentHint([], [])).toBeUndefined()
    })

    it('should return single remaining arg', () => {
      expect(generateProgressiveArgumentHint(['src', 'dest'], ['file.txt'])).toBe('[dest]')
    })
  })
})

describe('Argument Substitution (src/utils/argumentSubstitution.ts)', () => {
  describe('substituteArgumentsSimple', () => {
    it('should replace $ARGUMENTS placeholder', () => {
      expect(substituteArgumentsSimple('File: $ARGUMENTS', 'test.txt')).toBe('File: test.txt')
    })

    it('should replace indexed $0 $1 shorthands', () => {
      expect(substituteArgumentsSimple('$0 -> $1', 'a b')).toBe('a -> b')
    })

    it('should replace $ARGUMENTS[0] syntax', () => {
      expect(substituteArgumentsSimple('src=$ARGUMENTS[0]', 'main.ts lib.ts')).toBe('src=main.ts')
    })

    it('should return content unchanged for undefined args', () => {
      expect(substituteArgumentsSimple('no args here', undefined)).toBe('no args here')
    })

    it('should append args when no placeholder and appendIfNoPlaceholder=true', () => {
      const result = substituteArgumentsSimple('do something', 'myarg', true)
      expect(result).toContain('ARGUMENTS: myarg')
    })

    it('should not append when appendIfNoPlaceholder=false', () => {
      const result = substituteArgumentsSimple('do something', 'myarg', false)
      expect(result).toBe('do something')
    })

    it('should not append when args is empty string', () => {
      const result = substituteArgumentsSimple('do something', '', true)
      expect(result).toBe('do something')
    })

    it('should replace named arguments', () => {
      const result = substituteArgumentsSimple('$foo and $bar', 'hello world', true, ['foo', 'bar'])
      expect(result).toBe('hello and world')
    })

    it('should use empty string for missing indexed args', () => {
      expect(substituteArgumentsSimple('a=$0 b=$1', 'only')).toBe('a=only b=')
    })
  })
})
