#!/usr/bin/env bash
# shellcheck shell=bash

k_mobile_dir() { printf '%s' "$KARBAN_ROOT/mobile"; }
k_mobile_tool() { (cd "$(k_mobile_dir)" && "$KARBAN_CONSOLE_DIR/tools/tauri-android-toolkit.sh" "$@"); }
k_mobile_pm() { k_detect_pm "$(k_mobile_dir)"; }
k_mobile_package_id() { node "$KARBAN_CONSOLE_DIR/scripts/json-read.mjs" "$(k_mobile_dir)/src-tauri/tauri.conf.json" identifier 2>/dev/null || true; }

k_mobile_tauri() {
  local pm; pm="$(k_mobile_pm)"; cd "$(k_mobile_dir)"
  if [[ -x node_modules/.bin/tauri ]]; then node_modules/.bin/tauri "$@"; return; fi
  case "$pm" in npm) npx --no-install tauri "$@";; pnpm) pnpm exec tauri "$@";; yarn) yarn tauri "$@";; bun) bunx --no-install tauri "$@";; esac
}

k_adb() { command -v adb 2>/dev/null || printf '%s' "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}/platform-tools/adb"; }
k_android_devices() { local adb; adb="$(k_adb)"; [[ -x "$adb" || -n "$(command -v adb 2>/dev/null)" ]] || return 1; "$adb" devices -l; }
k_select_serial() {
  local adb serials=() line choice; adb="$(k_adb)"
  while IFS= read -r line; do [[ "$line" == *$'\tdevice'* ]] && serials+=("${line%%$'\t'*}"); done < <("$adb" devices 2>/dev/null)
  (( ${#serials[@]} )) || { k_err 'No authorized Android device/emulator.'; return 1; }
  if (( ${#serials[@]} == 1 )); then K_DEVICE="${serials[0]}"; return 0; fi
  for i in "${!serials[@]}"; do printf '  %d  %s\n' "$((i+1))" "${serials[$i]}"; done
  choice="$(k_prompt 'Device number' 1)"; K_DEVICE="${serials[$((choice-1))]}"
}

k_android_device_info() {
  k_select_serial || return 1; local adb; adb="$(k_adb)"
  k_header 'KARBAN / MOBILE / DEVICE INFORMATION' "$K_DEVICE"
  printf '  Model             %s\n' "$("$adb" -s "$K_DEVICE" shell getprop ro.product.model | tr -d '\r')"
  printf '  Manufacturer      %s\n' "$("$adb" -s "$K_DEVICE" shell getprop ro.product.manufacturer | tr -d '\r')"
  printf '  Android           %s (API %s)\n' "$("$adb" -s "$K_DEVICE" shell getprop ro.build.version.release | tr -d '\r')" "$("$adb" -s "$K_DEVICE" shell getprop ro.build.version.sdk | tr -d '\r')"
  printf '  ABI               %s\n' "$("$adb" -s "$K_DEVICE" shell getprop ro.product.cpu.abi | tr -d '\r')"
  printf '  Resolution        %s\n' "$("$adb" -s "$K_DEVICE" shell wm size 2>/dev/null | tail -1 | tr -d '\r')"
  printf '  Current user      %s\n' "$("$adb" -s "$K_DEVICE" shell am get-current-user 2>/dev/null | tr -d '\r')"
  printf '  Battery           %s\n' "$("$adb" -s "$K_DEVICE" shell dumpsys battery | awk -F': ' '/level:/{print $2"%"; exit}' | tr -d '\r')"
  local pkg; pkg="$(k_mobile_package_id)"; if [[ -n "$pkg" ]]; then
    printf '  Karban package    %s\n' "$pkg"
    "$adb" -s "$K_DEVICE" shell dumpsys package "$pkg" 2>/dev/null | grep -E 'versionName=|versionCode=' | head -4 | sed 's/^/  /' || true
  fi
}

k_android_logcat() {
  k_select_serial || return 1; local adb pkg pid; adb="$(k_adb)"; pkg="$(k_mobile_package_id)"
  pid="$("$adb" -s "$K_DEVICE" shell pidof "$pkg" 2>/dev/null | tr -d '\r' || true)"
  k_info "Live logs for $pkg on $K_DEVICE. Ctrl+C returns."
  if [[ -n "$pid" ]]; then "$adb" -s "$K_DEVICE" logcat --pid="$pid"; else "$adb" -s "$K_DEVICE" logcat | grep --line-buffered -Ei "${pkg//./\\.}|tauri|chromium"; fi
}

k_android_clear_logcat() { k_select_serial || return 1; "$(k_adb)" -s "$K_DEVICE" logcat -c; k_ok 'Logcat cleared.'; }

k_android_screenshot() {
  k_select_serial || return 1; local adb out remote; adb="$(k_adb)"; out="$KARBAN_ARTIFACT_DIR/screenshots"; mkdir -p "$out"; remote="/sdcard/karban-$(k_now).png"
  "$adb" -s "$K_DEVICE" shell screencap -p "$remote" && "$adb" -s "$K_DEVICE" pull "$remote" "$out/" >/dev/null && "$adb" -s "$K_DEVICE" shell rm "$remote"
  k_ok "Screenshot saved in $out"
}

k_android_record() {
  k_select_serial || return 1; local adb out remote seconds; adb="$(k_adb)"; out="$KARBAN_ARTIFACT_DIR/recordings"; mkdir -p "$out"; seconds="$(k_prompt 'Recording seconds' 30)"; remote="/sdcard/karban-recording-$(k_now).mp4"
  k_info "Recording for ${seconds}s..."; "$adb" -s "$K_DEVICE" shell screenrecord --time-limit "$seconds" "$remote"; "$adb" -s "$K_DEVICE" pull "$remote" "$out/" >/dev/null; "$adb" -s "$K_DEVICE" shell rm "$remote"; k_ok "Recording saved in $out"
}

k_android_app_action() {
  k_select_serial || return 1; local adb pkg action; adb="$(k_adb)"; pkg="$(k_mobile_package_id)"; action="$1"; [[ -n "$pkg" ]] || return 1
  case "$action" in
    launch) "$adb" -s "$K_DEVICE" shell monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 >/dev/null; k_ok 'Launch requested.';;
    stop) "$adb" -s "$K_DEVICE" shell am force-stop "$pkg"; k_ok 'App stopped.';;
    restart) "$adb" -s "$K_DEVICE" shell am force-stop "$pkg"; "$adb" -s "$K_DEVICE" shell monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 >/dev/null; k_ok 'App restarted.';;
    clear-data) k_danger_confirm "Clear all local Karban app data on $K_DEVICE." "$pkg" || return 0; "$adb" -s "$K_DEVICE" shell pm clear "$pkg"; ;;
    uninstall) k_danger_confirm "Uninstall Karban from $K_DEVICE." "$pkg" || return 0; "$adb" -s "$K_DEVICE" uninstall "$pkg";;
    settings) "$adb" -s "$K_DEVICE" shell am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d "package:$pkg" >/dev/null;;
  esac
}

