export function safeLimit(input: number | undefined, fallback = 20, max = 100): number {
  const parsed = Math.floor(input ?? fallback);
  return Math.min(Math.max(parsed, 1), max);
}
