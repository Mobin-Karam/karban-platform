# Iranian invoice and inventory model

## Monetary representation

All stored money is integer **rial (IRR)** using `BigInt`. UI formatting uses `fa-IR`; no floating-point amount is persisted. If a product UI later offers toman input, convert explicitly at the boundary and label the unit.

## Invoice data

An invoice stores seller/customer snapshots, sequential business invoice number, issue/due dates, payment terms, notes, discount, tax, subtotal/total/paid amounts, payment status, and item snapshots. Each item can represent a service, inventory item or custom allowed line. Service/inventory references are resolved server-side so frontend prices are not authoritative.

Important Iranian/tax fields are present as extensible metadata: product/service tax identifier, unit, tax rate, seller identifiers and references. Electronic tax submission to `سامانه مودیان` is intentionally a provider/adapter boundary: production compliance depends on the taxpayer entity, certificates, fiscal identifiers, accepted schemas and current regulations. Do not advertise a generic app invoice as tax-system compliant until the production adapter is certified for the merchant's case.

## Render lifecycle

`Invoice` and `InvoiceItem` stay in the database. `InvoiceRender` represents PDF/PNG files and has `expiresAt`. The default expiry is 72 hours. The scheduled cleanup deletes expired files and marks render records expired. Regeneration creates a new render without altering invoice history.

## Inventory

Do not use only `currentQuantity`. `InventoryMovement` is the audit source for:

- purchase/receipt
- job consumption
- counter sale
- customer/supplier return
- transfer
- opening balance
- correction/adjustment

Each movement records quantity, before/after, optional cost and reference/reason. Negative stock is rejected unless a future feature explicitly changes that policy. Item fields include category, SKU/barcode, unit, min/reorder quantity, average cost, sale price, tax/service identifier, supplier/location and batch/serial metadata.
