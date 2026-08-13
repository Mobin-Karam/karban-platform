#!/usr/bin/env node
const raw = process.argv[2];
if (!raw) process.exit(2);
try {
  const u = new URL(raw);
  const schema = u.searchParams.get('schema') || 'public';
  const out = {
    protocol: u.protocol.replace(':',''), host: u.hostname, port: u.port || '5432',
    database: u.pathname.replace(/^\//,''), username: decodeURIComponent(u.username),
    password: decodeURIComponent(u.password), schema
  };
  if (process.argv.includes('--shell')) {
    for (const [k,v] of Object.entries(out)) process.stdout.write(`${k.toUpperCase()}=${JSON.stringify(v)}\n`);
  } else process.stdout.write(JSON.stringify(out, null, 2));
} catch (e) { process.stderr.write(`Invalid DATABASE_URL: ${e.message}\n`); process.exit(1); }
