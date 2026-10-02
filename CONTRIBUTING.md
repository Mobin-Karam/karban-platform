# Contributing to Karban

Thanks for improving Karban.

The project is split into independent applications that share an HTTP contract. Keep changes focused, preserve provider boundaries, and avoid coupling one client to another client's implementation details.

## Before you start

Read:

- [README.md](README.md)
- [docs/README.md](docs/README.md)
- [docs/architecture.md](docs/architecture.md)
- [docs/security.md](docs/security.md)

## Development setup

Use either the root Docker workspace:

```bash
docker compose up --build
```

or follow [docs/development.md](docs/development.md) to run applications independently.

## Pull request expectations

A useful pull request should:

- Explain the user or operator problem being solved.
- Keep business rules in the appropriate backend/domain layer.
- Preserve Persian/RTL behavior where relevant.
- Avoid hardcoding provider credentials or production secrets.
- Include or update tests for behavior changes when practical.
- Update documentation for externally visible behavior.
- Keep migrations reviewed and committed for schema changes.
- Note any provider, native-toolchain, or environment requirements needed to verify the change.

## Quality checks

Run the checks relevant to the files you changed.

Backend:

```bash
cd backend
npm ci
npx prisma generate
npx prisma validate
npm run typecheck
npm run build
npm test
```

Mobile:

```bash
cd mobile
npm ci
npm run typecheck
npm run build
```

Admin:

```bash
cd admin
npm ci
npm run typecheck
npm run build
```

Website:

```bash
cd website
npm ci
npm run typecheck
npm run build
```

Repository source audit:

```bash
node scripts/audit.mjs
```

Native Tauri builds require the appropriate Rust and platform toolchains.

## Security

Never commit:

- Production database URLs
- JWT secrets
- Encryption keys
- OTP/SMS provider secrets
- Payment-provider secrets
- Signing keys or keystores
- User/customer data
- Private production logs

If a secret is accidentally committed, removing it from the latest file is not enough. Rotate the credential and, when necessary, rewrite repository history using an appropriate secret-removal process.

## Product claims

Keep public documentation credible. Do not claim that a feature, provider integration, tax workflow, payment flow, or native build is production-verified unless it has actually been validated in the relevant environment.
