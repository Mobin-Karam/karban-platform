# Security checklist

- JWT routes use guards; admin routes require `SUPERADMIN`.
- OTP codes are hashed in the database and expire.
- Integration secrets are AES-GCM encrypted at rest with an external master key.
- ZarinPal/payment callbacks are verified server-side; client redirect is never trusted.
- Sensitive money operations use database transactions and provider attempts.
- Invoice creation resolves prices/catalog entities server-side.
- File upload validates size and MIME allow-lists; production should add malware scanning and private-object authorization.
- Account/business freezes are checked in authorization-sensitive flows and admin changes should be audited.
- Reviews are customer content; owners can reply but cannot rewrite them.
- Public endpoints are paginated; admin tables are cursor-paginated.
- CORS uses explicit origins; production must not fall back to `*`.
- Do not log OTPs, tokens or decrypted integration secrets in production.

## Native token storage

The mobile code exposes `SecureStorageProvider`. The provided default keeps sensitive values in memory rather than ordinary `localStorage`. For persistent native sessions, provision Tauri Stronghold (or a platform-keystore-backed provider) and supply its unlock secret through a native-secure strategy; do not hardcode a vault password in JavaScript.