k_android_deeplink() {
  k_select_serial || return 1; local adb url; adb="$(k_adb)"
  url="$(k_prompt 'Deep link URI' 'karban://payment/callback?status=test')"
  "$adb" -s "$K_DEVICE" shell am start -W -a android.intent.action.VIEW -d "$url"
}

k_android_permissions() {
  k_select_serial || return 1; local adb pkg; adb="$(k_adb)"; pkg="$(k_mobile_package_id)"
  k_header 'KARBAN / MOBILE / ANDROID PERMISSIONS'
  "$adb" -s "$K_DEVICE" shell dumpsys package "$pkg" 2>/dev/null | sed -n '/requested permissions:/,/install permissions:/p' | head -120
  printf '\n1 Open app permission settings\n2 Reset runtime permissions\nB Back\nChoose: '; read -r c || c=b
  case "${c,,}" in 1) k_android_app_action settings;; 2) k_danger_confirm 'Reset runtime permission decisions for Karban.' RESET && "$adb" -s "$K_DEVICE" shell pm reset-permissions "$pkg";; esac
}

k_android_network() {
  k_select_serial || return 1; local adb port; adb="$(k_adb)"
  while true; do
    k_header 'KARBAN / MOBILE / DEVICE NETWORK'
    printf '  1  adb reverse API port 3000\n  2  adb reverse Vite port 5173\n  3  List adb reverse mappings\n  4  Remove all reverse mappings\n  5  Test Karban API from host\n  6  Show host LAN addresses\n  B  Back\n\nChoose: '; read -r c || c=b
    case "${c,,}" in
      1|2) [[ "$c" == 1 ]] && port=3000 || port=5173; "$adb" -s "$K_DEVICE" reverse "tcp:$port" "tcp:$port"; k_ok "Reversed tcp:$port"; k_pause;;
      3) "$adb" -s "$K_DEVICE" reverse --list; k_pause;; 4) "$adb" -s "$K_DEVICE" reverse --remove-all; k_pause;;
      5) curl -i --max-time 5 "${KARBAN_API_URL%/api/v1}/api/v1/health"; k_pause;;
      6) (hostname -I 2>/dev/null || ipconfig getifaddr en0 2>/dev/null || ifconfig 2>/dev/null | grep 'inet '); k_pause;; b) return;; esac
  done
}

