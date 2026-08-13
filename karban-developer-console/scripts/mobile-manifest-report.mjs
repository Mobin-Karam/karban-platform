#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path';
const root = path.resolve(process.argv[2] || '.');
const candidates = ['tauri.conf.json','tauri.conf.json5'].map(f=>path.join(root,'src-tauri',f));
const cfgFile = candidates.find(fs.existsSync);
const pkgFile = path.join(root,'package.json');
const pkg = fs.existsSync(pkgFile) ? JSON.parse(fs.readFileSync(pkgFile,'utf8')) : {};
let cfg = {};
if (cfgFile?.endsWith('.json')) cfg = JSON.parse(fs.readFileSync(cfgFile,'utf8'));
const report = {
  name: cfg.productName || pkg.name || path.basename(root), version: cfg.version || pkg.version || 'unknown',
  identifier: cfg.identifier || 'unknown', minSdkVersion: cfg.bundle?.android?.minSdkVersion ?? 'default',
  versionCode: cfg.bundle?.android?.versionCode ?? 'derived', frontendDist: cfg.build?.frontendDist ?? 'unknown',
  devUrl: cfg.build?.devUrl ?? 'unknown'
};
for (const [k,v] of Object.entries(report)) console.log(`${k.padEnd(16)} ${v}`);
