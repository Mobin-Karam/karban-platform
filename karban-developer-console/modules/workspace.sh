#!/usr/bin/env bash
# shellcheck shell=bash

k_workspace_install_all() {
  k_header 'KARBAN / INSTALL ALL DEPENDENCIES'
  local d
  for d in backend mobile admin website; do k_section "$d"; k_pm_install "$KARBAN_ROOT/$d" || return 1; done
}

k_workspace_tmux_start() {
  command -v tmux >/dev/null 2>&1 || { k_warn 'tmux is not installed. Use the individual app menus or install tmux.'; return 1; }
  local session='karban-dev'; tmux has-session -t "$session" 2>/dev/null && { k_warn 'karban-dev session already exists.'; return 0; }
  k_dc up -d postgres || return 1
  tmux new-session -d -s "$session" -n backend "cd '$KARBAN_ROOT/backend' && $(k_detect_pm "$KARBAN_ROOT/backend") run start:dev; exec bash"
  tmux new-window -t "$session" -n admin "cd '$KARBAN_ROOT/admin' && $(k_detect_pm "$KARBAN_ROOT/admin") run dev; exec bash"
  tmux new-window -t "$session" -n website "cd '$KARBAN_ROOT/website' && $(k_detect_pm "$KARBAN_ROOT/website") run dev; exec bash"
  tmux new-window -t "$session" -n mobile "cd '$KARBAN_ROOT/mobile' && $(k_detect_pm "$KARBAN_ROOT/mobile") run dev; exec bash"
  k_ok "Started tmux session '$session'. Attach with: tmux attach -t $session"
}

k_workspace_menu() {
  while true; do
    k_header 'KARBAN / DEVELOPMENT WORKSPACE' 'Start, stop and inspect the complete local project'
    printf '  1  Install dependencies for all four apps\n  2  Start PostgreSQL Docker service\n  3  Start full web/API development workspace in tmux\n  4  Attach to karban-dev tmux session\n  5  Stop karban-dev tmux session\n  6  Start backend only\n  7  Start admin only\n  8  Start website only\n  9  Start mobile frontend only\n 10  Show localhost/LAN URLs\n 11  Show listening ports\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) k_workspace_install_all; k_pause;; 2) k_dc up -d postgres; k_pause;; 3) k_workspace_tmux_start; k_pause;; 4) tmux attach -t karban-dev;; 5) tmux kill-session -t karban-dev 2>/dev/null || true; k_pause;;
      6) k_app_run_common "$KARBAN_ROOT/backend" BACKEND dev;; 7) k_app_run_common "$KARBAN_ROOT/admin" ADMIN dev;; 8) k_app_run_common "$KARBAN_ROOT/website" WEBSITE dev;; 9) k_app_run_common "$KARBAN_ROOT/mobile" MOBILE dev;;
      10) k_environment_summary; printf '\nLAN addresses: '; hostname -I 2>/dev/null || true; k_pause;; 11) (ss -lntp 2>/dev/null || lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null || true); k_pause;; b) return;; esac
  done
}
