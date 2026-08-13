# Karban Platform — Iranian Service Business & Invoice System

Karban is a production-oriented starter for an Iranian service marketplace and business operating system. The first enabled business type is plumbing, but the domain model is generic so later business types can be added through `BusinessType`, feature flags, catalog metadata, plan limits, and modular routes.

## Applications

- `backend/` — NestJS + Prisma + PostgreSQL REST API. No Redis.
- `mobile/` — React + Vite + Tauri 2 client for customers, business owners, and staff.
- `admin/` — React + Vite local-first PWA administration console.
- `website/` — Next.js marketing site + public business directory.
- `docs/` — architecture, Iranian invoice/inventory model, SMS/payment providers, security, deployment, audit.

These are separate applications, not a package-manager monorepo.

## Core flows implemented

1. Customer registers with mobile OTP; API.ir SMS OTP / CallOTP adapter is included.
2. Customer can discover nearby businesses, search/filter them, view Fresha-inspired business pages, reviews, services and availability.
3. A customer can request a business profile from inside the same mobile application.
4. Business onboarding is step-by-step: identity → business details → location → branding → payment details → service/catalog setup → preferences.
5. Business creates an invoice only for an existing registered customer phone number. The API returns `CUSTOMER_NOT_REGISTERED` when no account exists, with an optional SMS invite flow.
6. Invoice data remains in PostgreSQL. PDF/PNG render artifacts expire after 72 hours and are deleted by a scheduled cleanup job.
7. Inventory uses stock movement ledger entries, categories, SKU/unit, minimum stock, cost/sell price, tax/product-service IDs, batch/serial metadata and adjustment reasons.
8. Wallets exist for customers and businesses. Wallet charge creates optional claimable coins, loyalty levels and admin-controlled rules.
9. SMS is wallet-billed, feature-gated and policy-controlled (`AUTO`, `REVIEW`, `DISABLED`). Owners control invoice SMS and campaigns inside their business; platform admin remains the top policy layer.
10. ZarinPal is a payment-provider adapter. Card/bank transfer instructions and future payment providers are modeled separately.
11. Reviews are customer-owned content. Business owners cannot edit reviews; admin moderation is audited.
12. Admin controls feature flags, plans, limits, account freezes, integrations, payment providers, SMS pricing/policies, coins, verification, reports, users and businesses.
13. Admin PWA uses service-worker version updates and shows a click-to-update modal when a new build is waiting.

## Security note about admin-managed credentials

Most integration credentials are stored encrypted in PostgreSQL and edited through admin. Three bootstrap values must remain outside the database:

- `DATABASE_URL`
- `JWT_SECRET`
- `CONFIG_ENCRYPTION_KEY`

Putting the encryption key in the same database as encrypted provider credentials would defeat the purpose of encryption-at-rest.

## Start

See `docs/development.md`, `docs/IMPLEMENTATION_STATUS.md`, and each app README. For the first database bootstrap, generate and commit the initial Prisma migration as documented in `backend/prisma/migrations/README.md`.

## Build audit

See `docs/BUILD_AUDIT.md`. This environment did not have internet package resolution or a Rust toolchain, so dependency-install/native-Tauri builds could not be executed here. Configuration/JSON/source-level checks performed in this pack are recorded there; run the documented commands on a networked development machine before production deployment.
