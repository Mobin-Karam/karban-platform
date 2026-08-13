# Implementation status

## Implemented product slices

- Customer-only OTP registration with API.ir SMS OTP / CallOTP provider adapter.
- Consumer discovery/search and public business profiles, verified badge, services, availability and customer reviews.
- In-app "start your business" onboarding with plumber as the seeded first business type.
- Business profile/branding/payment-method management and verification requests.
- Service/category catalog and stock-ledger inventory.
- Registered-customer check before invoice composition, paid install-invite SMS path, invoice issuing, PDF/PNG render records and 72-hour artifact expiry.
- Customer invoices, regeneration requests, notifications, reports, ZarinPal invoice payment and wallet charging.
- Customer/business wallets, wallet ledger, claimable loyalty coins, loyalty levels and admin-managed rules.
- Paid business SMS with owner toggles plus platform `AUTO / REVIEW / DISABLED` policy and generic configurable SMS-provider adapter.
- Staff account requests and admin approval workflow.
- Feature flags, plans, plan limits, freezes, audit log and admin CRUD/operational pages.
- Local admin PWA persisted query cache, keyboard navigation, server-side pagination/search and waiting-service-worker update modal.
- Next.js marketing site, verified-business directory/profile pages, SEO metadata/structured data, eNamad component, screenshot skeletons and video-advertising placeholder.

## Deliberate provider/configuration boundaries

Real API credentials are not shipped. API.ir, ZarinPal and generic SMS gateway credentials are stored through encrypted `IntegrationConfig` records managed by admin. `DATABASE_URL`, `JWT_SECRET` and `CONFIG_ENCRYPTION_KEY` remain bootstrap environment values.

The database models Iranian invoice/tax identifiers and keeps a `TAX` integration category, but direct submission to Iran's Taxpayer System is not falsely presented as completed; connect a certified/current tax provider behind that boundary after legal/compliance review.

Persistent native refresh-token storage is represented by `SecureStorageProvider`; the default starter does not put bearer tokens in WebView local storage. Production persistent login should use Tauri Stronghold or a platform-keystore-backed implementation.
