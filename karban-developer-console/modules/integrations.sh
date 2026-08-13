#!/usr/bin/env bash
# shellcheck shell=bash

k_integration_env_status() {
  local env="$KARBAN_ROOT/backend/.env"
  k_status_row 'DATABASE_URL' "$([[ -n "$(k_env_value "$env" DATABASE_URL)" ]] && printf READY || printf MISSING)"
  k_status_row 'JWT secret' "$([[ -n "$(k_env_value "$env" JWT_SECRET)" ]] && printf READY || printf MISSING)"
  local ek; ek="$(k_env_value "$env" MASTER_ENCRYPTION_KEY)"; [[ -z "$ek" ]] && ek="$(k_env_value "$env" CONFIG_ENCRYPTION_KEY)"
  k_status_row 'Encryption key' "$([[ -n "$ek" ]] && printf READY || printf MISSING)" "$([[ -n "$ek" ]] && printf 'configured (hidden)' || true)"
}

k_integration_code_audit() {
  local term="$1"; grep -Rni --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=.next "$term" "$KARBAN_ROOT/backend/src" "$KARBAN_ROOT/backend/prisma" 2>/dev/null | head -120 || true
}

k_integrations_menu() {
  while true; do
    k_header 'KARBAN / EXTERNAL SERVICES & INTEGRATIONS' 'Secrets remain masked; database-managed provider credentials are not printed'
    k_integration_env_status
    printf '\n  1  Find API.ir OTP/CallOTP adapter\n  2  Find ZarinPal payment adapter\n  3  Find SMS provider adapters/configuration\n  4  Find payment-provider registry\n  5  Check backend API reachability\n  6  Inspect feature/provider configuration models\n  7  Security scan for obvious committed secrets\n  8  Open admin integration settings hint\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) k_integration_code_audit 'api.ir\|SmsOTP\|CallOTP'; k_pause;; 2) k_integration_code_audit 'zarinpal\|payment.zarinpal'; k_pause;; 3) k_integration_code_audit 'smsProvider\|SMS_PROVIDER\|Kavenegar\|sms.ir\|melipayamak\|ippanel'; k_pause;; 4) k_integration_code_audit 'PaymentProvider\|paymentProvider'; k_pause;;
      5) curl -i --max-time 5 "${KARBAN_API_URL%/api/v1}/api/v1/health"; k_pause;;
      6) grep -RniE 'Integration|ProviderConfig|Feature|FeatureOverride|Sms|Payment' "$KARBAN_ROOT/backend/prisma" 2>/dev/null | head -120; k_pause;;
      7) "$KARBAN_CONSOLE_DIR/scripts/secret-scan.sh" "$KARBAN_ROOT"; k_pause;;
      8) printf 'Admin PWA should be used for runtime provider credentials and feature controls.\nConsole only verifies bootstrap keys and code/config presence.\n'; k_pause;; b) return;; esac
  done
}
