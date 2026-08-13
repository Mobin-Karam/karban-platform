#!/usr/bin/env bash
# shellcheck shell=bash

k_doctor_row_cmd() { local label="$1" cmd="$2"; if command -v "$cmd" >/dev/null 2>&1; then k_status_row "$label" READY "$(command -v "$cmd")"; else k_status_row "$label" MISSING; fi; }

k_full_doctor() {
  k_header 'KARBAN / SYSTEM DOCTOR' 'No secrets are printed'
  k_doctor_row_cmd Node node; k_doctor_row_cmd npm npm; k_doctor_row_cmd Docker docker; k_doctor_row_cmd PostgreSQL psql; k_doctor_row_cmd pg_dump pg_dump; k_doctor_row_cmd Git git; k_doctor_row_cmd Cargo cargo; k_doctor_row_cmd adb adb; k_doctor_row_cmd Java java; k_doctor_row_cmd keytool keytool
  [[ "$(uname -s)" == Darwin ]] && k_doctor_row_cmd Xcode xcodebuild
  printf '\n'; k_status_dashboard
  printf '\n'; k_integration_env_status
}

k_support_bundle() {
  local out tmp; out="$KARBAN_ARTIFACT_DIR/support/karban-support-$(k_now).tar.gz"; tmp="$(mktemp -d)"; mkdir -p "$(dirname "$out")"
  {
    echo "generated=$(date -Is 2>/dev/null || date)"; echo "environment=$KARBAN_ENVIRONMENT"; echo "api=$(k_mask_url "$KARBAN_API_URL")"; echo "git_branch=$(k_git_branch)"; echo "git_commit=$(k_git_commit)"; echo "uname=$(uname -a)";
    for c in node npm docker cargo adb java; do printf '%s=' "$c"; "$c" --version 2>&1 | head -1 || true; done
  } > "$tmp/system.txt"
  [[ -f "$KARBAN_ROOT/backend/.env.example" ]] && cp "$KARBAN_ROOT/backend/.env.example" "$tmp/backend.env.example"
  [[ -f "$KARBAN_ROOT/mobile/src-tauri/tauri.conf.json" ]] && cp "$KARBAN_ROOT/mobile/src-tauri/tauri.conf.json" "$tmp/tauri.conf.json"
  tail -n 300 "$KARBAN_LOG_DIR"/*.log 2>/dev/null | k_redact_stream > "$tmp/recent-console.log" || true
  (cd "$tmp" && tar -czf "$out" .); rm -rf "$tmp"; k_ok "Support bundle: $out"
}

k_diagnostics_menu() {
  while true; do
    k_header 'KARBAN / DIAGNOSTICS'
    printf '  1  Full system doctor\n  2  Android doctor\n  3  Database connection test\n  4  API health test\n  5  Port/listener report\n  6  Git status\n  7  Secret-literal scan\n  8  Storage/Chromium doctor\n  9  Mobile manifest report\n 10  Create sanitized support bundle\n 11  Console self-test\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) k_full_doctor; k_pause;; 2) k_mobile_tool doctor; k_pause;; 3) k_prisma test-connection; k_pause;; 4) curl -i --max-time 5 "${KARBAN_API_URL%/api/v1}/api/v1/health"; k_pause;;
      5) (ss -lntp 2>/dev/null || lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null || true); k_pause;; 6) git -C "$KARBAN_ROOT" status --short --branch; k_pause;; 7) "$KARBAN_CONSOLE_DIR/scripts/secret-scan.sh" "$KARBAN_ROOT"; k_pause;; 8) k_chromium_doctor; k_pause;; 9) k_mobile_manifest; k_pause;; 10) k_support_bundle; k_pause;; 11) "$KARBAN_CONSOLE_DIR/tests/selftest.sh"; k_pause;; b) return;; esac
  done
}
