# Build and configuration audit

Audit date: 2026-08-11

## Passed in the packaging environment

The repository includes `node scripts/audit.mjs` so these checks are reproducible.

- 17 JSON/manifest/config files parsed successfully.
- 160 TypeScript/TSX source files passed TypeScript transpile/syntax parsing.
- 437 relative imports were resolved to local source files.
- 18 required brand/PWA/Tauri assets were present.
- `docker-compose.yml` parsed successfully and contains only `postgres` and `backend`; Redis is not present.
- Mobile source scan found no persisted bearer access token in `localStorage` or `sessionStorage`.
- Tauri/PWA/brand icon files were generated and included.
- Backend bootstrap validation requires PostgreSQL, a JWT secret of at least 32 characters, and a 64-hex-character AES-256 configuration encryption key.
- Docker runtime explicitly installs Chromium for Puppeteer invoice PDF/PNG rendering.
- Payment callback, wallet mutations, SMS dispatch, loyalty grant/claim paths contain database-level idempotency/concurrency guards.

## Checks that could not honestly be executed here

The environment cannot currently resolve `registry.npmjs.org` (`EAI_AGAIN`) and contains no application `node_modules`. Rust/Cargo are also not installed. Therefore the following are **not claimed as passed**:

- `npm ci` / dependency resolution
- Prisma client generation / `prisma validate`
- semantic TypeScript type-checks against installed library types
- Nest/Vite/Next production builds
- Jest execution
- native Tauri Android/iOS builds

The installed host tools observed during packaging were Node.js 22.16.0, npm 10.9.2 and Java 21.0.11.

## Prisma migration status

`backend/prisma/schema.prisma` and the seed are included. The initial migration SQL is intentionally not fabricated because Prisma CLI could not be installed/executed in this environment. On the first networked development machine:

```bash
cd backend
npm ci
npx prisma generate
npx prisma validate
npx prisma migrate dev --name init
npm run prisma:seed
```

Review and commit the generated `prisma/migrations/<timestamp>_init/` directory. Production deployments should use `npm run prisma:deploy`.

## Full validation commands

```bash
node scripts/audit.mjs

cd backend
npm ci
npx prisma generate
npx prisma validate
npm run typecheck
npm run build
npm test

cd ../mobile
npm ci
npm run typecheck
npm run build
# Native, after Rust/Android tooling:
npm run tauri:android:build

cd ../admin
npm ci
npm run typecheck
npm run build

cd ../website
npm ci
npm run typecheck
npm run build
```

Do not deploy until those dependency-backed checks pass on a networked development/CI machine.
