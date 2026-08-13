import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const required = [
  'assets/logo-512.png',
  'mobile/public/brand/logo.svg',
  'mobile/public/brand/favicon.svg',
  'mobile/public/icons/icon-512.png',
  'mobile/src-tauri/icons/32x32.png',
  'mobile/src-tauri/icons/128x128.png',
  'mobile/src-tauri/icons/128x128@2x.png',
  'mobile/src-tauri/icons/icon.ico',
  'mobile/src-tauri/icons/icon.icns',
  'admin/public/brand/logo.svg',
  'admin/public/brand/favicon.svg',
  'admin/public/icons/icon-512.png',
  'admin/public/manifest.webmanifest',
  'admin/public/sw.js',
  'website/public/brand/logo.svg',
  'website/public/brand/favicon.svg',
  'website/public/icons/icon-512.png',
  'website/components/EnamadSeal.tsx',
];
let failures = 0;
for (const rel of required) {
  const file = path.join(root, rel);
  if (!fs.existsSync(file) || fs.statSync(file).size === 0) {
    failures += 1;
    console.error('MISSING/EMPTY ASSET', rel);
  }
}
const enamad = fs.readFileSync(path.join(root, 'website/components/EnamadSeal.tsx'), 'utf8');
for (const needle of ['trustseal.enamad.ir/?id=707242&Code=EHBQU8BMbloXnxweqJxwbHPnH1yLJ33i', 'trustseal.enamad.ir/logo.aspx?id=707242&Code=EHBQU8BMbloXnxweqJxwbHPnH1yLJ33i']) {
  if (!enamad.includes(needle)) {
    failures += 1;
    console.error('ENAMAD SNIPPET MISMATCH', needle);
  }
}
console.log(`asset audit: ${required.length} required files checked; failures=${failures}`);
process.exit(failures ? 1 : 0);
