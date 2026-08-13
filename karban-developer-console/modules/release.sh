#!/usr/bin/env bash
# shellcheck shell=bash

k_release_version_manager() {
  local cfg="$KARBAN_ROOT/mobile/src-tauri/tauri.conf.json" current next
  [[ -f "$cfg" ]] || { k_err 'tauri.conf.json not found.'; return 1; }
  current="$(node "$KARBAN_CONSOLE_DIR/scripts/json-read.mjs" "$cfg" version 2>/dev/null || true)"
  next="$(k_prompt 'New semantic version' "$current")"; [[ -n "$next" ]] || return
  if [[ "$KARBAN_ENVIRONMENT" == production ]]; then k_danger_confirm "Change mobile release version from $current to $next." VERSION || return; fi
  node "$KARBAN_CONSOLE_DIR/scripts/json-write.mjs" "$cfg" version "\"$next\""
  if [[ -f "$KARBAN_ROOT/mobile/package.json" ]]; then node "$KARBAN_CONSOLE_DIR/scripts/json-write.mjs" "$KARBAN_ROOT/mobile/package.json" version "\"$next\""; fi
  k_ok "Version updated to $next"
}

k_release_artifact_report() {
  local version out files=(); version="$(k_project_version)"; out="$KARBAN_ARTIFACT_DIR/releases/$version/release-report.json"; mkdir -p "$(dirname "$out")"
  while IFS= read -r f; do files+=("$f"); done < <(find "$KARBAN_ROOT/mobile/src-tauri/gen/android/app/build/outputs" -type f \( -name '*.apk' -o -name '*.aab' \) 2>/dev/null || true)
  node "$KARBAN_CONSOLE_DIR/scripts/release-report.mjs" "$out" "${files[@]}"
  {
    echo "Karban release $version"; echo "Generated: $(date -Is 2>/dev/null || date)"; echo "Environment: $KARBAN_ENVIRONMENT"; echo "Git branch: $(k_git_branch)"; echo "Git commit: $(k_git_commit)"; echo "Git dirty: $(k_git_dirty && echo yes || echo no)";
  } > "$(dirname "$out")/release-summary.txt"
  k_ok "Release metadata: $(dirname "$out")"
}

k_release_wizard() {
  k_header 'KARBAN / PRODUCTION RELEASE' 'Quality gate → builds → mobile bundle → checksums/report'
  if k_git_dirty; then k_warn 'Git working tree has uncommitted changes.'; k_yes_no 'Continue release from a dirty working tree?' n || return 0; fi
  [[ "$KARBAN_ENVIRONMENT" == production ]] || k_warn "Console profile is '$KARBAN_ENVIRONMENT', not production."
  k_danger_confirm 'Start a full production release workflow.' RELEASE || return 0
  local failed=0
  k_run_steps_begin 6
  k_run_step 'Console syntax/self-test' "$KARBAN_CONSOLE_DIR/tests/selftest.sh" || failed=1
  k_run_step 'Prisma schema validation' k_prisma validate || failed=1
  k_run_step 'Project quality gate' k_all_quality || failed=1
  (( failed == 0 )) || { k_err 'Release stopped because preflight checks failed.'; k_pause; return 1; }
  k_run_step 'Build backend/admin/mobile/website' k_build_all || failed=1
  if [[ "$(uname -s)" == Linux || "$(uname -s)" == Darwin ]]; then k_run_step 'Build Android AAB' k_android_aab_build || failed=1; else k_warn 'Android build skipped on unsupported host.'; fi
  k_run_step 'Create release report/checksums' k_release_artifact_report || failed=1
  (( failed == 0 )) && k_ok 'Release workflow completed.' || k_err 'Release completed with failures. Review logs before distribution.'
  k_pause
}

k_release_menu() {
  while true; do
    k_header 'KARBAN / RELEASE MANAGEMENT'
    printf '  Version      %s\n  Environment  %s\n  Git          %s @ %s\n' "$(k_project_version)" "$KARBAN_ENVIRONMENT" "$(k_git_branch)" "$(k_git_commit)"
    printf '\n  1  Version manager\n  2  Pre-release quality gate\n  3  Android release APK\n  4  Android release AAB\n  5  Full production release wizard\n  6  Generate checksums/release report\n  7  List release artifacts\n  8  Git status\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in 1) k_release_version_manager; k_pause;; 2) k_all_quality; k_pause;; 3) k_mobile_tool release; k_pause;; 4) k_android_aab_build; k_pause;; 5) k_release_wizard;; 6) k_release_artifact_report; k_pause;; 7) find "$KARBAN_ARTIFACT_DIR/releases" -type f -maxdepth 3 -print 2>/dev/null | sort; k_pause;; 8) git -C "$KARBAN_ROOT" status --short --branch; k_pause;; b) return;; esac
  done
}
