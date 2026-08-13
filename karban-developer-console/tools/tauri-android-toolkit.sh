#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

# ============================================================
# Tauri Android Toolkit
# Run this script from the root of any Tauri v2 app.
# ============================================================

VERSION="1.1.1"
ROOT="$(pwd -P)"
STATE_DIR=".tauri-mobile"
KEY_DIR="$STATE_DIR/keys"
OUT_DIR="$STATE_DIR/output"
CONFIG_FILE="$STATE_DIR/config.env"

# ---------- Colors ----------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RESET=$'\033[0m'; BOLD=$'\033[1m'; DIM=$'\033[2m'
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CYAN=$'\033[36m'
else
  RESET=""; BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""
fi

cleanup() {
  unset TAURI_MOBILE_STORE_PASS 2>/dev/null || true
  unset TAURI_MOBILE_KEY_PASS 2>/dev/null || true
}
trap cleanup EXIT
trap 'printf "\n%bInterrupted.%b\n" "$YELLOW" "$RESET"; exit 130' INT TERM

# ---------- UI helpers ----------
line() {
  local ch="${1:--}" n="${2:-72}"
  printf '%*s\n' "$n" '' | tr ' ' "$ch"
}

clear_screen() {
  [[ -t 1 ]] && printf '\033[2J\033[H' || true
}

header() {
  clear_screen
  printf '%b' "$CYAN$BOLD"
  line '=' 72
  printf '  TAURI ANDROID TOOLKIT  v%s\n' "$VERSION"
  printf '%b' "$RESET$DIM"
  printf '  BUILD | SIGN | INSTALL | DEVICES | DOCTOR\n'
  printf '%b' "$RESET$CYAN$BOLD"
  line '=' 72
  printf '%b' "$RESET"
}

section() {
  printf '\n%b%s%b\n' "$BOLD" "$1" "$RESET"
  printf '%b' "$DIM"; line '-' 72; printf '%b' "$RESET"
}

info()    { printf '%b[INFO]%b %s\n' "$BLUE$BOLD" "$RESET" "$*"; }
ok()      { printf '%b[ OK ]%b %s\n' "$GREEN$BOLD" "$RESET" "$*"; }
warn()    { printf '%b[WARN]%b %s\n' "$YELLOW$BOLD" "$RESET" "$*"; }
err()     { printf '%b[ERR ]%b %s\n' "$RED$BOLD" "$RESET" "$*" >&2; }
die()     { err "$*"; exit 1; }

pause() {
  [[ -t 0 ]] || return 0
  printf '\n%bPress Enter to continue...%b' "$DIM" "$RESET"
  read -r _ || true
}

ask_yes_no() {
  local prompt="$1" default="${2:-y}" answer suffix
  [[ "$default" == "y" ]] && suffix='Y/n' || suffix='y/N'
  while true; do
    printf '%b%s%b [%s]: ' "$BOLD" "$prompt" "$RESET" "$suffix"
    read -r answer || answer=""
    answer="${answer:-$default}"
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) warn 'Please answer y or n.' ;;
    esac
  done
}

prompt_value() {
  local prompt="$1" default="${2:-}" value
  if [[ -n "$default" ]]; then
    printf '%b%s%b [%s]: ' "$BOLD" "$prompt" "$RESET" "$default" >&2
  else
    printf '%b%s%b: ' "$BOLD" "$prompt" "$RESET" >&2
  fi
  read -r value || value=""
  printf '%s' "${value:-$default}"
}

prompt_secret() {
  local prompt="$1" value
  printf '%b%s%b: ' "$BOLD" "$prompt" "$RESET" >&2
  IFS= read -r -s value || value=""
  printf '\n' >&2
  printf '%s' "$value"
}

choose() {
  local title="$1"; shift
  local options=("$@") i choice
  printf '\n%b%s%b\n' "$BOLD" "$title" "$RESET"
  for i in "${!options[@]}"; do
    printf '  %b%2d%b) %s\n' "$CYAN$BOLD" "$((i+1))" "$RESET" "${options[$i]}"
  done
  while true; do
    printf '%bSelect%b [1-%d]: ' "$BOLD" "$RESET" "${#options[@]}"
    read -r choice || choice=""
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
      REPLY="$choice"
      return 0
    fi
    warn 'Invalid selection.'
  done
}

# ---------- General helpers ----------
command_exists() { command -v "$1" >/dev/null 2>&1; }

abs_path() {
  local p="$1"
  if command_exists realpath; then realpath "$p"; else readlink -f "$p"; fi
}

human_size() { du -h "$1" 2>/dev/null | awk '{print $1}'; }
mtime_label() { date -r "$1" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || printf 'unknown'; }
slugify() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'; }

ensure_project_root() {
  if [[ ! -f package.json || ! -d src-tauri || ! -f src-tauri/Cargo.toml ]]; then
    header
    err 'Run this script from the root directory of a Tauri v2 app.'
    printf '\nExpected:\n  package.json\n  src-tauri/Cargo.toml\n\nExample:\n  cd ~/Projects/my-tauri-app\n  ./install-android.sh\n'
    exit 1
  fi
}

ensure_state_dirs() {
  mkdir -p "$STATE_DIR" "$KEY_DIR" "$OUT_DIR"
  chmod 700 "$STATE_DIR" "$KEY_DIR" 2>/dev/null || true
  if [[ -f .gitignore ]]; then
    grep -Fxq '/.tauri-mobile/' .gitignore || printf '\n/.tauri-mobile/\n' >> .gitignore
  else
    printf '/.tauri-mobile/\n' > .gitignore
  fi
}

