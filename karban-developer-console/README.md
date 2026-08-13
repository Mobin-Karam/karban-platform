# Karban Developer Console

A zero-required-dependency Bash control center for the Karban platform. It wraps the separate `backend/`, `mobile/`, `admin/`, and `website/` projects without turning them into a package-manager monorepo.

## One command

```bash
karban
```

or without installation:

```bash
/path/to/karban-developer-console/karban
```

Run it from the Karban platform root, or set:

```bash
export KARBAN_ROOT=/absolute/path/to/karban-platform
```

## Main consoles

1. Project overview and product-module audit
2. Development workspace
3. Database & Prisma
4. Backend API
5. Admin PWA
6. Mobile Android/iOS
7. Marketing website
8. Docker
9. Integrations (API.ir OTP/CallOTP, SMS provider architecture, ZarinPal/payment providers)
10. Storage and invoice rendering
11. Testing and quality
12. Builds and artifacts
13. Release management
14. Environment profiles
15. Logs
16. Diagnostics and support bundle

## Install command

```bash
chmod +x install.sh
./install.sh
```

Then make sure `~/.local/bin` is on `PATH` and run:

```bash
cd /path/to/karban-platform
karban
```

System-wide symlink (requires permission):

```bash
sudo ./install.sh --system
```

## Direct commands

```bash
karban project
karban workspace
karban db
karban backend
karban admin
karban mobile
karban website
karban docker
karban integrations
karban storage
karban test
karban build
karban release
karban env
karban logs
karban doctor
karban quality
karban selftest
```

## Database / Prisma capabilities

- configure and mask `DATABASE_URL`
- PostgreSQL connection testing
- Prisma validate / format / generate / Studio
- migrate dev / create-only / status / deploy / resolve
- db pull / db push
- migration diff/drift preview
- seed and development reset
- PostgreSQL information, table sizes and connection overview
- `psql` shell and SQL-file execution
- compressed `pg_dump` backups + SHA-256
- protected restore workflow
- local PostgreSQL Docker controls
- backend typecheck/test/build through the bundled Prisma manager

## Mobile capabilities

Android:

- Tauri Android initialization
- environment doctor
- hot-reload development
- debug/release APK builds
- release AAB build for Google Play
- APK manager
- keystore generation/selection
- zipalign/sign/verify
- device selection and device information
- emulator listing/start/cold boot/wipe
- install/update/reinstall/uninstall
- signature-conflict recovery
- launch/stop/restart/clear data/open app settings
- live app-focused logcat
- screenshots and screen recording
- deep-link testing for payment/invoice/notification routes
- permission inspection/reset/settings
- adb reverse + local API networking
- manifest/version/package report
- frontend/Rust quality gate
- artifact discovery/checksums/release reports

iOS on macOS:

- Xcode/simulator doctor
- Tauri iOS init
- iOS dev
- iOS build
- list available simulators
- open generated Xcode project

The original Tauri Android toolkit is retained under `tools/tauri-android-toolkit.sh` as the low-level signing/device/install engine.

## Karban-specific diagnostics

The project audit statically checks for modules corresponding to the platform requirements, including:

- OTP / CallOTP
- business onboarding and profiles
- nearby/discovery marketplace
- service catalog
- invoice records + PDF/PNG rendering + 72-hour artifact expiry
- inventory movements
- reviews
- ZarinPal/provider payments
- customer/business wallets
- loyalty coins/club mechanics
- paid/moderated SMS
- plans/limits
- verification badge
- staff requests
- reports
- feature flags
- Jalali/Persian formatting
- admin PWA update flow
- eNamad embed

This is a static presence scan, not proof that a feature passes runtime tests.

## Security model

The console never intentionally persists provider credentials. Project runtime provider credentials remain controlled by the application/admin backend. The console only reads bootstrap environment state for diagnostics and masks sensitive values.

Generated console state lives in:

```text
<karban-platform>/.karban-console/
  config.env
  logs/
  artifacts/
  backups/
```

The folder is added to `.gitignore` automatically.

See `docs/SECURITY.md` for details.
