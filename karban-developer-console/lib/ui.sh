#!/usr/bin/env bash
# shellcheck shell=bash

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  K_RESET=$'\033[0m'; K_BOLD=$'\033[1m'; K_DIM=$'\033[2m'
  K_RED=$'\033[31m'; K_GREEN=$'\033[32m'; K_YELLOW=$'\033[33m'; K_BLUE=$'\033[34m'; K_CYAN=$'\033[36m'; K_MAGENTA=$'\033[35m'
else
  K_RESET=""; K_BOLD=""; K_DIM=""; K_RED=""; K_GREEN=""; K_YELLOW=""; K_BLUE=""; K_CYAN=""; K_MAGENTA=""
fi

k_clear() { [[ -t 1 ]] && printf '\033[2J\033[H' || true; }
k_line() { local ch="${1:--}" n="${2:-78}"; printf '%*s\n' "$n" '' | tr ' ' "$ch"; }
k_info() { printf '%b[INFO]%b %s\n' "$K_BLUE$K_BOLD" "$K_RESET" "$*"; }
k_ok() { printf '%b[ OK ]%b %s\n' "$K_GREEN$K_BOLD" "$K_RESET" "$*"; }
k_warn() { printf '%b[WARN]%b %s\n' "$K_YELLOW$K_BOLD" "$K_RESET" "$*"; }
k_err() { printf '%b[FAIL]%b %s\n' "$K_RED$K_BOLD" "$K_RESET" "$*" >&2; }
k_die() { k_err "$*"; exit 1; }

k_header() {
  local title="${1:-KARBAN DEVELOPER CONSOLE}" subtitle="${2:-Engineering control center}"
  k_clear
  printf '%b' "$K_CYAN$K_BOLD"
  k_line '=' 78
  printf '  %s\n' "$title"
  printf '%b  %s%b\n' "$K_DIM" "$subtitle" "$K_RESET"
  printf '%b' "$K_CYAN$K_BOLD"; k_line '=' 78; printf '%b' "$K_RESET"
}

k_section() {
  printf '\n%b%s%b\n' "$K_BOLD" "$1" "$K_RESET"
  printf '%b' "$K_DIM"; k_line '-' 78; printf '%b' "$K_RESET"
}

k_pause() {
  [[ -t 0 ]] || return 0
  printf '\n%bPress Enter to continue...%b' "$K_DIM" "$K_RESET"
  read -r _ || true
}

k_yes_no() {
  local prompt="$1" default="${2:-y}" answer suffix
  [[ "$default" == y ]] && suffix='Y/n' || suffix='y/N'
  while true; do
    printf '%b%s%b [%s]: ' "$K_BOLD" "$prompt" "$K_RESET" "$suffix"
    read -r answer || answer=""
    answer="${answer:-$default}"
    case "${answer,,}" in y|yes) return 0;; n|no) return 1;; *) k_warn 'Please answer y or n.';; esac
  done
}

k_prompt() {
  local prompt="$1" default="${2:-}" value
  if [[ -n "$default" ]]; then printf '%b%s%b [%s]: ' "$K_BOLD" "$prompt" "$K_RESET" "$default" >&2
  else printf '%b%s%b: ' "$K_BOLD" "$prompt" "$K_RESET" >&2; fi
  read -r value || value=""
  printf '%s' "${value:-$default}"
}

k_secret() {
  local prompt="$1" value
  printf '%b%s%b: ' "$K_BOLD" "$prompt" "$K_RESET" >&2
  IFS= read -r -s value || value=""
  printf '\n' >&2
  printf '%s' "$value"
}

k_danger_confirm() {
  local label="$1" expected="$2" value
  printf '\n%b' "$K_RED$K_BOLD"; k_line '!' 78; printf '%b' "$K_RESET"
  printf '%bDANGER:%b %s\n' "$K_RED$K_BOLD" "$K_RESET" "$label"
  printf 'Type %b%s%b to continue: ' "$K_BOLD" "$expected" "$K_RESET"
  read -r value || value=""
  [[ "$value" == "$expected" ]]
}

k_choose() {
  local title="$1"; shift
  local options=("$@") i choice
  printf '\n%b%s%b\n' "$K_BOLD" "$title" "$K_RESET"
  for i in "${!options[@]}"; do printf '  %b%2d%b  %s\n' "$K_CYAN$K_BOLD" "$((i+1))" "$K_RESET" "${options[$i]}"; done
  while true; do
    printf '%bSelect%b [1-%d]: ' "$K_BOLD" "$K_RESET" "${#options[@]}"
    read -r choice || choice=""
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice>=1 && choice<=${#options[@]} )); then K_REPLY="$choice"; return 0; fi
    k_warn 'Invalid selection.'
  done
}

k_status_row() {
  local label="$1" status="$2" detail="${3:-}" color="$K_DIM"
  case "$status" in READY|ONLINE|PASS|CONNECTED|RUNNING|CURRENT) color="$K_GREEN$K_BOLD";; WARN|PENDING|PARTIAL) color="$K_YELLOW$K_BOLD";; FAIL|OFFLINE|MISSING|STOPPED|ERROR) color="$K_RED$K_BOLD";; esac
  printf '  %-22s %b%-12s%b %s\n' "$label" "$color" "$status" "$K_RESET" "$detail"
}

k_run_steps_begin() { K_STEPS_TOTAL="$1"; K_STEPS_DONE=0; }
k_run_step() {
  local label="$1"; shift
  K_STEPS_DONE=$((K_STEPS_DONE+1))
  printf '\n%b[%d/%d]%b %s\n' "$K_CYAN$K_BOLD" "$K_STEPS_DONE" "$K_STEPS_TOTAL" "$K_RESET" "$label"
  if "$@"; then k_ok "$label"; return 0; else k_err "$label"; return 1; fi
}
