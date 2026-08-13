#!/usr/bin/env bash
# shellcheck shell=bash

k_cmd_exists() { command -v "$1" >/dev/null 2>&1; }
k_now() { date '+%Y-%m-%d_%H-%M-%S'; }

k_find_project_root() {
  if [[ -n "${KARBAN_ROOT:-}" && -d "$KARBAN_ROOT" ]]; then (cd "$KARBAN_ROOT" && pwd -P); return; fi
  local d="${1:-$PWD}" i
  for i in {1..8}; do
    if [[ -d "$d/backend" && -d "$d/mobile" && -d "$d/admin" && -d "$d/website" ]]; then (cd "$d" && pwd -P); return; fi
    [[ "$d" == / ]] && break
    d="$(dirname "$d")"
  done
  return 1
}

k_detect_pm() {
  local dir="$1"
  if [[ -f "$dir/pnpm-lock.yaml" ]]; then printf pnpm
  elif [[ -f "$dir/yarn.lock" ]]; then printf yarn
  elif [[ -f "$dir/bun.lockb" || -f "$dir/bun.lock" ]]; then printf bun
  else printf npm; fi
}

k_pm_run() {
  local dir="$1" script="$2"; shift 2
  local pm; pm="$(k_detect_pm "$dir")"
  (cd "$dir" && case "$pm" in npm) npm run "$script" -- "$@";; pnpm) pnpm run "$script" "$@";; yarn) yarn "$script" "$@";; bun) bun run "$script" "$@";; esac)
}

k_pm_install() {
  local dir="$1" pm; pm="$(k_detect_pm "$dir")"
  (cd "$dir" && case "$pm" in npm) [[ -f package-lock.json ]] && npm ci || npm install;; pnpm) pnpm install;; yarn) yarn install;; bun) bun install;; esac)
}

k_has_script() {
  local dir="$1" name="$2"
  [[ -f "$dir/package.json" && -n "$(node "$KARBAN_CONSOLE_DIR/scripts/json-read.mjs" "$dir/package.json" "scripts.$name" 2>/dev/null || true)" ]]
}

k_run_script_if_present() {
  local dir="$1" script="$2"
  if k_has_script "$dir" "$script"; then k_pm_run "$dir" "$script"; else k_warn "No '$script' script in $dir/package.json"; return 2; fi
}

k_git_root() { git -C "$KARBAN_ROOT" rev-parse --show-toplevel 2>/dev/null || true; }
k_git_branch() { git -C "$KARBAN_ROOT" branch --show-current 2>/dev/null || printf unknown; }
k_git_commit() { git -C "$KARBAN_ROOT" rev-parse --short HEAD 2>/dev/null || printf unknown; }
k_git_dirty() { [[ -n "$(git -C "$KARBAN_ROOT" status --porcelain 2>/dev/null)" ]]; }

k_project_version() {
  node "$KARBAN_CONSOLE_DIR/scripts/json-read.mjs" "$KARBAN_ROOT/mobile/src-tauri/tauri.conf.json" version 2>/dev/null || \
  node "$KARBAN_CONSOLE_DIR/scripts/json-read.mjs" "$KARBAN_ROOT/mobile/package.json" version 2>/dev/null || printf unknown
}
