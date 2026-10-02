# Implementation status

> Source reviewed for repository presentation on 2026-10-02. This document describes product slices present in the repository; it is not a claim that every external integration or production deployment path has been runtime-certified.

## Implemented product slices

- Customer-only OTP registration with API.ir SMS OTP / CallOTP provider adapter.
- Consumer discovery/search and public business profiles, verified badge, services, availability foundations, and customer reviews.
- In-app "start your business" onboarding with plumbing as the seeded first business type.
- Business profile/branding/payment-method management and verification requests.
- Service/category catalog and stock-ledger inventory.
- Registered-customer check before invoice composition, optional invite-SMS path, invoice issuing, PDF/PNG render records, and scheduled artifact expiry.
- Customer invoices, regeneration requests, notifications, reports, ZarinPal invoice payment, and wallet charging.
- Customer/business wallets, wallet ledger, claimable loyalty coins, loyalty levels, and admin-managed rules.
- Paid business SMS with owner toggles plus platform `AUTO / REVIEW / DISABLED` policy and configurable SMS-provider boundary.
- Staff account requests and admin approval workflow.
- Feature flags, plans, plan limits, freezes, audit log, and admin operational pages.
- Local admin PWA persisted query cache, keyboard navigation, server-side pagination/search, and waiting-service-worker update modal.
- Next.js marketing site, verified-business directory/profile pages, SEO metadata/structured data, eNamad component, and media showcase placeholders.
- Initial Prisma migration committed under `backend/prisma/migrations/`.
- Developer console for project, database, native-mobile, build, release, diagnostic, and support workflows.

## Deliberate provider/configuration boundaries

Real provider credentials are not shipped. API.ir, ZarinPal, and generic SMS gateway credentials are designed to be stored through encrypted `IntegrationConfig` records managed by admin.

These bootstrap values remain environment configuration:

- `DATABASE_URL`
- `JWT_SECRET`
- `CONFIG_ENCRYPTION_KEY`

The database models Iranian invoice/tax identifiers and keeps a tax integration boundary, but direct submission to Iran's Taxpayer System is not presented as completed. Connect a certified/current provider only after current legal and compliance review.

## Native-session boundary

The mobile code exposes a `SecureStorageProvider`. The default starter avoids ordinary WebView local-storage persistence for bearer tokens. Production persistent login should use Tauri Stronghold or another platform-keystore-backed implementation with an appropriate native secret strategy.

## Before calling a deployment production-ready

Run dependency-backed type checks, tests, builds, Prisma validation/migration checks, native builds where applicable, provider sandbox/production verification, backup/restore drills, observability setup, security review, and current regulatory/compliance review.