k_android_emulator_menu() {
  local emulator="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}/emulator/emulator"
  while true; do
    k_header 'KARBAN / MOBILE / EMULATORS'
    printf '  1  List AVDs\n  2  Start AVD\n  3  Cold boot AVD\n  4  Wipe and start AVD (destructive)\n  5  Connected devices\n  B  Back\n\nChoose: '; read -r c || c=b
    case "${c,,}" in
      1) "$emulator" -list-avds; k_pause;;
      2|3|4) local avd; avd="$(k_prompt 'AVD name')"; [[ -n "$avd" ]] || continue; if [[ "$c" == 4 ]]; then k_danger_confirm 'Wipe emulator user data.' "$avd" || continue; "$emulator" -avd "$avd" -wipe-data >/dev/null 2>&1 & elif [[ "$c" == 3 ]]; then "$emulator" -avd "$avd" -no-snapshot-load >/dev/null 2>&1 & else "$emulator" -avd "$avd" >/dev/null 2>&1 & fi; k_ok 'Emulator start requested.'; k_pause;;
      5) k_android_devices; k_pause;; b) return;; esac
  done
}

k_android_aab_build() {
  k_header 'KARBAN / MOBILE / ANDROID AAB' 'Google Play release bundle'
  (cd "$(k_mobile_dir)" && k_mobile_tauri android build --aab)
  local aab; aab="$(find "$(k_mobile_dir)/src-tauri/gen/android/app/build/outputs/bundle" -type f -name '*.aab' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2- || true)"
  [[ -n "$aab" ]] && { sha256sum "$aab" 2>/dev/null || shasum -a 256 "$aab"; k_ok "$aab"; }
}

k_mobile_quality() {
  local dir; dir="$(k_mobile_dir)"; k_header 'KARBAN / MOBILE / QUALITY GATE'
  k_run_steps_begin 6
  k_run_step 'Install/check dependencies' bash -c "[[ -d '$dir/node_modules' ]] || true" || true
  k_has_script "$dir" typecheck && k_run_step 'TypeScript typecheck' k_run_script_if_present "$dir" typecheck || k_warn 'No typecheck script.'
  k_has_script "$dir" test && k_run_step 'Frontend tests' k_run_script_if_present "$dir" test || k_warn 'No test script.'
  k_has_script "$dir" build && k_run_step 'Frontend build' k_run_script_if_present "$dir" build || k_warn 'No build script.'
  if k_cmd_exists cargo; then k_run_step 'cargo check' bash -c "cd '$dir/src-tauri' && cargo check" || true; k_run_step 'cargo fmt --check' bash -c "cd '$dir/src-tauri' && cargo fmt -- --check" || true; else k_warn 'Cargo unavailable.'; fi
}

k_mobile_manifest() { k_header 'KARBAN / MOBILE / MANIFEST'; node "$KARBAN_CONSOLE_DIR/scripts/mobile-manifest-report.mjs" "$(k_mobile_dir)"; }

k_mobile_artifacts() {
  k_header 'KARBAN / MOBILE / ARTIFACTS'
  find "$(k_mobile_dir)/src-tauri/gen" "$KARBAN_ARTIFACT_DIR" -type f \( -name '*.apk' -o -name '*.aab' -o -name '*.ipa' -o -name '*.mp4' -o -name '*.png' \) -printf '%TY-%Tm-%Td %TH:%TM  %10s  %p\n' 2>/dev/null | sort -r | head -100 || true
}

