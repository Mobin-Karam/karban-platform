# Adding future business types/modules

1. Create/enable a `BusinessType` (for example electrical, HVAC, cleaning).
2. Keep shared concepts in core modules: customer, business, service, inventory, invoice, wallet, review.
3. Add business-specific settings inside a dedicated module/table or typed metadata—not conditionals scattered across controllers.
4. Register the module's feature key in `Feature` and plan limits in `PlanLimit`.
5. Add mobile/admin routes behind feature gates.
6. Add provider implementations behind `PaymentProvider`, SMS/OTP, storage, maps or tax adapters.
7. Add migrations and module tests before enabling the feature globally.

A disabled/maintenance/coming-soon feature remains structurally installed; admin changes availability without deleting routes/data.
