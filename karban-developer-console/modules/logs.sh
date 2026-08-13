#!/usr/bin/env bash
# shellcheck shell=bash

k_logs_menu() {
  while true; do
    k_header 'KARBAN / LOGS'
    printf '  Console log directory: %s\n' "$KARBAN_LOG_DIR"
    printf '\n  1  List console logs\n  2  View latest console log\n  3  Follow backend Docker logs\n  4  Follow PostgreSQL Docker logs\n  5  Android live logcat\n  6  Clear Android logcat\n  7  Delete old console logs\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) ls -lht "$KARBAN_LOG_DIR" | head -80; k_pause;;
      2) local f; f="$(find "$KARBAN_LOG_DIR" -type f -name '*.log' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2- || true)"; [[ -n "$f" ]] && ${PAGER:-less} "$f" || k_warn 'No console logs.';;
      3) k_dc logs -f backend;; 4) k_dc logs -f postgres;; 5) k_android_logcat;; 6) k_android_clear_logcat; k_pause;;
      7) local days; days="$(k_prompt 'Delete logs older than N days' 30)"; find "$KARBAN_LOG_DIR" -type f -mtime "+$days" -delete; k_ok 'Old logs removed.'; k_pause;; b) return;; esac
  done
}
