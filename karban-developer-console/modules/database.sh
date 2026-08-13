#!/usr/bin/env bash
# shellcheck shell=bash

k_db_url() { local v; v="$(k_env_value "$KARBAN_ROOT/backend/.env" DATABASE_URL)"; printf '%s' "${DATABASE_URL:-$v}"; }
k_prisma() { (cd "$KARBAN_ROOT" && "$KARBAN_CONSOLE_DIR/tools/prisma-manager.sh" "$@"); }

k_db_info() {
  k_header 'KARBAN / DATABASE / INFORMATION' 'PostgreSQL and Prisma overview'
  local url; url="$(k_db_url)"; [[ -n "$url" ]] || { k_warn 'DATABASE_URL is not configured.'; return 1; }
  printf '  DATABASE_URL  %s\n' "$(k_mask_url "$url")"
  if k_cmd_exists psql; then
    printf '\n'; PGPASSWORD="$(node "$KARBAN_CONSOLE_DIR/scripts/parse-db-url.mjs" "$url" --shell | sed -n 's/^PASSWORD="\(.*\)"$/\1/p')" \
      psql "$url" -X -v ON_ERROR_STOP=1 -c "select current_database() as database, current_user as user, version();" || true
    psql "$url" -X -Atc "select pg_size_pretty(pg_database_size(current_database()));" 2>/dev/null | awk '{print "Database size: "$0}' || true
    psql "$url" -X -Atc "select count(*) from information_schema.tables where table_schema not in ('pg_catalog','information_schema');" 2>/dev/null | awk '{print "Application tables: "$0}' || true
  else k_warn 'psql is not installed; Prisma connection test is still available.'; fi
}

k_db_psql() { local url; url="$(k_db_url)"; [[ -n "$url" ]] || { k_warn 'DATABASE_URL missing.'; return 1; }; k_cmd_exists psql || { k_err 'psql not installed.'; return 1; }; psql "$url"; }

k_db_backup() {
  local url name out; url="$(k_db_url)"; [[ -n "$url" ]] || return 1
  k_cmd_exists pg_dump || { k_err 'pg_dump is required.'; return 1; }
  name="database-$(k_now).dump"; out="$KARBAN_BACKUP_DIR/$name"
  k_info "Creating compressed PostgreSQL backup..."
  pg_dump --format=custom --no-owner --no-acl --file "$out" "$url"
  sha256sum "$out" > "$out.sha256" 2>/dev/null || shasum -a 256 "$out" > "$out.sha256"
  k_ok "Backup created: $out"
}

k_db_list_backups() { k_header 'KARBAN / DATABASE / BACKUPS'; find "$KARBAN_BACKUP_DIR" -maxdepth 1 -type f \( -name '*.dump' -o -name '*.sql' \) -printf '%TY-%Tm-%Td %TH:%TM  %10s  %f\n' 2>/dev/null | sort -r || true; }

k_db_restore() {
  k_db_list_backups
  local file url dbname; file="$(k_prompt 'Backup path')"; [[ -f "$file" ]] || { k_err 'Backup file not found.'; return 1; }
  url="$(k_db_url)"; [[ -n "$url" ]] || return 1
  dbname="$(node "$KARBAN_CONSOLE_DIR/scripts/parse-db-url.mjs" "$url" --shell | sed -n 's/^DATABASE="\(.*\)"$/\1/p')"
  k_danger_confirm "Restore will overwrite objects/data in database '$dbname'." "$dbname" || { k_warn 'Cancelled.'; return 0; }
  case "$file" in *.dump) k_cmd_exists pg_restore || { k_err 'pg_restore required.'; return 1; }; pg_restore --clean --if-exists --no-owner --no-acl --dbname "$url" "$file";; *.sql) psql "$url" -v ON_ERROR_STOP=1 -f "$file";; esac
  k_ok 'Restore completed.'
}

k_db_sql_file() { local file url; file="$(k_prompt 'SQL file path')"; [[ -f "$file" ]] || { k_err 'File not found.'; return 1; }; url="$(k_db_url)"; psql "$url" -v ON_ERROR_STOP=1 -f "$file"; }

k_db_migrate_diff() {
  local url; url="$(k_db_url)"; [[ -n "$url" ]] || return 1
  (cd "$KARBAN_ROOT/backend" && npx --no-install prisma migrate diff --from-url "$url" --to-schema-datamodel prisma/schema.prisma --script)
}

k_db_tables() {
  local url; url="$(k_db_url)"; [[ -n "$url" ]] || return 1; k_cmd_exists psql || return 1
  psql "$url" -X -P pager=off -c "SELECT schemaname, relname AS table, pg_size_pretty(pg_total_relation_size(relid)) AS total_size FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 30;"
}

k_db_connections() {
  local url; url="$(k_db_url)"; [[ -n "$url" ]] || return 1; k_cmd_exists psql || return 1
  psql "$url" -X -P pager=off -c "SELECT state, count(*) FROM pg_stat_activity WHERE datname=current_database() GROUP BY state ORDER BY state;"
}

k_database_menu() {
  while true; do
    k_header 'KARBAN / DATABASE & PRISMA' "Environment: ${KARBAN_ENVIRONMENT^^}"
    k_section 'Database'
    printf '  1  Database information\n  2  Configure DATABASE_URL\n  3  Test connection\n  4  PostgreSQL shell\n  5  Largest tables\n  6  Connection overview\n'
    k_section 'Prisma'
    printf '  7  Validate schema\n  8  Format schema\n  9  Generate client\n 10  Prisma Studio\n 11  DB pull / introspection\n 12  DB push (no migration history)\n'
    k_section 'Migrations'
    printf ' 13  Migrate dev\n 14  Create-only migration\n 15  Migration status\n 16  Deploy migrations\n 17  Resolve migration\n 18  Migration diff / drift preview\n 19  Full Prisma manager\n'
    k_section 'Backup & Recovery'
    printf ' 20  Create backup\n 21  List backups\n 22  Restore backup\n 23  Execute SQL file\n 24  Seed database\n 25  RESET development database\n'
    printf '\n  B  Back\n  Q  Quit\n\nChoose: '
    read -r choice || choice=b
    case "${choice,,}" in
      1) k_db_info; k_pause;; 2) k_prisma set-url; k_pause;; 3) k_prisma test-connection; k_pause;; 4) k_db_psql;; 5) k_db_tables; k_pause;; 6) k_db_connections; k_pause;;
      7) k_prisma validate; k_pause;; 8) k_prisma format; k_pause;; 9) k_prisma generate; k_pause;; 10) k_prisma studio;; 11) k_prisma db-pull; k_pause;; 12) k_prisma db-push; k_pause;; 13) k_prisma migrate-dev; k_pause;; 14) k_prisma migrate-create; k_pause;; 17) k_prisma resolve; k_pause;;
      15) k_prisma status; k_pause;; 16) k_prisma deploy; k_pause;; 18) k_db_migrate_diff; k_pause;; 19) k_prisma menu;;
      20) k_db_backup; k_pause;; 21) k_db_list_backups; k_pause;; 22) k_db_restore; k_pause;; 23) k_db_sql_file; k_pause;; 24) k_prisma seed; k_pause;; 25) k_prisma reset; k_pause;;
      b) return 0;; q) exit 0;; *) k_warn 'Unknown option.'; sleep 1;;
    esac
  done
}
