import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    include: ['tests/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      include: [
        'src/utils/array.ts',
        'src/utils/xml.ts',
        'src/utils/uuid.ts',
        'src/utils/CircularBuffer.ts',
        'src/utils/intl.ts',
        'src/utils/userPromptKeywords.ts',
        'src/utils/formatBriefTimestamp.ts',
        'src/utils/memoize.ts',
        'src/utils/json.ts',
        'src/utils/jsonRead.ts',
      ],
      exclude: [],
      reporter: ['text', 'html'],
      thresholds: {
        lines: 90,
        functions: 90,
        branches: 80,
        statements: 90,
      },
    },
  },
})
