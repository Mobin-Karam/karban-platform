#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import crypto from 'node:crypto';
const [outFile, ...files] = process.argv.slice(2);
if (!outFile) process.exit(2);
const sha = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const artifacts = files.filter(fs.existsSync).map(file => ({file:path.resolve(file), size:fs.statSync(file).size, sha256:sha(file)}));
const report = {generatedAt:new Date().toISOString(), artifacts};
fs.mkdirSync(path.dirname(outFile), {recursive:true}); fs.writeFileSync(outFile, JSON.stringify(report,null,2)+'\n');
console.log(outFile);
