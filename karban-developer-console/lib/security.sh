#!/usr/bin/env bash
# shellcheck shell=bash

k_mask_url() {
  local value="${1:-}"
  [[ -n "$value" ]] || { printf '<missing>'; return; }
  printf '%s' "$value" | sed -E 's#(://[^:/@]+:)[^@/]+@#\1****@#g; s#([?&](token|key|secret|password|api_key)=)[^&]+#\1****#Ig'
}

k_redact_stream() {
  sed -E \
    -e 's#(postgres(ql)?://[^:/@[:space:]]+:)[^@[:space:]]+@#\1****@#g' \
    -e 's#((TOKEN|SECRET|PASSWORD|API_KEY|MERCHANT_ID|ENCRYPTION_KEY)[=:][[:space:]]*)[^[:space:]]+#\1****#Ig' \
    -e 's#(Authorization:[[:space:]]*Bearer[[:space:]]+)[A-Za-z0-9._~-]+#\1****#Ig'
}

k_env_value() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 0
  grep -E "^${key}=" "$file" | tail -n1 | cut -d= -f2- | sed -E 's/^"(.*)"$/\1/'
}
