#!/usr/bin/env bash
# shellcheck shell=bash

k_storage_dirs() {
  find "$KARBAN_ROOT/backend" -maxdepth 3 -type d \( -iname '*upload*' -o -iname '*media*' -o -iname '*render*' -o -iname '*invoice*' \) -print 2>/dev/null | head -80
}

k_chromium_doctor() {
  local c=''; for x in chromium chromium-browser google-chrome google-chrome-stable; do command -v "$x" >/dev/null 2>&1 && { c="$(command -v "$x")"; break; }; done
  [[ -n "$c" ]] && k_ok "Chromium/Chrome: $c" || k_warn 'Chromium not found on host; Docker may still provide it.'
  local configured; configured="$(k_env_value "$KARBAN_ROOT/backend/.env" PUPPETEER_EXECUTABLE_PATH)"; [[ -n "$configured" ]] && printf 'Configured executable: %s\n' "$configured"
}

k_storage_menu() {
  while true; do
    k_header 'KARBAN / STORAGE & INVOICE RENDERING' 'Media, PDF/PNG artifacts and 72-hour render lifecycle'
    printf '  State directory usage: '; du -sh "$KARBAN_STATE_DIR" 2>/dev/null | awk '{print $1}' || printf 'unknown\n'
    printf '\n  1  Discover backend media/render directories\n  2  Chromium/Puppeteer doctor\n  3  Find 72-hour invoice cleanup implementation\n  4  Find invoice PDF/PNG rendering implementation\n  5  Show local media/render disk usage\n  6  Find invoice cleanup npm/job scripts\n  7  Run configured invoice cleanup script\n  8  Run cleanup DRY-RUN when supported\n  9  Media upload validation audit\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) k_storage_dirs; k_pause;; 2) k_chromium_doctor; k_pause;; 3) grep -RniE '72|expiresAt|expiry|expired.*render|render.*delete|cleanup' "$KARBAN_ROOT/backend/src" --exclude-dir=node_modules 2>/dev/null | head -160; k_pause;;
      4) grep -RniE 'puppeteer|pdf\(|screenshot\(|png|invoice.*render' "$KARBAN_ROOT/backend/src" 2>/dev/null | head -160; k_pause;; 5) while IFS= read -r d; do du -sh "$d" 2>/dev/null; done < <(k_storage_dirs); k_pause;;
      6) node -e 'const p=require(process.argv[1]); console.log(Object.entries(p.scripts||{}).filter(([k])=>/invoice|render|cleanup|media/.test(k)).map(x=>x.join(" = ")).join("\n"))' "$KARBAN_ROOT/backend/package.json"; k_pause;;
      7) local s; s="$(k_prompt 'npm script name (example: invoice:cleanup)')"; k_run_script_if_present "$KARBAN_ROOT/backend" "$s"; k_pause;;
      8) local s; s="$(k_prompt 'npm script name')"; (cd "$KARBAN_ROOT/backend" && npm run "$s" -- --dry-run); k_pause;;
      9) grep -RniE 'mime|mimetype|max.*size|file.*size|upload' "$KARBAN_ROOT/backend/src" 2>/dev/null | head -160; k_pause;; b) return;; esac
  done
}
