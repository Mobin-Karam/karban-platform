#!/usr/bin/env node
import fs from 'node:fs';
const [file, key, rawValue] = process.argv.slice(2);
if (!file || !key) process.exit(2);
const data = JSON.parse(fs.readFileSync(file, 'utf8'));
let value = rawValue;
try { value = JSON.parse(rawValue); } catch {}
const parts = key.split('.');
let cursor = data;
for (const part of parts.slice(0, -1)) cursor = cursor[part] ??= {};
cursor[parts.at(-1)] = value;
fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`);
