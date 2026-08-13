# Console security

## Principles

- Do not write API.ir, SMS-provider, ZarinPal, bank, JWT, OTP or payment credentials into console configuration.
- Console configuration stores only environment/profile URLs.
- `DATABASE_URL` continues to live in the backend environment and is masked on display.
- Support bundles contain system metadata and sanitized console logs, not project `.env` files.
- A lightweight secret-literal scan is included but is not a substitute for a dedicated secret scanner.
- Database reset, restore, Docker volume deletion, app-data deletion and release workflows use explicit confirmations.
- Production is represented as an explicit environment string and should never rely only on ANSI colors.

## Keystore

The Android toolkit can create or select a release keystore. The keystore password is read with hidden terminal input and exported only to the signing subprocess environment. The console never writes the password to its config file.

Back up the release keystore separately using your organization’s secure secret/backup process. Losing the signing identity can prevent normal application upgrades.

## Logs

`k_log_run` duplicates visible command output into `.karban-console/logs` through a redaction filter. Avoid passing secrets as command-line arguments; shell process listings and history are outside the redactor’s control.
