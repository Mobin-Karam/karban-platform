# Karban Backend API

Karban Backend is the central application service for identity, businesses, catalog, inventory, invoices, payments, wallets, messaging, platform policy, and administration.

## Stack

- NestJS 11
- Prisma 6
- PostgreSQL 16
- TypeScript
- JWT authentication
- Puppeteer for invoice PDF/PNG rendering

## API shape

The API is served under:

```text
/api/v1
```

The application enables:

- URI API versioning
- Request validation with non-whitelisted fields rejected
- Helmet security headers
- Compression
- Explicit CORS allowlists
- Global response envelope handling
- Global exception normalization
- Request throttling
- Graceful shutdown hooks

## Domain modules

Current source modules cover:

- Authentication and OTP
- Businesses and business access
- Catalog
- Inventory
- Invoices and rendering
- Reviews
- Wallets
- SMS
- Payments
- Staff
- Reports
- Messaging
- Media
- Notifications
- Feature flags and entitlements
- Encrypted integration configuration
- Platform administration
- Health checks

## Local development

```bash
cd backend
cp .env.example .env
npm ci
npx prisma generate
npx prisma validate
npm run prisma:deploy
npm run prisma:seed
npm run dev
```

The default development API is available at:

```text
http://localhost:4000/api/v1
```

## Required bootstrap configuration

These values must exist before the application starts:

```env
DATABASE_URL=postgresql://...
JWT_SECRET=replace-with-a-random-secret-of-at-least-32-characters
CONFIG_ENCRYPTION_KEY=<64 hex characters>
```

Do not store the configuration encryption key inside the same database that holds encrypted provider configuration.

See [`../docs/environment.md`](../docs/environment.md) for the broader configuration model.

## Database

The Prisma schema and initial migration are committed under:

```text
prisma/schema.prisma
prisma/migrations/
```

Apply committed migrations with:

```bash
npm run prisma:deploy
```

Create new development migrations intentionally with:

```bash
npm run prisma:migrate -- --name describe_the_change
```

## Checks

```bash
npm run typecheck
npm run build
npm test
npm run lint
```

## Provider boundaries

Karban keeps external integrations behind application/provider boundaries rather than wiring business rules directly to one vendor. Current source includes foundations for:

- API.ir OTP / CallOTP
- Generic configurable SMS providers
- ZarinPal payments
- Additional payment methods/providers
- Tax-provider integration boundary
- Local/S3-style media storage

Production deployments should validate each configured provider against current API documentation and legal/compliance requirements.

## Security

Important implemented safeguards include hashed OTPs, JWT guards, super-admin guards, encrypted integration configuration, payment callback verification, transactional money flows, server-resolved invoice data, CORS allowlists, validation, throttling, upload constraints, and audit-oriented administration.

Read [`../docs/security.md`](../docs/security.md) before exposing the API publicly.
