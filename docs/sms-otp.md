# OTP and paid SMS

OTP and business messaging are separate concerns even when a vendor provides both.

## OTP

The API creates a short-lived challenge, generates the code server-side, stores only a hash, enforces expiry/attempt limits and uses an `OTP` integration provider only for delivery. The API.ir adapter supports SMS OTP and voice CallOTP modes.

## Business SMS

A business has SMS settings for invoice notifications, install invites and campaign permission. Admin sets global/provider policy and may require review per business. Message states include pending approval, queued/sent, delivered/failed/rejected. Cost is estimated by segment and debited from the business wallet on dispatch.

The generic HTTP adapter accepts encrypted provider auth/settings plus a request template and response ID path. This avoids tying billing/policy logic to one Iranian SMS company. Add a typed provider adapter when a vendor has important delivery-report or template APIs.
