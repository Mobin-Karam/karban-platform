# Karban Mobile

Karban Mobile is the Persian/RTL-first customer and business application. It uses one customer identity as the starting point: direct registration creates a customer account, and business capabilities are enabled later through the in-app **Start your business** flow.

The same client therefore supports discovery and customer activity while also giving owners and approved staff access to business operations.

## Stack

- React 19
- Vite 7
- Tauri 2
- React Router 7
- TanStack Query
- Zustand
- Zod
- TypeScript

## Customer experience

Current source-level flows include:

- Mobile OTP authentication
- Business discovery and search
- Public business detail
- Services and reviews
- Customer invoices
- Payment/wallet foundations
- Notifications and reporting/message foundations
- Profile management

## Business experience

Business mode includes source-level flows for:

- Multi-step business onboarding
- Business profile and branding
- Service catalog
- Inventory
- Invoice creation and history
- Business wallet
- SMS controls
- Staff requests
- Reporting

## Run the web shell

```bash
cd mobile
cp .env.example .env
npm ci
npm run dev
```

Default environment:

```env
VITE_API_URL=http://localhost:4000/api/v1
VITE_APP_NAME=کاربان
```

The browser/Vite shell is useful for day-to-day UI development. Native-only behavior still needs a Tauri target.

## Android with Tauri 2

Prerequisites include Rust, the Android SDK/NDK, Java, and the Tauri mobile requirements for your host OS.

```bash
npm run tauri:android:init
npm run tauri:android:dev
npm run tauri:android:build
```

The included [Karban Developer Console](../karban-developer-console/README.md) provides additional Android doctor, emulator/device, signing, install, logcat, screenshot, recording, permission, deep-link, and release tooling.

## Native integration boundaries

The source contains native-facing helpers for:

- Payment/deep-link handling
- Secure-storage abstraction
- Tauri runtime integration

The default starter does not persist bearer tokens in ordinary WebView `localStorage`. Persistent native sessions should use a platform-keystore-backed solution such as Tauri Stronghold and a secure unlock strategy.

## Build and checks

```bash
npm run typecheck
npm run build
npm run tauri:android:build
```

The final command requires a correctly configured native Android toolchain.

## Product model

Karban intentionally avoids separate customer and business registration silos. A user starts as a customer, then can create a business profile and receive role-appropriate capabilities. This keeps identity, invoices, wallet behavior, and customer/business relationships centered on one account model.

For platform-wide setup and architecture, return to the [root README](../README.md).