# ---------- Read project metadata ----------
json_value() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 1
  command_exists node || return 1
  node - "$file" "$key" <<'NODE' 2>/dev/null || true
const fs = require('fs');
const [file, key] = process.argv.slice(2);
try {
  let value = JSON.parse(fs.readFileSync(file, 'utf8'));
  for (const part of key.split('.')) value = value?.[part];
  if (['string','number','boolean'].includes(typeof value)) process.stdout.write(String(value));
} catch (_) {}
NODE
}

first_tauri_config() {
  local f
  for f in src-tauri/tauri.conf.json src-tauri/tauri.conf.json5 src-tauri/Tauri.toml src-tauri/tauri.conf.toml; do
    [[ -f "$f" ]] && { printf '%s' "$f"; return 0; }
  done
  return 1
}

extract_loose_config_value() {
  local file="$1" key="$2"
  grep -E "[\"']?${key}[\"']?[[:space:]]*[:=]" "$file" 2>/dev/null \
    | head -n 1 \
    | sed -E "s/.*[\"']?${key}[\"']?[[:space:]]*[:=][[:space:]]*[\"']?([^\"',}]+).*/\1/" \
    | xargs 2>/dev/null || true
}

detect_project_metadata() {
  local cfg product_name="" package_name="" identifier=""
  cfg="$(first_tauri_config || true)"

  if [[ -n "$cfg" ]]; then
    product_name="$(json_value "$cfg" productName || true)"
    identifier="$(json_value "$cfg" identifier || true)"
    [[ -n "$product_name" ]] || product_name="$(extract_loose_config_value "$cfg" productName)"
    [[ -n "$identifier" ]] || identifier="$(extract_loose_config_value "$cfg" identifier)"
  fi

  package_name="$(json_value package.json name || true)"

  if [[ -z "$identifier" && -f src-tauri/gen/android/app/build.gradle.kts ]]; then
    identifier="$(grep -E 'applicationId[[:space:]]*=' src-tauri/gen/android/app/build.gradle.kts 2>/dev/null \
      | head -n 1 | sed -E 's/.*=[[:space:]]*"([^"]+)".*/\1/' || true)"
  fi

  APP_NAME="${product_name:-${package_name:-$(basename "$ROOT")}}"
  PACKAGE_ID="${identifier:-}"
  APP_SLUG="$(slugify "$APP_NAME")"
  [[ -n "$APP_SLUG" ]] || APP_SLUG='tauri-app'
}

# ---------- Package manager ----------
detect_package_manager() {
  if [[ -f pnpm-lock.yaml ]]; then PACKAGE_MANAGER='pnpm'
  elif [[ -f yarn.lock ]]; then PACKAGE_MANAGER='yarn'
  elif [[ -f bun.lockb || -f bun.lock ]]; then PACKAGE_MANAGER='bun'
  else PACKAGE_MANAGER='npm'
  fi
}

install_dependencies() {
  [[ -d node_modules ]] && return 0
  section 'Dependencies'
  ask_yes_no 'Install project dependencies now?' y || die 'Dependencies are required.'
  case "$PACKAGE_MANAGER" in
    npm)  [[ -f package-lock.json ]] && npm ci || npm install ;;
    pnpm) command_exists pnpm || die 'pnpm is required.'; pnpm install ;;
    yarn) command_exists yarn || die 'yarn is required.'; yarn install ;;
    bun)  command_exists bun  || die 'bun is required.'; bun install ;;
  esac
}

run_tauri() {
  if [[ -x node_modules/.bin/tauri ]]; then
    node_modules/.bin/tauri "$@"
    return
  fi
  case "$PACKAGE_MANAGER" in
    npm)  npx --no-install tauri "$@" ;;
    pnpm) pnpm exec tauri "$@" ;;
    yarn) yarn tauri "$@" ;;
    bun)  bunx --no-install tauri "$@" ;;
  esac
}

# ---------- Config ----------
load_config() {
  KEYSTORE_PATH="${TAURI_MOBILE_KEYSTORE:-}"
  KEY_ALIAS="${TAURI_MOBILE_KEY_ALIAS:-}"
  LAST_DEVICE=""
  if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
  fi
  KEYSTORE_PATH="${TAURI_MOBILE_KEYSTORE:-${KEYSTORE_PATH:-}}"
  KEY_ALIAS="${TAURI_MOBILE_KEY_ALIAS:-${KEY_ALIAS:-}}"
}

save_config() {
  ensure_state_dirs
  {
    printf 'KEYSTORE_PATH=%q\n' "${KEYSTORE_PATH:-}"
    printf 'KEY_ALIAS=%q\n' "${KEY_ALIAS:-}"
    printf 'LAST_DEVICE=%q\n' "${LAST_DEVICE:-}"
  } > "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE" 2>/dev/null || true
}

# ---------- Android SDK tools ----------
sdk_root() {
  local candidates=("${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk" "$HOME/Library/Android/sdk") c
  for c in "${candidates[@]}"; do
    [[ -n "$c" && -d "$c" ]] && { printf '%s' "$c"; return 0; }
  done
  return 1
}

latest_build_tools_dir() {
  local root="$1"
  [[ -d "$root/build-tools" ]] || return 1
  find "$root/build-tools" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
    | sort -V | tail -n 1 | awk -v root="$root" '{print root "/build-tools/" $0}'
}

