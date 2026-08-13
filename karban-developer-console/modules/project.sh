#!/usr/bin/env bash
# shellcheck shell=bash

k_feature_check() {
  local label="$1" pattern="$2" paths=("$KARBAN_ROOT/backend/src" "$KARBAN_ROOT/backend/prisma" "$KARBAN_ROOT/mobile/src" "$KARBAN_ROOT/admin/src" "$KARBAN_ROOT/website")
  if grep -RqiE --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=.next "$pattern" "${paths[@]}" 2>/dev/null; then k_status_row "$label" PASS; else k_status_row "$label" WARN 'not found by static name scan'; fi
}

k_feature_audit() {
  k_header 'KARBAN / PRODUCT MODULE AUDIT' 'Static presence scan based on the platform requirements'
  k_feature_check 'OTP / CallOTP' 'CallOTP|SmsOTP|otp'
  k_feature_check 'Business onboarding' 'business.*onboard|onboard.*business|start.*business'
  k_feature_check 'Businesses/profiles' 'BusinessProfile|business profile|Business'
  k_feature_check 'Customer discovery' 'nearby|distance|location|discover|marketplace'
  k_feature_check 'Services/catalog' 'ServiceCategory|Catalog|ServiceItem|services'
  k_feature_check 'Invoices' 'InvoiceItem|Invoice|invoice'
  k_feature_check 'PDF/PNG renders' 'puppeteer|render.*invoice|invoice.*pdf|png'
  k_feature_check '72-hour lifecycle' '72|expiresAt|render.*expire'
  k_feature_check 'Inventory ledger' 'InventoryMovement|StockMovement|inventory'
  k_feature_check 'Reviews/ratings' 'Review|rating|stars'
  k_feature_check 'ZarinPal payments' 'zarinpal|PaymentProvider'
  k_feature_check 'Wallets' 'WalletTransaction|Wallet|wallet'
  k_feature_check 'Coins/loyalty' 'coin|loyalty|club|reward'
  k_feature_check 'SMS billing/moderation' 'Sms|sms.*approval|approval.*sms|segment.*cost'
  k_feature_check 'Plans/limits' 'Plan|Limit|quota|subscription'
  k_feature_check 'Verification badge' 'Verification|verified|blue.*tick'
  k_feature_check 'Staff requests' 'Staff|staff.*request'
  k_feature_check 'Reports' 'Report|report'
  k_feature_check 'Feature flags' 'FeatureFlag|FeatureOverride|feature.*flag'
  k_feature_check 'Jalali/Persian format' 'Jalali|fa-IR|Persian|formatNumber|formatDate'
  k_feature_check 'Admin PWA update' 'registerSW|serviceWorker|update.*available'
  k_feature_check 'eNamad' 'trustseal\.enamad\.ir'
  printf '\n%bNote:%b PASS here means a static code/schema reference exists; it is not a runtime test.\n' "$K_BOLD" "$K_RESET"
}

k_project_overview() {
  k_header 'KARBAN / PROJECT OVERVIEW'
  k_status_dashboard
  k_section 'Applications'
  k_app_summary "$KARBAN_ROOT/backend" Backend
  k_app_summary "$KARBAN_ROOT/admin" Admin
  k_app_summary "$KARBAN_ROOT/mobile" Mobile
  k_app_summary "$KARBAN_ROOT/website" Website
  printf '\nRoot: %s\nConsole: %s\n' "$KARBAN_ROOT" "$KARBAN_CONSOLE_DIR"
}

k_project_menu() {
  while true; do
    k_header 'KARBAN / PROJECT'
    printf '  1  Project overview\n  2  Product module presence audit\n  3  Show project tree\n  4  Git status\n  5  Documentation index\n  6  Open console README path\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) k_project_overview; k_pause;; 2) k_feature_audit; k_pause;; 3) (cd "$KARBAN_ROOT" && find backend admin mobile website docs -maxdepth 2 -type d 2>/dev/null | sort | head -200); k_pause;; 4) git -C "$KARBAN_ROOT" status --short --branch; k_pause;; 5) find "$KARBAN_ROOT/docs" "$KARBAN_CONSOLE_DIR/docs" -maxdepth 1 -type f -print 2>/dev/null | sort; k_pause;; 6) printf '%s\n' "$KARBAN_CONSOLE_DIR/README.md"; k_pause;; b) return;; esac
  done
}
