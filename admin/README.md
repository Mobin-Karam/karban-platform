# Karban Admin PWA

Karban Admin is the platform-operations console for managing users, businesses, plans, feature controls, integrations, payments, SMS policy, verification, reviews, wallets, reports, and audit-oriented workflows.

It is built as a **local-first React PWA**: the static application shell is service-worker cached, while API responses remain under explicit application/query-cache control rather than being blindly cached by the service worker.

## Stack

- React 19
- Vite 7
- React Router 7
- TanStack Query with persisted browser cache
- Zustand
- Lucide icons
- TypeScript

## Main operational areas

The current admin source includes pages for:

- Dashboard and reporting
- Users and businesses
- Business types
- Plans and feature controls
- Integrations
- Inventory and invoices
- Payments and wallets
- SMS policy
- Reviews and verification
- Staff requests
- Audit logs

The backend remains the source of truth for authorization and policy enforcement. The admin UI should never be treated as a security boundary by itself.

## Local development

```bash
cd admin
cp .env.example .env
npm ci
npm run dev
```

Default development URL: `http://localhost:5174`.

Environment:

```env
VITE_API_URL=http://localhost:4000/api/v1
```

Run the backend first or use the root `docker compose up --build` workspace.

## Build and checks

```bash
npm run typecheck
npm run build
npm run preview
```

## PWA update behavior

The service worker caches the shell/static assets. API responses are intentionally excluded from service-worker caching.

When a new service worker is installed and waiting:

1. Karban displays an update modal.
2. The user chooses to update.
3. The app sends `SKIP_WAITING`.
4. `controllerchange` triggers a single reload.

This avoids requiring operators to manually clear browser cache after deployments.

## Local-first query cache

TanStack Query persistence gives operators faster reloads and continuity across navigation. It does **not** make privileged operations fully offline. Mutating actions still depend on the API and backend authorization.

## Keyboard navigation

Press `G`, then the shortcut shown in the sidebar. Examples:

- `G D` — Dashboard
- `G U` — Users
- `G B` — Businesses

## Security notes

- Admin API routes require backend authorization; UI route hiding is not sufficient.
- Integration secrets should only be entered through the supported encrypted backend flow.
- Do not store provider secrets in Vite environment variables.
- Review [`../docs/security.md`](../docs/security.md) and [`../docs/environment.md`](../docs/environment.md) before production deployment.
