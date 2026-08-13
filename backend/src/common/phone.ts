export function normalizeIranPhone(input: string): string {
  const ascii = input.replace(/[۰-۹]/g, (d) => String('۰۱۲۳۴۵۶۷۸۹'.indexOf(d))).replace(/\D/g, '');
  if (ascii.startsWith('0098')) return `0${ascii.slice(4)}`;
  if (ascii.startsWith('98')) return `0${ascii.slice(2)}`;
  if (ascii.startsWith('9') && ascii.length === 10) return `0${ascii}`;
  if (/^09\d{9}$/.test(ascii)) return ascii;
  throw new Error('INVALID_IRAN_PHONE');
}