resolve_android_tools() {
  SDK_ROOT="$(sdk_root || true)"
  ADB_BIN="$(command -v adb 2>/dev/null || true)"
  KEYTOOL_BIN="$(command -v keytool 2>/dev/null || true)"
  APKSIGNER_BIN="$(command -v apksigner 2>/dev/null || true)"
  ZIPALIGN_BIN="$(command -v zipalign 2>/dev/null || true)"
  AAPT_BIN="$(command -v aapt 2>/dev/null || true)"

  if [[ -n "$SDK_ROOT" ]]; then
    [[ -n "$ADB_BIN" ]] || [[ ! -x "$SDK_ROOT/platform-tools/adb" ]] || ADB_BIN="$SDK_ROOT/platform-tools/adb"
    local bt="$(latest_build_tools_dir "$SDK_ROOT" || true)"
    if [[ -n "$bt" ]]; then
      [[ -n "$APKSIGNER_BIN" ]] || [[ ! -x "$bt/apksigner" ]] || APKSIGNER_BIN="$bt/apksigner"
      [[ -n "$ZIPALIGN_BIN" ]]  || [[ ! -x "$bt/zipalign"  ]] || ZIPALIGN_BIN="$bt/zipalign"
      [[ -n "$AAPT_BIN" ]]      || [[ ! -x "$bt/aapt"      ]] || AAPT_BIN="$bt/aapt"
    fi
  fi

  if [[ -z "$KEYTOOL_BIN" ]]; then
    local c
    for c in "${JAVA_HOME:-}/bin/keytool" /opt/android-studio/jbr/bin/keytool /usr/local/android-studio/jbr/bin/keytool; do
      [[ -n "$c" && -x "$c" ]] && { KEYTOOL_BIN="$c"; break; }
    done
  fi
}

ensure_build_tools() {
  resolve_android_tools
  [[ -n "$SDK_ROOT" ]] || die 'Android SDK not found. Set ANDROID_HOME or ANDROID_SDK_ROOT.'
  [[ -n "$APKSIGNER_BIN" && -x "$APKSIGNER_BIN" ]] || die 'apksigner not found. Install Android SDK Build-Tools.'
  [[ -n "$ZIPALIGN_BIN" && -x "$ZIPALIGN_BIN" ]] || die 'zipalign not found. Install Android SDK Build-Tools.'
}

# ---------- Doctor ----------
doctor() {
  header
  resolve_android_tools
  section 'Environment doctor'
  local failed=0
  check_row() {
    local label="$1" value="$2"
    if [[ -n "$value" ]]; then
      printf '  %bPASS%b  %-20s %s\n' "$GREEN$BOLD" "$RESET" "$label" "$value"
    else
      printf '  %bFAIL%b  %-20s %s\n' "$RED$BOLD" "$RESET" "$label" 'missing'
      failed=1
    fi
  }
  check_row Node "$(command -v node 2>/dev/null || true)"
  check_row "$PACKAGE_MANAGER" "$(command -v "$PACKAGE_MANAGER" 2>/dev/null || true)"
  check_row Cargo "$(command -v cargo 2>/dev/null || true)"
  check_row 'Android SDK' "$SDK_ROOT"
  check_row adb "$ADB_BIN"
  check_row keytool "$KEYTOOL_BIN"
  check_row apksigner "$APKSIGNER_BIN"
  check_row zipalign "$ZIPALIGN_BIN"
  check_row 'Tauri CLI' "$([[ -x node_modules/.bin/tauri ]] && printf '%s' node_modules/.bin/tauri || true)"
  printf '\n'
  (( failed == 0 )) && ok 'Environment looks ready.' || warn 'One or more tools are missing.'
  return "$failed"
}

# ---------- Tauri Android init/build ----------
ensure_android_initialized() {
  [[ -d src-tauri/gen/android ]] && return 0
  section 'Android initialization'
  warn 'Tauri Android has not been initialized for this project.'
  ask_yes_no "Run 'tauri android init' now?" y || die 'Android initialization is required.'
  install_dependencies
  run_tauri android init
  ok 'Android target initialized.'
}

find_latest_build_apk() {
  [[ -d src-tauri/gen/android/app/build/outputs/apk ]] || return 0
  find src-tauri/gen/android/app/build/outputs/apk -type f -name '*.apk' -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr | head -n 1 | cut -d' ' -f2- || true
}

build_apk() {
  local mode="$1"
  ensure_android_initialized
  install_dependencies
  section "Build $mode APK"
  if [[ "$mode" == 'debug' ]]; then
    info 'Building debug APK...'
    run_tauri android build --debug --apk
  else
    info 'Building release APK...'
    run_tauri android build --apk
  fi
  local apk="$(find_latest_build_apk)"
  [[ -n "$apk" && -f "$apk" ]] || die 'Build completed but no APK was found.'
  LAST_APK="$(abs_path "$apk")"
  ok 'APK built successfully.'
  printf '\n  Path: %s\n  Size: %s\n' "$LAST_APK" "$(human_size "$LAST_APK")"
}

# ---------- APK discovery/signature ----------
collect_apks() {
  APKS=()
  local file absolute existing seen
  while IFS= read -r file; do
    [[ -n "$file" && -f "$file" ]] || continue
    absolute="$(abs_path "$file")"
    seen=0
    for existing in "${APKS[@]:-}"; do [[ "$existing" == "$absolute" ]] && { seen=1; break; }; done
    (( seen == 0 )) && APKS+=("$absolute")
  done < <(find . -type f -name '*.apk' -not -path './node_modules/*' -not -path './src-tauri/target/*' \
    -printf '%T@ %p\n' 2>/dev/null | sort -nr | cut -d' ' -f2-)
}

