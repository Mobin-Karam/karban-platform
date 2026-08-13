import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const roots = ['backend/src', 'backend/prisma', 'mobile/src', 'admin/src', 'website'];
const files = [];
const skip = new Set(['node_modules', '.next', 'dist', 'target', '.git']);

function walk(dir) {
  if (!fs.existsSync(dir)) return;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (skip.has(entry.name)) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (/\.(?:ts|tsx|js|jsx|mjs|cjs)$/.test(entry.name)) files.push(full);
  }
}
for (const dir of roots) walk(path.join(root, dir));

const specifierRe = /(?:from\s*|import\s*\(|require\s*\()\s*['"](\.[^'"]+)['"]/g;
const extensions = ['', '.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.json', '.css', '.svg', '.png', '.jpg', '.jpeg', '.webp'];
const indexes = ['index.ts', 'index.tsx', 'index.js', 'index.jsx', 'index.mjs', 'index.cjs'];
let checked = 0;
let failures = 0;

function resolves(fromFile, specifier) {
  const base = path.resolve(path.dirname(fromFile), specifier);
  for (const ext of extensions) if (fs.existsSync(base + ext) && fs.statSync(base + ext).isFile()) return true;
  if (fs.existsSync(base) && fs.statSync(base).isDirectory()) {
    for (const name of indexes) if (fs.existsSync(path.join(base, name))) return true;
  }
  return false;
}

for (const file of files) {
  const source = fs.readFileSync(file, 'utf8');
  let match;
  while ((match = specifierRe.exec(source))) {
    checked += 1;
    if (!resolves(file, match[1])) {
      failures += 1;
      console.error('UNRESOLVED', path.relative(root, file), '->', match[1]);
    }
  }
}

console.log(`local import audit: ${checked} relative imports checked; failures=${failures}`);
process.exit(failures ? 1 : 0);
