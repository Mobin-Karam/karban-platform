# Karban Documentation

This directory contains product, architecture, operations, security, and integration notes for the Karban platform.

## Start here

| Document | Purpose |
| --- | --- |
| [Product scope](product-scope.md) | What the current platform is designed to cover |
| [Implementation status](IMPLEMENTATION_STATUS.md) | What product slices are present in the repository |
| [Architecture](architecture.md) | Application boundaries and domain model |
| [Local development](development.md) | How to run the platform locally |
| [Environment](environment.md) | Bootstrap configuration and secret handling |
| [Security](security.md) | Security model and production checklist |
| [Build verification](BUILD_AUDIT.md) | Historical audit context and current validation commands |

## Domain references

- [Iranian invoice & inventory model](iranian-invoice-inventory.md)
- [Payments & wallets](payments-wallets.md)
- [SMS & OTP](sms-otp.md)
- [API conventions](api-conventions.md)
- [Extensibility](extensibility.md)
- [Admin PWA notes](admin-pwa.md)

## Application guides

- [Backend API](../backend/README.md)
- [Mobile client](../mobile/README.md)
- [Admin PWA](../admin/README.md)
- [Public website](../website/README.md)
- [Developer console](../karban-developer-console/README.md)

## Documentation principles

Karban documentation should distinguish clearly between:

1. Source that is implemented.
2. Integrations that require deployment credentials/configuration.
3. Features that require runtime verification.
4. Legal, tax, payment, privacy, or marketplace requirements that must be re-checked for the actual production deployment.

Avoid presenting planned or provider-dependent behavior as verified production functionality.
