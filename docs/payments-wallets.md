# Payments, wallets and loyalty

## Payment provider boundary

`PaymentAttempt` is provider-neutral. ZarinPal is the initial adapter. An attempt is created before redirect/opening the gateway and every callback is verified by the backend using the amount stored on that attempt. A browser/deep-link return is not payment proof.

Business owners can publish non-secret bank/card payment instructions through `BusinessPaymentMethod`. Secret provider settings remain encrypted admin configuration.

## Wallet ledger

Customers and businesses each have wallets. Balance changes happen inside database transactions and create immutable `WalletTransaction` records. SMS cost is debited from the business wallet; failed provider dispatch is refunded through a compensating transaction.

## Coins and club levels

A successful eligible wallet charge creates a `CoinGrant` using admin `CoinRule`. Grants can require the user to enter the coin section and claim them. `LoyaltyLevel.autoClaimEnabled` can switch higher levels to automatic collection. Coins are a separate non-cash ledger and must not silently become withdrawable money.
