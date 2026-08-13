import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { execFileSync } from 'node:child_process';

const root = path.resolve(import.meta.dirname, '..');
const require = createRequire(import.meta.url);
let ts;
const candidates = [
  path.join(root, 'backend/node_modules/typescript'),
  path.join(root, 'mobile/node_modules/typescript'),
  path.join(root, 'admin/node_modules/typescript'),
  path.join(root, 'website/node_modules/typescript'),
];
try {
  const globalRoot = execFileSync('npm', ['root', '-g'], { encoding: 'utf8' }).trim();
  candidates.push(path.join(globalRoot, 'typescript'));
} catch {}
for (const candidate of candidates) {
  try { ts = require(candidate); break; } catch {}
}
if (!ts) {
  console.error('TypeScript compiler not found. Install dependencies in one app or install TypeScript globally.');
  process.exit(2);
}

const files = [];
function walk(p) {
  if (!fs.existsSync(p)) return;
  for (const entry of fs.readdirSync(p, { withFileTypes: true })) {
    if (['node_modules', '.next', 'dist', 'target'].includes(entry.name)) continue;
    const q = path.join(p, entry.name);
    if (entry.isDirectory()) walk(q);
    else if (/\.(ts|tsx)$/.test(entry.name) && !entry.name.endsWith('.d.ts')) files.push(q);
  }
}
for (const d of ['backend/src', 'backend/prisma', 'mobile/src', 'admin/src', 'website']) walk(path.join(root, d));
let bad = 0;
for (const f of files) {
  const result = ts.transpileModule(fs.readFileSync(f, 'utf8'), {
    fileName: f,
    reportDiagnostics: true,
    compilerOptions: {
      target: ts.ScriptTarget.ES2022,
      module: ts.ModuleKind.ESNext,
      jsx: ts.JsxEmit.ReactJSX,
      experimentalDecorators: true,
    },
  });
  const errors = (result.diagnostics ?? []).filter((d) => d.category === ts.DiagnosticCategory.Error);
  if (errors.length) {
    bad += 1;
    console.error(`\n${path.relative(root, f)}`);
    for (const d of errors) console.error(ts.flattenDiagnosticMessageText(d.messageText, ' '));
  }
}
console.log(`source syntax audit: ${files.length} TS/TSX files; failures=${bad}`);
process.exit(bad ? 1 : 0);
