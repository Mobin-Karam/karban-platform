# Configuration and secrets

Only bootstrap secrets stay in environment variables:

- `DATABASE_URL`
- `JWT_SECRET`
- `CONFIG_ENCRYPTION_KEY` (exactly 64 hexadecimal characters = 32 bytes)
- server bind/public URL and CORS values

Provider credentials are encrypted before being stored in `IntegrationConfig.encryptedConfig` and are edited from the admin Integration page. The admin UI never reads the decrypted secret back; it only gets a mask/configured flag.

Do not put `CONFIG_ENCRYPTION_KEY` in PostgreSQL. Rotate it through an explicit migration/re-encryption procedure.
