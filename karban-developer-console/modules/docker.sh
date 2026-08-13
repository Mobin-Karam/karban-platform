#!/usr/bin/env bash
# shellcheck shell=bash
k_docker_compose() { if docker compose version >/dev/null 2>&1; then printf 'docker compose'; elif command -v docker-compose >/dev/null; then printf docker-compose; else return 1; fi; }
k_dc() { local dc; dc="$(k_docker_compose)" || { k_err 'Docker Compose is unavailable.'; return 1; }; (cd "$KARBAN_ROOT" && $dc "$@"); }

k_docker_menu() {
  while true; do
    k_header 'KARBAN / DOCKER' 'Local PostgreSQL and backend environment'
    if command -v docker >/dev/null; then docker --version; else k_warn 'Docker missing.'; fi
    printf '\n  1  Start full Compose stack\n  2  Start PostgreSQL only\n  3  Start backend only\n  4  Stop stack\n  5  Restart stack\n  6  Service status\n  7  Follow all logs\n  8  PostgreSQL logs\n  9  Backend logs\n 10  Compose config validation\n 11  Container health/details\n 12  Remove containers (keep volumes)\n 13  Remove development volumes (DESTRUCTIVE)\n  B  Back\n\nChoose: '
    read -r c || c=b
    case "${c,,}" in
      1) k_dc up -d; k_pause;; 2) k_dc up -d postgres; k_pause;; 3) k_dc up -d backend; k_pause;; 4) k_dc down; k_pause;; 5) k_dc restart; k_pause;; 6) k_dc ps; k_pause;;
      7) k_dc logs -f;; 8) k_dc logs -f postgres;; 9) k_dc logs -f backend;; 10) k_dc config; k_pause;; 11) docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'; k_pause;;
      12) k_danger_confirm 'Remove Karban Compose containers but preserve named volumes.' REMOVE && k_dc down; k_pause;;
      13) k_danger_confirm 'Delete local Docker volumes and PostgreSQL development data.' DELETE-VOLUMES && k_dc down -v; k_pause;; b) return;; esac
  done
}
