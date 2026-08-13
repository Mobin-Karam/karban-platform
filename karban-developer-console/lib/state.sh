#!/usr/bin/env bash
# shellcheck shell=bash

k_state_init() {
  KARBAN_STATE_DIR="${KARBAN_STATE_DIR:-$KARBAN_ROOT/.karban-console}"
  KARBAN_LOG_DIR="$KARBAN_STATE_DIR/logs"
  KARBAN_ARTIFACT_DIR="$KARBAN_STATE_DIR/artifacts"
  KARBAN_BACKUP_DIR="$KARBAN_STATE_DIR/backups"
  KARBAN_CONFIG_FILE="$KARBAN_STATE_DIR/config.env"
  mkdir -p "$KARBAN_LOG_DIR" "$KARBAN_ARTIFACT_DIR" "$KARBAN_BACKUP_DIR"
  chmod 700 "$KARBAN_STATE_DIR" 2>/dev/null || true
  if [[ -f "$KARBAN_ROOT/.gitignore" ]]; then
    grep -Fxq '/.karban-console/' "$KARBAN_ROOT/.gitignore" || printf '\n/.karban-console/\n' >> "$KARBAN_ROOT/.gitignore"
  fi
  KARBAN_ENVIRONMENT="development"
  KARBAN_API_URL="http://localhost:3000/api/v1"
  KARBAN_ADMIN_URL="http://localhost:5174"
  KARBAN_WEBSITE_URL="http://localhost:3001"
  [[ -f "$KARBAN_CONFIG_FILE" ]] && source "$KARBAN_CONFIG_FILE" || true
  return 0
}

k_state_save() {
  {
    printf 'KARBAN_ENVIRONMENT=%q\n' "$KARBAN_ENVIRONMENT"
    printf 'KARBAN_API_URL=%q\n' "$KARBAN_API_URL"
    printf 'KARBAN_ADMIN_URL=%q\n' "$KARBAN_ADMIN_URL"
    printf 'KARBAN_WEBSITE_URL=%q\n' "$KARBAN_WEBSITE_URL"
  } > "$KARBAN_CONFIG_FILE"
  chmod 600 "$KARBAN_CONFIG_FILE" 2>/dev/null || true
}

k_log_run() {
  local name="$1"; shift
  local log="$KARBAN_LOG_DIR/$(k_now)-${name}.log"
  k_info "Log: $log"
  set +e
  "$@" 2>&1 | tee >(k_redact_stream > "$log")
  local rc=${PIPESTATUS[0]}
  set -e
  return "$rc"
}
