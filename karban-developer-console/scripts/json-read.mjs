#!/usr/bin/env node
import fs from 'node:fs';
const [file, key = ''] = process.argv.slice(2);
if (!file) process.exit(2);
try {
  let value = JSON.parse(fs.readFileSync(file, 'utf8'));
  for (const part of key.split('.').filter(Boolean)) value = value?.[part];
  if (value === undefined || value === null) process.exit(1);
  if (typeof value === 'object') process.stdout.write(JSON.stringify(value));
  else process.stdout.write(String(value));
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
}
