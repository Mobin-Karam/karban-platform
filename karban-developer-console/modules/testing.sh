#!/usr/bin/env bash
# shellcheck shell=bash

k_test_project() {
  local dir="$1" label="$2"
  k_section "$label"
  if [[ ! -d "$dir" ]]; then k_warn 'Project missing.'; return 1; fi
  local ran=0
  for s in typecheck lint test build; do
    if k_has_script "$dir" "$s"; then ran=1; k_log_run "test-${label,,}-$s" k_run_script_if_present "$dir" "$s" || return 1; fi
  done
  (( ran )) || k_warn 'No standard quality scripts discovered.'
}

k_all_quality() {
  k_header 'KARBAN / FULL QUALITY GATE' 'Backend • Mobile • Admin • Website • Console'
  local failed=0
  "$KARBAN_CONSOLE_DIR/tests/syntax.sh" || failed=1
  k_prisma validate || failed=1
  k_test_project "$KARBAN_ROOT/backend" backend || failed=1
  k_test_project "$KARBAN_ROOT/mobile" mobile || failed=1
  k_test_project "$KARBAN_ROOT/admin" admin || failed=1
  k_test_project "$KARBAN_ROOT/website" website || failed=1
  (( failed == 0 )) && k_ok 'Quality gate completed.' || k_err 'One or more quality checks failed.'
  return "$failed"
}

k_testing_menu() {
  while true; do
    k_header 'KARBAN / TESTING & QUALITY'
    printf '  1  Console self-test\n  2  Prisma validate\n  3  Backend quality\n  4  Mobile quality\n  5  Admin quality\n  6  Website quality\n  7  Full project quality gate\n  8  Secret-literal scan\n  9  Check all JSON files\n 10  Bash shellcheck (if installed)\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) "$KARBAN_CONSOLE_DIR/tests/selftest.sh"; k_pause;; 2) k_prisma validate; k_pause;; 3) k_test_project "$KARBAN_ROOT/backend" backend; k_pause;; 4) k_mobile_quality; k_pause;; 5) k_test_project "$KARBAN_ROOT/admin" admin; k_pause;; 6) k_test_project "$KARBAN_ROOT/website" website; k_pause;;
      7) k_all_quality; k_pause;; 8) "$KARBAN_CONSOLE_DIR/scripts/secret-scan.sh" "$KARBAN_ROOT"; k_pause;;
      9) find "$KARBAN_ROOT" -type f -name '*.json' -not -path '*/node_modules/*' -not -path '*/.next/*' -not -path '*/target/*' -print0 | xargs -0 -n1 node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); console.log("OK",process.argv[1])'; k_pause;;
      10) if command -v shellcheck >/dev/null; then find "$KARBAN_CONSOLE_DIR" -type f -name '*.sh' -print0 | xargs -0 shellcheck; else k_warn 'shellcheck not installed.'; fi; k_pause;; b) return;; esac
  done
}
