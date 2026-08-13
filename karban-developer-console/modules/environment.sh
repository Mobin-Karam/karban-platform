#!/usr/bin/env bash
# shellcheck shell=bash

k_environment_summary() {
  printf '  Environment      %s\n  API URL          %s\n  Admin URL        %s\n  Website URL      %s\n' "$KARBAN_ENVIRONMENT" "$(k_mask_url "$KARBAN_API_URL")" "$KARBAN_ADMIN_URL" "$KARBAN_WEBSITE_URL"
}

k_environment_set_profile() {
  case "$1" in
    local) KARBAN_ENVIRONMENT=development; KARBAN_API_URL='http://localhost:3000/api/v1'; KARBAN_ADMIN_URL='http://localhost:5174'; KARBAN_WEBSITE_URL='http://localhost:3001';;
    lan) local ip; ip="$(hostname -I 2>/dev/null | awk '{print $1}')"; [[ -n "$ip" ]] || ip="$(ipconfig getifaddr en0 2>/dev/null || true)"; ip="$(k_prompt 'LAN IP address' "$ip")"; KARBAN_ENVIRONMENT=development; KARBAN_API_URL="http://$ip:3000/api/v1"; KARBAN_ADMIN_URL="http://$ip:5174"; KARBAN_WEBSITE_URL="http://$ip:3001";;
    staging) KARBAN_ENVIRONMENT=staging; KARBAN_API_URL="$(k_prompt 'Staging API URL' "$KARBAN_API_URL")"; KARBAN_ADMIN_URL="$(k_prompt 'Staging admin URL' "$KARBAN_ADMIN_URL")"; KARBAN_WEBSITE_URL="$(k_prompt 'Staging website URL' "$KARBAN_WEBSITE_URL")";;
    production) KARBAN_ENVIRONMENT=production; KARBAN_API_URL="$(k_prompt 'Production API URL')"; KARBAN_ADMIN_URL="$(k_prompt 'Production admin URL')"; KARBAN_WEBSITE_URL="$(k_prompt 'Production website URL')";;
  esac
  k_state_save; k_ok 'Console environment profile saved.'
}

k_environment_menu() {
  while true; do
    k_header 'KARBAN / ENVIRONMENT' 'Console profiles never store integration secrets'
    k_environment_summary
    printf '\n  1  Use localhost development profile\n  2  Use LAN/mobile-device development profile\n  3  Configure staging profile\n  4  Configure production profile\n  5  Custom URLs\n  6  Show backend .env (redacted)\n  7  Show project .env.example files\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) k_environment_set_profile local; k_pause;; 2) k_environment_set_profile lan; k_pause;; 3) k_environment_set_profile staging; k_pause;; 4) k_environment_set_profile production; k_pause;;
      5) KARBAN_ENVIRONMENT="$(k_prompt 'Environment' "$KARBAN_ENVIRONMENT")"; KARBAN_API_URL="$(k_prompt 'API URL' "$KARBAN_API_URL")"; KARBAN_ADMIN_URL="$(k_prompt 'Admin URL' "$KARBAN_ADMIN_URL")"; KARBAN_WEBSITE_URL="$(k_prompt 'Website URL' "$KARBAN_WEBSITE_URL")"; k_state_save; k_pause;;
      6) [[ -f "$KARBAN_ROOT/backend/.env" ]] && k_redact_stream < "$KARBAN_ROOT/backend/.env" || k_warn 'backend/.env missing'; k_pause;;
      7) find "$KARBAN_ROOT" -maxdepth 2 -name '.env.example' -print -exec sh -c 'echo "--- $1"; cat "$1"' _ {} \; | k_redact_stream; k_pause;; b) return;; esac
  done
}
