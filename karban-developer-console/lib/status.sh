#!/usr/bin/env bash
# shellcheck shell=bash

k_port_open() {
  local host="${1:-127.0.0.1}" port="$2"
  if k_cmd_exists nc; then nc -z -w1 "$host" "$port" >/dev/null 2>&1
  elif k_cmd_exists bash; then timeout 1 bash -c "</dev/tcp/$host/$port" >/dev/null 2>&1
  else return 1; fi
}

k_status_dashboard() {
  local db='UNKNOWN' api='OFFLINE' docker='MISSING' mobile='MISSING'
  [[ -f "$KARBAN_ROOT/backend/prisma/schema.prisma" ]] && db='READY'
  if k_cmd_exists curl && curl -fsS --max-time 1 "${KARBAN_API_URL%/api/v1}/api/v1/health" >/dev/null 2>&1; then api='ONLINE'; fi
  if k_cmd_exists docker; then docker='STOPPED'; docker info >/dev/null 2>&1 && docker='READY'; fi
  [[ -f "$KARBAN_ROOT/mobile/src-tauri/Cargo.toml" ]] && mobile='READY'
  k_status_row 'Environment' "${KARBAN_ENVIRONMENT^^}" "API: $(k_mask_url "$KARBAN_API_URL")"
  k_status_row 'Backend API' "$api"
  k_status_row 'Prisma schema' "$db"
  k_status_row 'Mobile/Tauri' "$mobile"
  k_status_row 'Docker' "$docker"
  printf '  %-22s %-12s %s\n' 'Git' "$(k_git_branch)" "$(k_git_commit)$([[ $(k_git_dirty; echo $?) -eq 0 ]] && printf ' dirty' || true)"
}