apk_signature_state() {
  local apk="$1"
  resolve_android_tools
  [[ -n "$APKSIGNER_BIN" && -x "$APKSIGNER_BIN" ]] || { printf 'unknown'; return 0; }
  if "$APKSIGNER_BIN" verify "$apk" >/dev/null 2>&1; then printf 'signed'; else printf 'unsigned'; fi
}

apk_package_id() {
  local apk="$1"
  resolve_android_tools
  [[ -n "$AAPT_BIN" && -x "$AAPT_BIN" ]] || return 0
  "$AAPT_BIN" dump badging "$apk" 2>/dev/null | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n 1
}

apk_row() {
  local apk="$1" state label
  state="$(apk_signature_state "$apk")"
  case "$state" in
    signed) label="${GREEN}SIGNED${RESET}" ;;
    unsigned) label="${YELLOW}UNSIGNED${RESET}" ;;
    *) label="${DIM}UNKNOWN${RESET}" ;;
  esac
  printf '%b | %6s | %s | %s' "$label" "$(human_size "$apk")" "$(mtime_label "$apk")" "${apk#$ROOT/}"
}

select_apk() {
  collect_apks
  (( ${#APKS[@]} > 0 )) || { warn 'No APK files were found.'; return 1; }
  section 'APK selector'
  local i choice
  for i in "${!APKS[@]}"; do
    printf '  %b%2d%b) ' "$CYAN$BOLD" "$((i+1))" "$RESET"
    apk_row "${APKS[$i]}"; printf '\n'
  done
  printf '  %b 0%b) Back\n' "$DIM" "$RESET"
  while true; do
    printf '%bSelect APK%b [0-%d]: ' "$BOLD" "$RESET" "${#APKS[@]}"
    read -r choice || choice=0
    [[ "$choice" == '0' ]] && return 1
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#APKS[@]} )); then
      SELECTED_APK="${APKS[$((choice-1))]}"
      return 0
    fi
    warn 'Invalid selection.'
  done
}

# ---------- Keystore ----------
select_existing_keystore() {
  local keys=() file i choice
  while IFS= read -r file; do [[ -f "$file" ]] && keys+=("$(abs_path "$file")"); done < <(
    find . -maxdepth 5 -type f \( -name '*.jks' -o -name '*.keystore' -o -name '*.p12' -o -name '*.pfx' \) \
      -not -path './node_modules/*' -not -path './src-tauri/target/*' -print 2>/dev/null | awk '!seen[$0]++'
  )
  (( ${#keys[@]} > 0 )) || { warn 'No existing keystore was found.'; return 1; }
  printf '\n%bExisting keystores%b\n' "$BOLD" "$RESET"
  for i in "${!keys[@]}"; do printf '  %d) %s\n' "$((i+1))" "${keys[$i]#$ROOT/}"; done
  printf '  0) Cancel\n'
  while true; do
    printf 'Select [0-%d]: ' "${#keys[@]}"; read -r choice || choice=0
    [[ "$choice" == '0' ]] && return 1
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#keys[@]} )); then
      KEYSTORE_PATH="${keys[$((choice-1))]}"
      KEY_ALIAS="$(prompt_value 'Key alias' "${KEY_ALIAS:-upload}")"
      save_config
      ok 'Configured keystore.'
      return 0
    fi
  done
}

generate_keystore() {
  resolve_android_tools
  [[ -n "$KEYTOOL_BIN" && -x "$KEYTOOL_BIN" ]] || die 'keytool not found. Install a JDK or Android Studio JBR.'
  section 'Generate release signing key'
  warn 'Back up this keystore. You need the same key for future app updates.'

  local default_path path alias password confirm dname
  default_path="$ROOT/$KEY_DIR/${APP_SLUG}-release.jks"
  path="$(prompt_value 'Keystore path' "$default_path")"
  [[ "$path" == /* ]] || path="$ROOT/$path"
  alias="$(prompt_value 'Key alias' "${APP_SLUG}-upload")"

  while true; do
    password="$(prompt_secret 'Keystore password (minimum 6 characters)')"
    (( ${#password} >= 6 )) || { warn 'Password must be at least 6 characters.'; continue; }
    confirm="$(prompt_secret 'Confirm keystore password')"
    [[ "$password" == "$confirm" ]] || { warn 'Passwords do not match.'; continue; }
    break
  done

  mkdir -p "$(dirname "$path")"
  [[ ! -e "$path" ]] || die "Keystore already exists: $path"
  dname="CN=${APP_NAME}, OU=Mobile, O=${APP_NAME}, L=Unknown, ST=Unknown, C=US"
  "$KEYTOOL_BIN" -genkeypair -v -keystore "$path" -storetype JKS -alias "$alias" \
    -keyalg RSA -keysize 2048 -validity 10000 -dname "$dname" -storepass "$password" -keypass "$password"
  chmod 600 "$path" 2>/dev/null || true
  KEYSTORE_PATH="$(abs_path "$path")"; KEY_ALIAS="$alias"; save_config
  ok 'Release keystore created.'
  printf '\n  Path:  %s\n  Alias: %s\n' "$KEYSTORE_PATH" "$KEY_ALIAS"
  unset password confirm
}

ensure_keystore() {
  if [[ -n "${KEYSTORE_PATH:-}" && -f "$KEYSTORE_PATH" ]]; then
    [[ -n "${KEY_ALIAS:-}" ]] || KEY_ALIAS="$(prompt_value 'Key alias' upload)"
    save_config
    return 0
  fi
  section 'Release signing key'
  warn 'No release keystore is configured.'
  choose 'Choose signing key action' 'Generate a new release keystore' 'Select an existing keystore' 'Cancel'
  case "$REPLY" in
    1) generate_keystore ;;
    2) select_existing_keystore || return 1 ;;
    3) return 1 ;;
  esac
}

read_keystore_password() {
  local password="${TAURI_MOBILE_KEYSTORE_PASS:-}"
  [[ -n "$password" ]] || password="$(prompt_secret 'Keystore password')"
  [[ -n "$password" ]] || return 1
  export TAURI_MOBILE_STORE_PASS="$password"
  export TAURI_MOBILE_KEY_PASS="${TAURI_MOBILE_KEY_PASS:-$password}"
}

sign_apk() {
  local apk="$1"
  [[ -f "$apk" ]] || die "APK does not exist: $apk"
  if [[ "$(apk_signature_state "$apk")" == 'signed' ]]; then
    ok 'APK is already signed.'; SIGNED_APK="$apk"; return 0
  fi
  ensure_build_tools
  ensure_keystore || return 1
  read_keystore_password || { warn 'Signing cancelled.'; return 1; }
  section 'Sign APK'

  local base aligned signed
  base="$(basename "$apk" .apk)"
  aligned="$OUT_DIR/${base}-aligned.apk"
  signed="$OUT_DIR/${base}-signed.apk"
  mkdir -p "$OUT_DIR"
  rm -f "$aligned" "$signed" "$signed.idsig"

  info 'Aligning APK...'
  "$ZIPALIGN_BIN" -f -p 4 "$apk" "$aligned"
  "$ZIPALIGN_BIN" -c -v 4 "$aligned" >/dev/null

  info 'Signing APK...'
  "$APKSIGNER_BIN" sign \
    --ks "$KEYSTORE_PATH" \
    --ks-key-alias "$KEY_ALIAS" \
    --ks-pass env:TAURI_MOBILE_STORE_PASS \
    --key-pass env:TAURI_MOBILE_KEY_PASS \
    --out "$signed" "$aligned"

  info 'Verifying signature...'
  "$APKSIGNER_BIN" verify --verbose "$signed" >/dev/null
  SIGNED_APK="$(abs_path "$signed")"
  rm -f "$aligned"
  cleanup
  ok 'APK signed and verified.'
  printf '\n  Signed APK: %s\n' "$SIGNED_APK"
}

# ---------- Devices ----------
adb_devices_raw() {
  [[ -n "$ADB_BIN" && -x "$ADB_BIN" ]] || return 1
  "$ADB_BIN" devices -l 2>/dev/null | sed '1d' | sed '/^[[:space:]]*$/d'
}

connected_device_count() {
  resolve_android_tools
  [[ -n "$ADB_BIN" && -x "$ADB_BIN" ]] || { printf '0'; return; }
  adb_devices_raw | awk '$2=="device"{c++} END{print c+0}'
}

wait_for_device_or_exit() {
  resolve_android_tools
  [[ -n "$ADB_BIN" && -x "$ADB_BIN" ]] || die 'adb not found. Install Android SDK Platform-Tools.'
  while (( $(connected_device_count) == 0 )); do
    header; section 'Android device required'
    warn 'No authorized Android device is connected.'
    printf '\nConnect a phone and:\n  1. Enable Developer Options\n  2. Enable USB Debugging\n  3. Connect USB\n  4. Accept the debugging authorization prompt\n\n'
    local raw="$(adb_devices_raw || true)"
    [[ -z "$raw" ]] || { printf 'Detected but unavailable devices:\n\n%s\n\n' "$raw"; }
    choose 'What do you want to do?' 'Retry after connecting a device' 'Exit'
    [[ "$REPLY" == '1' ]] || exit 0
  done
}

select_device() {
  wait_for_device_or_exit
  local lines=() serials=() line serial state model i choice
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    serial="$(awk '{print $1}' <<<"$line")"
    state="$(awk '{print $2}' <<<"$line")"
    [[ "$state" == 'device' ]] || continue
    serials+=("$serial"); lines+=("$line")
  done < <(adb_devices_raw)

  if (( ${#serials[@]} == 1 )); then
    DEVICE_SERIAL="${serials[0]}"
  else
    section 'Connected devices'
    for i in "${!serials[@]}"; do
      model="$(sed -n 's/.*model:\([^ ]*\).*/\1/p' <<<"${lines[$i]}")"
      printf '  %b%2d%b) %-24s %s\n' "$CYAN$BOLD" "$((i+1))" "$RESET" "${serials[$i]}" "${model:-Android device}"
    done
    while true; do
      printf '%bSelect device%b [1-%d]: ' "$BOLD" "$RESET" "${#serials[@]}"
      read -r choice || choice=""
      if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#serials[@]} )); then
        DEVICE_SERIAL="${serials[$((choice-1))]}"; break
      fi
      warn 'Invalid device selection.'
    done
  fi

  LAST_DEVICE="$DEVICE_SERIAL"; save_config
  ADB=("$ADB_BIN" -s "$DEVICE_SERIAL")
  ok "Selected device: $DEVICE_SERIAL"
}

show_devices() {
  header; section 'Android devices'; resolve_android_tools
  [[ -n "$ADB_BIN" ]] || { err 'adb is not installed.'; pause; return; }
  local raw="$(adb_devices_raw || true)"
  [[ -n "$raw" ]] && printf '%s\n' "$raw" || warn 'No Android devices detected.'
  pause
}

# ---------- Install / launch ----------
launch_package() {
  local package="$1" user="${2:-0}" activity=""
  [[ -n "$package" ]] || { warn 'Package identifier is unknown.'; return 1; }
  activity="$("${ADB[@]}" shell cmd package resolve-activity --brief --user "$user" \
    -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p "$package" 2>/dev/null \
    | tail -n 1 | tr -d '\r' || true)"
  if [[ "$activity" == */* ]]; then
    "${ADB[@]}" shell am start --user "$user" -n "$activity" >/dev/null
  else
    "${ADB[@]}" shell monkey --user "$user" -p "$package" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
  fi
  ok "Launch requested for $package"
}

package_registered_on_device() {
  local package="$1"
  [[ -n "$package" ]] || return 1
  "${ADB[@]}" shell pm path "$package" 2>/dev/null \
    | tr -d '\r' \
    | grep -q '^package:'
}

adb_install_file() {
  local apk="$1"
  local android_user="$2"
  local output result

  set +e
  output="$("${ADB[@]}" install --no-incremental --user "$android_user" -r -d "$apk" 2>&1)"
  result=$?

  if (( result != 0 )) && grep -qiE 'unknown option|unrecognized option|--no-incremental' <<<"$output"; then
    output="$("${ADB[@]}" install --user "$android_user" -r -d "$apk" 2>&1)"
    result=$?
  fi
  set -e

  printf '%s\n' "$output"
  return "$result"
}

full_uninstall_package() {
  local package="$1"
  local output result i

  [[ -n "$package" ]] || {
    err 'Could not determine package identifier.'
    return 1
  }

  info "Removing existing package completely: $package"

  # IMPORTANT:
  # Do NOT use `adb uninstall --user ...` here.
  # That only removes the package for one Android user and can leave the package
  # registered on the device. Android will then still reject an APK signed with
  # a different key with INSTALL_FAILED_UPDATE_INCOMPATIBLE.
  set +e
  output="$("${ADB[@]}" uninstall "$package" 2>&1)"
  result=$?
  set -e

  [[ -z "$output" ]] || printf '%s\n' "$output"

  if (( result != 0 )); then
    warn 'adb uninstall did not complete. Trying Package Manager directly.'

    set +e
    output="$("${ADB[@]}" shell pm uninstall "$package" 2>&1)"
    result=$?
    set -e

    [[ -z "$output" ]] || printf '%s\n' "$output"
  fi

  # Package Manager may need a moment to finish removing the package.
  for i in {1..15}; do
    if ! package_registered_on_device "$package"; then
      ok "Old package fully removed: $package"
      return 0
    fi
    sleep 0.2
  done

  err "Package is still registered on the device: $package"
  warn 'Android cannot install the new APK with a different signing key until the old package is fully removed.'
  printf '\n'
  printf 'Try manually:\n'
  printf '  adb -s %q uninstall %q\n' "$DEVICE_SERIAL" "$package"
  printf '\n'
  return 1
}

install_apk() {
  local apk="$1" state package android_user output result
  [[ -f "$apk" ]] || die "APK does not exist: $apk"
  state="$(apk_signature_state "$apk")"

  if [[ "$state" == 'unsigned' ]]; then
    section 'Unsigned APK'
    warn 'This APK is unsigned and Android normally cannot install it.'
    if ask_yes_no 'Create/select a key, sign it, and continue?' y; then
      sign_apk "$apk" || return 1
      apk="$SIGNED_APK"
    else
      return 0
    fi
  elif [[ "$state" == 'unknown' ]]; then
    warn 'Could not verify APK signature because apksigner is unavailable.'
    ask_yes_no 'Try installing it anyway?' n || return 0
  fi

  select_device
  android_user="$("${ADB[@]}" shell am get-current-user 2>/dev/null | tr -d '\r' || true)"
  android_user="${android_user:-0}"
  package="$(apk_package_id "$apk" || true)"
  [[ -n "$package" ]] || package="$PACKAGE_ID"

  section 'Install APK'
  printf '  APK:       %s\n  Device:    %s\n  User:      %s\n  Signature: %s\n' \
    "$apk" "$DEVICE_SERIAL" "$android_user" "$(apk_signature_state "$apk")"
  [[ -z "$package" ]] || printf '  Package:   %s\n' "$package"
  printf '\n'

  ask_yes_no 'Install this APK?' y || return 0

  info 'Installing APK...'

  set +e
  output="$(adb_install_file "$apk" "$android_user" 2>&1)"
  result=$?
  set -e

  if (( result == 0 )); then
    printf '%s\n' "$output"
    ok 'APK installed successfully.'

    if [[ -n "$package" ]] && ask_yes_no 'Launch the app now?' y; then
      launch_package "$package" "$android_user"
    fi

    return 0
  fi

  printf '%s\n' "$output"

  if grep -q 'INSTALL_FAILED_UPDATE_INCOMPATIBLE' <<<"$output"; then
    warn 'The installed app is signed with a different key.'
    warn 'This commonly happens when a DEBUG build is installed and you are now installing a RELEASE build.'
    warn 'To change signing keys, Android requires a full uninstall of the old package.'
    warn 'A full uninstall deletes this app'\''s local data on the selected device.'

    if ! ask_yes_no 'Fully uninstall the old app and install this APK?' n; then
      return 1
    fi

    full_uninstall_package "$package" || return 1

    info 'Installing APK as a fresh install...'

    if ! adb_install_file "$apk" "$android_user"; then
      err 'Fresh APK installation failed.'
      return 1
    fi

    ok 'APK installed successfully after removing the conflicting package.'

    if [[ -n "$package" ]] && ask_yes_no 'Launch the app now?' y; then
      launch_package "$package" "$android_user"
    fi

    return 0
  fi

  if grep -q 'INSTALL_FAILED_VERSION_DOWNGRADE' <<<"$output"; then
    warn 'The installed app has a newer version code.'
    warn 'The script already uses -d, but this device rejected the downgrade.'
  elif grep -q 'INSTALL_FAILED_INSUFFICIENT_STORAGE' <<<"$output"; then
    warn 'The Android device does not have enough free storage.'
  elif grep -q 'INSTALL_FAILED_USER_RESTRICTED' <<<"$output"; then
    warn 'Android blocked installation. Check the phone screen and USB-install/security settings.'
  elif grep -q 'INSTALL_FAILED_OLDER_SDK' <<<"$output"; then
    warn 'This APK requires a newer Android version than the connected device provides.'
  fi

  die 'APK installation failed.'
}

# ---------- APK manager ----------
show_apk_manager() {
  header
  select_apk || { pause; return; }
  local apk="$SELECTED_APK" state package
  state="$(apk_signature_state "$apk")"
  package="$(apk_package_id "$apk" || true)"; [[ -n "$package" ]] || package="${PACKAGE_ID:-unknown}"
  section 'Selected APK'
  printf '  Path:      %s\n  Size:      %s\n  Modified:  %s\n  Signature: %s\n  Package:   %s\n' \
    "$apk" "$(human_size "$apk")" "$(mtime_label "$apk")" "$state" "$package"

  if [[ "$state" == 'signed' ]]; then
    choose 'APK action' 'Install APK' 'Back'
    [[ "$REPLY" == '1' ]] && install_apk "$apk"
  else
    choose 'APK action' 'Sign APK' 'Sign APK and install it' 'Try to install APK' 'Back'
    case "$REPLY" in
      1) sign_apk "$apk" ;;
      2) sign_apk "$apk" && install_apk "$SIGNED_APK" ;;
      3) install_apk "$apk" ;;
      4) : ;;
    esac
  fi
  pause
}

# ---------- Key manager ----------
key_manager() {
  header; section 'Release key manager'
  if [[ -n "${KEYSTORE_PATH:-}" && -f "$KEYSTORE_PATH" ]]; then
    printf '  Configured keystore: %s\n  Alias:               %s\n' "$KEYSTORE_PATH" "${KEY_ALIAS:-unset}"
  else
    warn 'No release keystore is configured.'
  fi
  choose 'Key action' 'Generate a new release keystore' 'Select an existing keystore' 'Forget configured keystore' 'Back'
  case "$REPLY" in
    1) generate_keystore ;;
    2) select_existing_keystore || true ;;
    3) KEYSTORE_PATH=''; KEY_ALIAS=''; save_config; ok 'Keystore configuration cleared.' ;;
    4) : ;;
  esac
  pause
}

# ---------- Workflows ----------
build_debug_flow() {
  header; build_apk debug
  printf '\n  Signature: %s\n' "$(apk_signature_state "$LAST_APK")"
  ask_yes_no 'Install the debug APK on a device?' y && install_apk "$LAST_APK"
  pause
}

build_release_flow() {
  header; build_apk release
  local apk="$LAST_APK" state="$(apk_signature_state "$LAST_APK")"
  printf '\n  Signature: %s\n' "$state"
  if [[ "$state" != 'signed' ]]; then
    warn 'Release APK is unsigned.'
    if ask_yes_no 'Sign the release APK now?' y; then sign_apk "$apk" && apk="$SIGNED_APK"; fi
  else
    ok 'Release APK is already signed.'
  fi
  ask_yes_no 'Install the resulting APK on a device?' y && install_apk "$apk"
  pause
}

release_sign_install_flow() {
  header; build_apk release
  local apk="$LAST_APK"
  [[ "$(apk_signature_state "$apk")" == 'signed' ]] || { sign_apk "$apk" || { pause; return; }; apk="$SIGNED_APK"; }
  install_apk "$apk"
  pause
}

sign_existing_flow() {
  header; select_apk || { pause; return; }
  sign_apk "$SELECTED_APK"
  [[ -n "${SIGNED_APK:-}" ]] && ask_yes_no 'Install the signed APK now?' n && install_apk "$SIGNED_APK"
  pause
}

install_existing_flow() {
  header; select_apk || { pause; return; }
  install_apk "$SELECTED_APK"
  pause
}

initialize_android_flow() {
  header
  if [[ -d src-tauri/gen/android ]]; then ok 'Android target is already initialized.'
  else install_dependencies; info 'Initializing Android target...'; run_tauri android init; ok 'Android target initialized.'
  fi
  pause
}

project_status() {
  collect_apks
  local android_status key_status
  [[ -d src-tauri/gen/android ]] && android_status='ready' || android_status='not initialized'
  [[ -n "${KEYSTORE_PATH:-}" && -f "$KEYSTORE_PATH" ]] && key_status='configured' || key_status='not configured'
  printf '\n%bProject%b\n' "$BOLD" "$RESET"
  printf '  App:       %s\n  Package:   %s\n  Root:      %s\n  Android:   %s\n  APKs:      %s found\n  Signing:   %s\n  Devices:   %s connected/authorized\n' \
    "$APP_NAME" "${PACKAGE_ID:-unknown}" "$ROOT" "$android_status" "${#APKS[@]}" "$key_status" "$(connected_device_count)"
}

# ---------- Menu ----------
main_menu() {
  while true; do
    header; project_status; section 'Main menu'
    printf '  %b 1%b) Build DEBUG APK\n' "$CYAN$BOLD" "$RESET"
    printf '  %b 2%b) Build RELEASE APK\n' "$CYAN$BOLD" "$RESET"
    printf '  %b 3%b) Build DEBUG APK -> optionally install\n' "$CYAN$BOLD" "$RESET"
    printf '  %b 4%b) Build RELEASE -> sign if needed -> optionally install\n' "$CYAN$BOLD" "$RESET"
    printf '  %b 5%b) Build RELEASE -> sign -> install guided workflow\n' "$CYAN$BOLD" "$RESET"
    printf '  %b 6%b) APK manager\n' "$CYAN$BOLD" "$RESET"
    printf '  %b 7%b) Sign an existing APK\n' "$CYAN$BOLD" "$RESET"
    printf '  %b 8%b) Install an existing APK\n' "$CYAN$BOLD" "$RESET"
    printf '  %b 9%b) Release key manager\n' "$CYAN$BOLD" "$RESET"
    printf '  %b10%b) Connected devices\n' "$CYAN$BOLD" "$RESET"
    printf '  %b11%b) Environment doctor\n' "$CYAN$BOLD" "$RESET"
    printf '  %b12%b) Initialize Tauri Android target\n' "$CYAN$BOLD" "$RESET"
    printf '  %b 0%b) Exit\n' "$DIM" "$RESET"
    printf '\n%bChoose%b: ' "$BOLD" "$RESET"
    local choice apk
    read -r choice || choice=0
    case "$choice" in
      1)
        header; build_apk debug
        ask_yes_no 'Install this debug APK now?' n && install_apk "$LAST_APK"
        pause
        ;;
      2)
        header; build_apk release; apk="$LAST_APK"
        if [[ "$(apk_signature_state "$apk")" != 'signed' ]]; then
          warn 'Release APK is unsigned.'
          if ask_yes_no 'Create/select a signing key and sign it now?' y; then sign_apk "$apk" && apk="$SIGNED_APK"; fi
        else ok 'Release APK is already signed.'; fi
        ask_yes_no 'Install the resulting APK now?' n && install_apk "$apk"
        pause
        ;;
      3) build_debug_flow ;;
      4) build_release_flow ;;
      5) release_sign_install_flow ;;
      6) show_apk_manager ;;
      7) sign_existing_flow ;;
      8) install_existing_flow ;;
      9) key_manager ;;
      10) show_devices ;;
      11) header; doctor || true; pause ;;
      12) initialize_android_flow ;;
      0) printf '\n%bBye.%b\n' "$DIM" "$RESET"; exit 0 ;;
      *) warn 'Unknown menu option.'; sleep 1 ;;
    esac
  done
}

usage() {
  cat <<USAGE
Tauri Android Toolkit v$VERSION

Run this script from the root of a Tauri v2 application.

Interactive:
  ./install-android.sh

Commands:
  ./install-android.sh menu
  ./install-android.sh doctor
  ./install-android.sh devices
  ./install-android.sh init
  ./install-android.sh debug
  ./install-android.sh debug-install
  ./install-android.sh release
  ./install-android.sh release-install
  ./install-android.sh apks
  ./install-android.sh key
  ./install-android.sh sign [APK_PATH]
  ./install-android.sh install [APK_PATH]

Environment:
  TAURI_MOBILE_KEYSTORE=/absolute/path/release.jks
  TAURI_MOBILE_KEY_ALIAS=upload
  TAURI_MOBILE_KEYSTORE_PASS=your-password
  TAURI_MOBILE_KEY_PASS=your-password
  NO_COLOR=1

Local generated state:
  .tauri-mobile/
    config.env
    keys/
    output/
USAGE
}

main() {
  ensure_project_root
  ensure_state_dirs
  detect_package_manager
  detect_project_metadata
  load_config
  resolve_android_tools

  local cmd="${1:-menu}"
  case "$cmd" in
    menu) main_menu ;;
    doctor) doctor ;;
    devices) show_devices ;;
    init) initialize_android_flow ;;
    debug) header; build_apk debug; printf '\n%s\n' "$LAST_APK" ;;
    debug-install) build_debug_flow ;;
    release) build_release_flow ;;
    release-install) release_sign_install_flow ;;
    apks) show_apk_manager ;;
    key) key_manager ;;
    sign)
      header
      if [[ -n "${2:-}" ]]; then sign_apk "$(abs_path "$2")"; else select_apk && sign_apk "$SELECTED_APK"; fi
      ;;
    install)
      header
      if [[ -n "${2:-}" ]]; then install_apk "$(abs_path "$2")"; else select_apk && install_apk "$SELECTED_APK"; fi
      ;;
    help|-h|--help) usage ;;
    *) err "Unknown command: $cmd"; usage; exit 2 ;;
  esac
}

main "$@"