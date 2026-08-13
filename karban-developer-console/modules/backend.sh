#!/usr/bin/env bash
# shellcheck shell=bash
k_backend_advanced() {
  while true; do
    k_header 'KARBAN / BACKEND / ADVANCED'
    printf '  1  Health endpoint\n  2  Readiness endpoint\n  3  Prisma console\n  4  Show backend environment (redacted)\n  5  Show listening ports/processes\n  6  Run seed\n  7  Full backend quality gate\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) curl -i --max-time 5 "${KARBAN_API_URL%/}/health" 2>/dev/null || curl -i --max-time 5 "${KARBAN_API_URL%/api/v1}/api/v1/health"; k_pause;;
      2) curl -i --max-time 5 "${KARBAN_API_URL%/}/ready" 2>/dev/null || true; k_pause;;
      3) k_database_menu;;
      4) [[ -f "$KARBAN_ROOT/backend/.env" ]] && k_redact_stream < "$KARBAN_ROOT/backend/.env" || k_warn 'backend/.env missing'; k_pause;;
      5) (ss -lntp 2>/dev/null || lsof -iTCP -sTCP:LISTEN 2>/dev/null || true); k_pause;;
      6) k_prisma seed; k_pause;;
      7) k_run_steps_begin 4; k_run_step 'Prisma validate' k_prisma validate && k_run_step 'Typecheck' k_run_script_if_present "$KARBAN_ROOT/backend" typecheck && k_run_step 'Tests' k_run_script_if_present "$KARBAN_ROOT/backend" test && k_run_step 'Build' k_run_script_if_present "$KARBAN_ROOT/backend" build; k_pause;;
      b) return;; esac
  done
}
k_backend_menu() { k_generic_app_menu "$KARBAN_ROOT/backend" 'BACKEND API' k_backend_advanced; }
