#!/usr/bin/env bash
# shellcheck shell=bash

k_build_one() { local dir="$1" label="$2"; k_header "KARBAN / BUILD / $label"; k_run_script_if_present "$dir" build; }

k_build_all() {
  k_header 'KARBAN / BUILD ALL' "Environment: ${KARBAN_ENVIRONMENT^^}"
  local failed=0
  for spec in "backend:BACKEND" "admin:ADMIN" "mobile:MOBILE" "website:WEBSITE"; do
    IFS=: read -r d l <<<"$spec"
    k_section "$l"
    k_log_run "build-${d}" k_run_script_if_present "$KARBAN_ROOT/$d" build || failed=1
  done
  return "$failed"
}

k_build_menu() {
  while true; do
    k_header 'KARBAN / BUILDS & ARTIFACTS'
    printf '  1  Build backend\n  2  Build admin\n  3  Build mobile frontend\n  4  Build website\n  5  Build all web/API projects\n  6  Android debug APK\n  7  Android release APK\n  8  Android release AAB\n  9  Mobile artifacts\n 10  Full production release wizard\n 11  Clean build outputs\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) k_build_one "$KARBAN_ROOT/backend" BACKEND; k_pause;; 2) k_build_one "$KARBAN_ROOT/admin" ADMIN; k_pause;; 3) k_build_one "$KARBAN_ROOT/mobile" MOBILE; k_pause;; 4) k_build_one "$KARBAN_ROOT/website" WEBSITE; k_pause;;
      5) k_build_all; k_pause;; 6) k_mobile_tool debug; k_pause;; 7) k_mobile_tool release; k_pause;; 8) k_android_aab_build; k_pause;; 9) k_mobile_artifacts; k_pause;; 10) k_release_wizard;;
      11) k_danger_confirm 'Remove generated build outputs (not source or dependencies).' CLEAN || continue; rm -rf "$KARBAN_ROOT/backend/dist" "$KARBAN_ROOT/admin/dist" "$KARBAN_ROOT/mobile/dist" "$KARBAN_ROOT/website/.next"; k_ok 'Build outputs removed.'; k_pause;; b) return;; esac
  done
}
