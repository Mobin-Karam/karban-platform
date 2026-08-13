#!/usr/bin/env bash
# shellcheck shell=bash
k_admin_advanced() {
  while true; do
    k_header 'KARBAN / ADMIN PWA / ADVANCED'
    printf '  1  Inspect PWA/service-worker files\n  2  Check manifest JSON\n  3  Find update-modal/service-worker registration\n  4  Preview production build\n  5  Clear local build artifacts\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) find "$KARBAN_ROOT/admin" -maxdepth 3 -type f \( -iname '*manifest*' -o -iname '*service-worker*' -o -iname 'sw.*' \) -print; k_pause;;
      2) for f in "$KARBAN_ROOT/admin"/public/*manifest*.json; do [[ -f "$f" ]] && node --check "$f" 2>/dev/null || true; done; k_pause;;
      3) grep -RniE 'registerSW|serviceWorker|update.*available|skipWaiting' "$KARBAN_ROOT/admin/src" "$KARBAN_ROOT/admin"/vite.config.* 2>/dev/null | head -80; k_pause;;
      4) k_run_script_if_present "$KARBAN_ROOT/admin" preview;;
      5) rm -rf "$KARBAN_ROOT/admin/dist"; k_ok 'admin/dist removed.'; k_pause;;
      b) return;; esac
  done
}
k_admin_menu() { k_generic_app_menu "$KARBAN_ROOT/admin" 'ADMIN PWA' k_admin_advanced; }