k_ios_menu() {
  while true; do
    k_header 'KARBAN / MOBILE / iOS' 'Available on macOS with Xcode'
    if [[ "$(uname -s)" != Darwin ]]; then k_warn 'iOS build/simulator workflows require macOS.'; k_pause; return; fi
    printf '  1  iOS environment doctor\n  2  Initialize Tauri iOS target\n  3  Run iOS development mode\n  4  Build iOS release\n  5  List simulators\n  6  Open generated Xcode project\n  B  Back\n\nChoose: '; read -r c || c=b
    case "${c,,}" in
      1) xcodebuild -version; xcrun simctl list devices available | head -80; k_pause;; 2) k_mobile_tauri ios init; k_pause;; 3) k_mobile_tauri ios dev;; 4) k_mobile_tauri ios build; k_pause;;
      5) xcrun simctl list devices available; k_pause;; 6) local p; p="$(find "$(k_mobile_dir)/src-tauri/gen/apple" -maxdepth 2 -name '*.xcodeproj' -o -name '*.xcworkspace' 2>/dev/null | head -1)"; [[ -n "$p" ]] && open "$p" || k_warn 'Generated Xcode project not found.';; b) return;; esac
  done
}

k_android_menu() {
  while true; do
    k_header 'KARBAN / MOBILE / ANDROID' "Environment: ${KARBAN_ENVIRONMENT^^}"
    printf '  1  Run Tauri Android toolkit\n  2  Android doctor\n  3  Initialize target\n  4  Hot reload / tauri android dev\n  5  Build debug APK\n  6  Build release APK\n  7  Build release AAB\n  8  APK manager\n  9  Signing/key manager\n 10  Devices & device info\n 11  Emulator manager\n 12  App control\n 13  Live logcat\n 14  Screenshots & recording\n 15  Deep-link tester\n 16  Permissions\n 17  Network / adb reverse\n 18  Manifest report\n 19  Mobile quality gate\n 20  Artifacts\n  B  Back\n\nChoose: '; read -r c || c=b
    case "${c,,}" in
      1) k_mobile_tool menu;; 2) k_mobile_tool doctor; k_pause;; 3) k_mobile_tool init; k_pause;; 4) (cd "$(k_mobile_dir)" && k_mobile_tauri android dev);;
      5) k_mobile_tool debug; k_pause;; 6) k_mobile_tool release; k_pause;; 7) k_android_aab_build; k_pause;; 8) k_mobile_tool apks;; 9) k_mobile_tool key;;
      10) k_android_device_info; k_pause;; 11) k_android_emulator_menu;;
      12) k_choose 'App action' 'Launch' 'Stop' 'Restart' 'Open app settings' 'Clear app data' 'Uninstall'; case "$K_REPLY" in 1) k_android_app_action launch;; 2) k_android_app_action stop;; 3) k_android_app_action restart;; 4) k_android_app_action settings;; 5) k_android_app_action clear-data;; 6) k_android_app_action uninstall;; esac; k_pause;;
      13) k_android_logcat;; 14) k_choose 'Capture' 'Screenshot' 'Screen recording'; [[ "$K_REPLY" == 1 ]] && k_android_screenshot || k_android_record; k_pause;; 15) k_android_deeplink; k_pause;; 16) k_android_permissions; k_pause;; 17) k_android_network;; 18) k_mobile_manifest; k_pause;; 19) k_mobile_quality; k_pause;; 20) k_mobile_artifacts; k_pause;; b) return;; esac
  done
}

k_mobile_menu() {
  while true; do
    k_header 'KARBAN / MOBILE DEVELOPER CONSOLE' 'Tauri 2 • React • Android • iOS'
    k_mobile_manifest 2>/dev/null || true
    printf '\n  1  Android\n  2  iOS\n  3  Install mobile dependencies\n  4  Frontend development server\n  5  Mobile quality gate\n  6  Mobile artifacts\n  7  Environment/API settings\n  B  Back\n\nChoose: '; read -r c || c=b
    case "${c,,}" in 1) k_android_menu;; 2) k_ios_menu;; 3) k_pm_install "$(k_mobile_dir)"; k_pause;; 4) k_run_script_if_present "$(k_mobile_dir)" dev;; 5) k_mobile_quality; k_pause;; 6) k_mobile_artifacts; k_pause;; 7) k_environment_menu;; b) return;; esac
  done
}
