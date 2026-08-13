#!/usr/bin/env bash
# shellcheck shell=bash

k_app_summary() {
  local dir="$1" label="$2" pm='-'
  [[ -d "$dir" ]] || { k_status_row "$label" MISSING; return; }
  pm="$(k_detect_pm "$dir")"
  local deps='MISSING'; [[ -d "$dir/node_modules" ]] && deps='READY'
  k_status_row "$label" READY "$pm | dependencies: $deps"
}

k_app_run_common() {
  local dir="$1" label="$2" action="$3"
  case "$action" in
    install) k_log_run "${label,,}-install" k_pm_install "$dir" ;;
    dev) k_has_script "$dir" dev && k_pm_run "$dir" dev || k_run_script_if_present "$dir" start:dev ;;
    build) k_log_run "${label,,}-build" k_run_script_if_present "$dir" build ;;
    typecheck) k_log_run "${label,,}-typecheck" k_run_script_if_present "$dir" typecheck ;;
    test) k_log_run "${label,,}-test" k_run_script_if_present "$dir" test ;;
    lint) k_log_run "${label,,}-lint" k_run_script_if_present "$dir" lint ;;
  esac
}

k_generic_app_menu() {
  local dir="$1" label="$2" extra_fn="${3:-}" choice
  while true; do
    k_header "KARBAN / $label" "$dir"
    k_app_summary "$dir" "$label"
    printf '\n  1  Install dependencies\n  2  Start development server\n  3  Typecheck\n  4  Tests\n  5  Lint\n  6  Production build\n  7  Package scripts\n'
    [[ -n "$extra_fn" ]] && printf '  8  Advanced tools\n'
    printf '\n  B  Back\n\nChoose: '
    read -r choice || choice=b
    case "${choice,,}" in
      1) k_app_run_common "$dir" "$label" install; k_pause;; 2) k_app_run_common "$dir" "$label" dev;; 3) k_app_run_common "$dir" "$label" typecheck; k_pause;; 4) k_app_run_common "$dir" "$label" test; k_pause;; 5) k_app_run_common "$dir" "$label" lint; k_pause;; 6) k_app_run_common "$dir" "$label" build; k_pause;;
      7) node -e 'let p=require(process.argv[1]);console.log(p.scripts||{})' "$dir/package.json" 2>/dev/null || cat "$dir/package.json"; k_pause;;
      8) [[ -n "$extra_fn" ]] && "$extra_fn";; b) return 0;; *) k_warn 'Unknown option.'; sleep 1;; esac
  done
}
