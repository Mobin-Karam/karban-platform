# Troubleshooting

## Project root not found

Run from the platform root or export:

```bash
export KARBAN_ROOT=/path/to/karban-platform
```

The root must contain `backend`, `mobile`, `admin`, and `website`.

## Tauri command missing

Install the mobile application's dependencies first, then run Android/iOS tooling.

## Android device not detected

Run the Android doctor, check USB debugging authorization, and use the Devices menu. An `unauthorized` device needs approval on the phone.

## Phone cannot reach API

Use Environment -> LAN profile or Mobile -> Android -> Network -> adb reverse API port.

## AAB/APK signing errors

Use the low-level Android toolkit Key Manager and environment doctor. Do not replace a production signing key casually.

## Prisma cannot connect

Use Database -> Configure DATABASE_URL and Test connection. Confirm Docker/PostgreSQL is running and the host differs correctly between host-local (`localhost`) and backend-inside-Docker (`postgres`).
