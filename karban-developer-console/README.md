# Karban Developer Console

The Karban Developer Console is a zero-required-dependency Bash control center for the platform. It wraps the separate `backend/`, `mobile/`, `admin/`, and `website/` projects without turning them into a package-manager monorepo.

Use it when you want one consistent entry point for local development, database work, diagnostics, builds, native-mobile operations, and release tasks.

## Quick start

Run without installing:

```bash
/path/to/karban-developer-console/karban
```

Or install it for the current user:

```bash
cd karban-developer-console
chmod +x install.sh
./install.sh
```

Make sure `~/.local/bin` is on `PATH`, then:

```bash
cd /path/to/karban-platform
karban
```

If you launch the console outside the repository, set:

```bash
export KARBAN_ROOT=/absolute/path/to/karban-platform
```

System-wide symlink installation is also available when appropriate:

```bash
sudo ./install.sh --system
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
9. Integrations
10. Storage and invoice rendering
11. Testing and quality
12. Builds and artifacts
13. Release management
14. Environment profiles
15. Logs
16. Diagnostics and support bundle

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

- Configure and mask `DATABASE_URL`
- Test PostgreSQL connectivity
- Prisma validate / format / generate / Studio
- Migrate dev / create-only / status / deploy / resolve
- `db pull` / `db push`
- Migration diff and drift preview
- Seed and protected development reset
- PostgreSQL information, table-size, and connection views
- `psql` shell and SQL-file execution
- Compressed `pg_dump` backups with SHA-256
- Protected restore workflow
- Local PostgreSQL Docker controls
- Backend typecheck/test/build through the bundled Prisma manager

## Mobile capabilities

### Android

- Tauri Android initialization
- Environment doctor
- Hot-reload development
- Debug/release APK builds
- Release AAB build
- APK manager
- Keystore generation/selection
- zipalign/sign/verify
- Device selection and device information
- Emulator listing/start/cold boot/wipe
- Install/update/reinstall/uninstall
- Signature-conflict recovery
- Launch/stop/restart/clear data/open app settings
- App-focused logcat
- Screenshots and screen recording
- Deep-link testing for payment/invoice/notification routes
- Permission inspection/reset/settings
- `adb reverse` + local API networking
- Manifest/version/package report
- Frontend/Rust quality gate
- Artifact discovery, checksums, and release reports

### iOS on macOS

- Xcode/simulator doctor
- Tauri iOS initialization
- iOS development/build flows
- Simulator listing
- Open generated Xcode project

The original Tauri Android toolkit remains under `tools/tauri-android-toolkit.sh` as the low-level signing/device/install engine.

## Karban-specific diagnostics

The project audit statically checks for source corresponding to major platform requirements, including:

- OTP / CallOTP
- Business onboarding and profiles
- Nearby/discovery marketplace
- Service catalog
- Invoice records + PDF/PNG rendering + artifact expiry
- Inventory movements
- Reviews
- ZarinPal/provider payments
- Customer/business wallets
- Loyalty coins/club mechanics
- Paid/moderated SMS
- Plans/limits
- Verification badge
- Staff requests
- Reports
- Feature flags
- Persian/Jalali formatting foundations
- Admin PWA update flow
- eNamad embed

A static presence scan is useful for catching missing product areas, but it is **not proof that a feature passes runtime tests**.

## Security model

The console does not intentionally persist provider credentials. Runtime provider secrets stay controlled by the application/admin backend. The console reads bootstrap environment state for diagnostics and masks sensitive values.

Generated console state lives under:

```text
<karban-platform>/.karban-console/
  config.env
  logs/
  artifacts/
  backups/
```

The project ignores this directory.

Read [`docs/SECURITY.md`](docs/SECURITY.md) before using backup, restore, signing, or environment-management workflows.

## More documentation

- [Installation](docs/INSTALLATION.md)
- [Commands](docs/COMMANDS.md)
- [Database workflows](docs/DATABASE.md)
- [Mobile tooling](docs/MOBILE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Security](docs/SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Extending the console](docs/EXTENDING.md)
