# Build and verification notes

This file separates **historical packaging checks** from checks that still need to be run on a fully provisioned development/CI machine.

## Historical packaging audit

The recorded packaging audit was performed on **2026-08-11**. At that time the environment could not resolve `registry.npmjs.org` and did not contain a Rust toolchain, so dependency-backed application builds and native Tauri builds were not claimed as passing.

The repository has changed since that snapshot. In particular:

- An initial Prisma migration is now committed under `backend/prisma/migrations/20260811173844_start/`.
- The root Compose workspace now includes PostgreSQL, backend, admin, and website services.
- Public repository documentation has been refreshed.

For that reason, do not treat the old packaging snapshot as a current CI result.

## Source-level audit tooling

The repository includes:

```bash
node scripts/audit.mjs
```

The audit scripts are intended to catch configuration, local-import, manifest, source-presence, and asset problems without replacing real builds/tests.

## Recommended full validation

Run these commands on a networked development or CI machine:

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

## Database migration checks

The current repository includes an initial migration. Validate it against a disposable PostgreSQL database before production:

```bash
cd backend
npm ci
npx prisma generate
npx prisma validate
npm run prisma:deploy
npm run prisma:seed
```

For production deployments, apply committed migrations with `npm run prisma:deploy`; do not generate migrations on the production host.

## Production gate

Do not deploy solely because source-level audits pass. A production gate should also cover:

- Dependency and lockfile review
- Runtime/unit/integration tests
- API/provider sandbox validation
- Native build/signing checks where applicable
- Database backup and restore test
- Secret and configuration review
- Storage permissions and cleanup behavior
- Monitoring/logging/alerting
- Current Iranian payment, tax, privacy, marketplace, and e-commerce compliance requirements
