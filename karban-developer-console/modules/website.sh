#!/usr/bin/env bash
# shellcheck shell=bash
k_website_advanced() {
  while true; do
    k_header 'KARBAN / MARKETING WEBSITE / ADVANCED'
    printf '  1  SEO file audit\n  2  Find structured data\n  3  Find eNamad component\n  4  Check screenshot/video placeholders\n  5  Clear .next\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) find "$KARBAN_ROOT/website" -maxdepth 4 -type f \( -name 'sitemap.*' -o -name 'robots.*' -o -name 'manifest.*' \) -print; k_pause;;
      2) grep -RniE 'application/ld\+json|schema.org|structured' "$KARBAN_ROOT/website" --exclude-dir=node_modules --exclude-dir=.next 2>/dev/null | head -80; k_pause;;
      3) grep -Rni 'trustseal.enamad.ir' "$KARBAN_ROOT/website" --exclude-dir=node_modules 2>/dev/null | head -20; k_pause;;
      4) grep -RniE 'skeleton|screenshot|video' "$KARBAN_ROOT/website/app" "$KARBAN_ROOT/website/src" 2>/dev/null | head -80; k_pause;;
      5) rm -rf "$KARBAN_ROOT/website/.next"; k_ok '.next removed.'; k_pause;;
      b) return;; esac
  done
}
k_website_menu() { k_generic_app_menu "$KARBAN_ROOT/website" 'MARKETING WEBSITE' k_website_advanced; }
