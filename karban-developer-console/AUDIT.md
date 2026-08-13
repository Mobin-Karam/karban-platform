# Karban Developer Console — Handoff Audit

Date: 2026-08-11
Version: 1.0.0

## Completed checks

- `bash -n` run over every Bash entry/module/tool/test script.
- `node --check` run over every `.mjs` helper.
- Console fake-project self-test passed.
- Standalone `--help` dispatch passed.
- Attach-to-project installation test passed and generated root `./karban` wrapper executed correctly.
- Safe menu smoke test passed against the real Karban source-pack layout for:
  - project
  - workspace
  - database
  - backend
  - admin
  - mobile
  - website
  - Docker
  - integrations
  - storage
  - testing
  - builds
  - release
  - environment
  - logs
  - diagnostics
- Main interactive menu open/exit smoke test passed.
- Mobile manifest helper correctly identified the Karban app/package/version from the source pack.
- Karban product-module static audit found references for the major requirements (OTP, businesses, discovery, catalog, invoices, renders, expiry, inventory, reviews, payments, wallets, loyalty, SMS, plans, verification, staff, reports and feature flags).
- Console repository lightweight secret scan passed after excluding known local-development placeholders and dynamic password construction.

## Source counts

- 50 files in the console project at audit time.
- Approximately 3,000 lines across Bash/Node console source, modules, helpers and bundled low-level tools.

## Not claimed

This audit proves console syntax, dispatch and safe smoke behavior. It does not claim that Android SDK, Rust, Docker, PostgreSQL, Prisma dependencies, Xcode or each Karban application dependency is installed on the destination machine.

Commands that require those tools deliberately detect or report missing prerequisites at runtime.

The full Karban application build/test results remain the responsibility of the application source tree and its installed dependencies; the console provides the orchestration and quality-gate commands to run them.
