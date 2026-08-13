#!/usr/bin/env bash
set -Eeuo pipefail

# Karban Prisma Manager
# Interactive Prisma/PostgreSQL helper for the Karban backend.
# Safe defaults: destructive actions require explicit confirmation.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ---------- terminal helpers ----------
if [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_BOLD='\033[1m'
  C_BLUE='\033[34m'
  C_GREEN='\033[32m'
  C_YELLOW='\033[33m'
  C_RED='\033[31m'
  C_DIM='\033[2m'
else
  C_RESET=''
  C_BOLD=''
  C_BLUE=''
  C_GREEN=''
  C_YELLOW=''
  C_RED=''
  C_DIM=''
fi

info()  { printf "%b[INFO]%b %s\n" "$C_BLUE" "$C_RESET" "$*"; }
ok()    { printf "%b[ OK ]%b %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf "%b[WARN]%b %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
error() { printf "%b[ERR ]%b %s\n" "$C_RED" "$C_RESET" "$*" >&2; }
hr()    { printf '%s\n' '--------------------------------------------------------------------------'; }
pause() { printf '\nPress Enter to continue...'; IFS= read -r _; }

on_error() {
  local exit_code=$?
  local line_no=${1:-unknown}
  error "Command failed near line ${line_no} (exit ${exit_code})."
  return "$exit_code"
}
trap 'on_error $LINENO' ERR

# ---------- project discovery ----------
find_backend_dir() {
  local candidates=(
    "$PWD/backend"
    "$PWD"
    "$SCRIPT_DIR/backend"
    "$SCRIPT_DIR/../backend"
    "$SCRIPT_DIR/karban-platform/backend"
  )

  local dir
  for dir in "${candidates[@]}"; do
    if [[ -f "$dir/package.json" && -f "$dir/prisma/schema.prisma" ]]; then
      (cd "$dir" && pwd)
      return 0
    fi
  done

  return 1
}

BACKEND_DIR="${KARBAN_BACKEND_DIR:-}"
if [[ -z "$BACKEND_DIR" ]]; then
  if ! BACKEND_DIR="$(find_backend_dir)"; then
    error "Could not find backend/package.json + backend/prisma/schema.prisma."
    printf '%s\n' "Run this script from the Karban project root/backend, or set:"
    printf '%s\n' "  KARBAN_BACKEND_DIR=/absolute/path/to/karban-platform/backend"
    exit 1
  fi
fi

BACKEND_DIR="$(cd "$BACKEND_DIR" && pwd)"
ROOT_DIR="$(cd "$BACKEND_DIR/.." && pwd)"
SCHEMA_FILE="$BACKEND_DIR/prisma/schema.prisma"
ENV_FILE="$BACKEND_DIR/.env"
ENV_EXAMPLE="$BACKEND_DIR/.env.example"
MIGRATIONS_DIR="$BACKEND_DIR/prisma/migrations"
PRISMA_BIN="$BACKEND_DIR/node_modules/.bin/prisma"

cd "$BACKEND_DIR"

# ---------- env handling ----------
ensure_env_file() {
  if [[ -f "$ENV_FILE" ]]; then
    return 0
  fi

  if [[ -f "$ENV_EXAMPLE" ]]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    chmod 600 "$ENV_FILE" 2>/dev/null || true
    ok "Created backend/.env from .env.example"
  else
    touch "$ENV_FILE"
    chmod 600 "$ENV_FILE" 2>/dev/null || true
    warn "Created an empty backend/.env because .env.example was not found."
  fi
}

read_env_value() {
  local key="$1"
  local line=""
  [[ -f "$ENV_FILE" ]] || return 0

  line="$(grep -E "^${key}=" "$ENV_FILE" | tail -n 1 || true)"
  line="${line#*=}"

  # Strip one matching pair of quotes, if present.
  if [[ "$line" == \"*\" && "$line" == *\" ]]; then
    line="${line:1:${#line}-2}"
  elif [[ "$line" == \'*\' && "$line" == *\' ]]; then
    line="${line:1:${#line}-2}"
  fi

  printf '%s' "$line"
}

write_env_value() {
  local key="$1"
  local value="$2"
  local tmp
  local found=0

  ensure_env_file
  tmp="$(mktemp)"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "${key}="* ]]; then
      printf '%s=%s\n' "$key" "$value" >> "$tmp"
      found=1
    else
      printf '%s\n' "$line" >> "$tmp"
    fi
  done < "$ENV_FILE"

  if [[ "$found" -eq 0 ]]; then
    printf '%s=%s\n' "$key" "$value" >> "$tmp"
  fi

  mv "$tmp" "$ENV_FILE"
  chmod 600 "$ENV_FILE" 2>/dev/null || true
}

mask_database_url() {
  local url="$1"
  if [[ "$url" =~ ^([^:]+://[^:]+:)([^@]+)(@.*)$ ]]; then
    printf '%s****%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[3]}"
  else
    printf '%s' "$url"
  fi
}

urlencode() {
  local raw="$1"
  local out=""
  local i ch hex
  LC_ALL=C

  for ((i=0; i<${#raw}; i++)); do
    ch="${raw:i:1}"
    case "$ch" in
      [a-zA-Z0-9.~_-]) out+="$ch" ;;
      *)
        printf -v hex '%%%02X' "'$ch"
        out+="$hex"
        ;;
    esac
  done

  printf '%s' "$out"
}

set_database_url_menu() {
  ensure_env_file
  printf '\n%bSet DATABASE_URL%b\n' "$C_BOLD" "$C_RESET"
  hr
  printf '%s\n' '1) Karban local PostgreSQL (host machine -> Docker port 5432)'
  printf '%s\n' '2) Karban Docker network (backend container -> postgres service)'
  printf '%s\n' '3) Build URL from connection fields'
  printf '%s\n' '4) Paste a complete PostgreSQL URL'
  printf '%s\n' '0) Cancel'
  printf '> '
  IFS= read -r choice

  local url=""
  case "$choice" in
    1)
      url='postgresql://karban:karban_dev@localhost:5432/karban?schema=public'
      ;;
    2)
      url='postgresql://karban:karban_dev@postgres:5432/karban?schema=public'
      ;;
    3)
      local host port db user pass schema ssl_query enc_user enc_pass
      read -r -p 'Host [localhost]: ' host
      host="${host:-localhost}"
      read -r -p 'Port [5432]: ' port
      port="${port:-5432}"
      read -r -p 'Database [karban]: ' db
      db="${db:-karban}"
      read -r -p 'Username [karban]: ' user
      user="${user:-karban}"
      read -r -s -p 'Password: ' pass
      printf '\n'
      read -r -p 'Schema [public]: ' schema
      schema="${schema:-public}"
      read -r -p 'Extra query (example: sslmode=require) [none]: ' ssl_query

      if [[ -z "$pass" ]]; then
        error 'Password cannot be empty in the URL builder.'
        return 1
      fi

      enc_user="$(urlencode "$user")"
      enc_pass="$(urlencode "$pass")"
      url="postgresql://${enc_user}:${enc_pass}@${host}:${port}/${db}?schema=${schema}"
      if [[ -n "$ssl_query" ]]; then
        url+="&${ssl_query}"
      fi
      ;;
    4)
      read -r -p 'DATABASE_URL: ' url
      ;;
    0)
      return 0
      ;;
    *)
      error 'Invalid selection.'
      return 1
      ;;
  esac

  if [[ ! "$url" =~ ^postgres(ql)?:// ]]; then
    error 'DATABASE_URL must start with postgresql:// or postgres://'
    return 1
  fi

  write_env_value 'DATABASE_URL' "$url"
  export DATABASE_URL="$url"
  ok "Saved DATABASE_URL to backend/.env"
  printf 'Current: %s\n' "$(mask_database_url "$url")"
}

load_database_url() {
  ensure_env_file
  local url
  url="$(read_env_value DATABASE_URL)"
  if [[ -n "$url" ]]; then
    export DATABASE_URL="$url"
  fi
}

require_database_url() {
  load_database_url
  if [[ -z "${DATABASE_URL:-}" ]]; then
    error 'DATABASE_URL is missing.'
    set_database_url_menu
    load_database_url
  fi

  [[ -n "${DATABASE_URL:-}" ]]
}

# ---------- dependency helpers ----------
require_node_npm() {
  command -v node >/dev/null 2>&1 || { error 'Node.js is not installed.'; return 1; }
  command -v npm >/dev/null 2>&1 || { error 'npm is not installed.'; return 1; }
}

install_dependencies() {
  require_node_npm
  info "Installing backend dependencies in: $BACKEND_DIR"

  if [[ -f package-lock.json ]]; then
    npm ci
  else
    npm install
  fi

  ok 'Backend dependencies installed.'
}

require_prisma() {
  require_node_npm
  if [[ ! -x "$PRISMA_BIN" ]]; then
    error 'Local Prisma CLI is not installed yet.'
    printf '%s\n' 'Use menu option 4 (Install backend dependencies) first.'
    return 1
  fi
}

prisma() {
  require_prisma
  require_database_url
  "$PRISMA_BIN" "$@"
}

# ---------- safety helpers ----------
confirm() {
  local message="$1"
  local answer
  printf '%b%s%b [y/N]: ' "$C_YELLOW" "$message" "$C_RESET"
  IFS= read -r answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

confirm_phrase() {
  local message="$1"
  local phrase="$2"
  local answer
  warn "$message"
  printf 'Type %s to continue: ' "$phrase"
  IFS= read -r answer
  [[ "$answer" == "$phrase" ]]
}

# ---------- prisma actions ----------
show_config() {
  ensure_env_file
  load_database_url

  printf '\n%bKarban database configuration%b\n' "$C_BOLD" "$C_RESET"
  hr
  printf 'Project root : %s\n' "$ROOT_DIR"
  printf 'Backend      : %s\n' "$BACKEND_DIR"
  printf 'Schema       : %s\n' "$SCHEMA_FILE"
  printf '.env         : %s\n' "$ENV_FILE"
  printf 'DATABASE_URL : %s\n' "$(mask_database_url "${DATABASE_URL:-<missing>}")"
  printf 'Node         : %s\n' "$(node --version 2>/dev/null || printf '<missing>')"
  printf 'npm          : %s\n' "$(npm --version 2>/dev/null || printf '<missing>')"
  if [[ -x "$PRISMA_BIN" ]]; then
    printf 'Prisma       : '
    "$PRISMA_BIN" -v | sed -n '1,4p'
  else
    printf 'Prisma       : <not installed in backend/node_modules>\n'
  fi
}

test_connection() {
  require_prisma
  require_database_url
  info 'Testing PostgreSQL connection with SELECT 1...'
  printf 'SELECT 1;\n' | "$PRISMA_BIN" db execute --stdin --schema "$SCHEMA_FILE"
  ok 'Database connection succeeded.'
}

validate_schema() {
  info 'Validating Prisma schema...'
  prisma validate --schema "$SCHEMA_FILE"
  ok 'Prisma schema is valid.'
}

format_schema() {
  info 'Formatting Prisma schema...'
  prisma format --schema "$SCHEMA_FILE"
  ok 'Prisma schema formatted.'
}

generate_client() {
  info 'Generating Prisma Client...'
  prisma generate --schema "$SCHEMA_FILE"
  ok 'Prisma Client generated.'
}

migrate_dev() {
  local name
  read -r -p 'Migration name [update]: ' name
  name="${name:-update}"
  info "Creating/applying development migration: $name"
  prisma migrate dev --schema "$SCHEMA_FILE" --name "$name"
  ok 'Development migration applied.'
}

migrate_create_only() {
  local name
  read -r -p 'Migration name [update]: ' name
  name="${name:-update}"
  info "Creating migration without applying it: $name"
  prisma migrate dev --schema "$SCHEMA_FILE" --name "$name" --create-only
  ok 'Migration SQL created; it has not been applied.'
}

migrate_status() {
  info 'Checking migration status...'
  prisma migrate status --schema "$SCHEMA_FILE"
}

migrate_deploy() {
  warn 'migrate deploy is intended for staging/production-style application of existing migrations.'
  if ! confirm 'Apply all pending migrations to the configured database?'; then
    warn 'Cancelled.'
    return 0
  fi
  prisma migrate deploy --schema "$SCHEMA_FILE"
  ok 'Pending migrations deployed.'
}

db_push() {
  warn 'db push changes the database directly without creating migration history.'
  if ! confirm 'Push schema state directly to this database?'; then
    warn 'Cancelled.'
    return 0
  fi
  prisma db push --schema "$SCHEMA_FILE"
  ok 'Schema pushed to database.'
}

db_pull() {
  warn 'db pull introspects the database and can rewrite models in prisma/schema.prisma.'
  if ! confirm_phrase 'This can modify your Prisma schema file.' 'PULL'; then
    warn 'Cancelled.'
    return 0
  fi
  prisma db pull --schema "$SCHEMA_FILE"
  ok 'Database schema introspected into Prisma schema.'
}

seed_database() {
  require_prisma
  require_database_url
  info 'Seeding database...'

  # Karban currently has an explicit npm seed script. Keep this compatible with
  # Prisma versions where seed discovery/config changed.
  if node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts['prisma:seed'] ? 0 : 1)"; then
    npm run prisma:seed
  else
    "$PRISMA_BIN" db seed --schema "$SCHEMA_FILE"
  fi

  ok 'Database seed completed.'
}

open_studio() {
  info 'Starting Prisma Studio. Press Ctrl+C to return to this menu.'
  prisma studio --schema "$SCHEMA_FILE"
}

reset_database() {
  warn 'THIS DELETES ALL DATA in the configured development database.'
  if ! confirm_phrase 'Prisma migrate reset will recreate the database schema from migrations.' 'RESET'; then
    warn 'Cancelled.'
    return 0
  fi

  prisma migrate reset --schema "$SCHEMA_FILE" --force
  # Explicit generation + seed keeps behavior deterministic across Prisma versions.
  generate_client
  seed_database
  ok 'Database reset, Client generated, and seed completed.'
}

resolve_migration() {
  local name action
  read -r -p 'Migration folder/name to resolve: ' name
  if [[ -z "$name" ]]; then
    error 'Migration name is required.'
    return 1
  fi

  printf '%s\n' '1) Mark as applied'
  printf '%s\n' '2) Mark as rolled back'
  printf '> '
  IFS= read -r action

  case "$action" in
    1) prisma migrate resolve --schema "$SCHEMA_FILE" --applied "$name" ;;
    2) prisma migrate resolve --schema "$SCHEMA_FILE" --rolled-back "$name" ;;
    *) error 'Invalid selection.'; return 1 ;;
  esac
}

list_migrations() {
  printf '\n%bMigration folders%b\n' "$C_BOLD" "$C_RESET"
  hr
  if [[ ! -d "$MIGRATIONS_DIR" ]]; then
    warn 'No prisma/migrations directory exists yet.'
    return 0
  fi

  find "$MIGRATIONS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort || true
  if [[ -f "$MIGRATIONS_DIR/README.md" ]]; then
    printf '%s\n' "${C_DIM}README.md is also present.${C_RESET}"
  fi
}

execute_sql() {
  local sql
  warn 'This executes SQL directly and bypasses Prisma migration history.'
  read -r -p 'SQL (single line): ' sql
  if [[ -z "$sql" ]]; then
    warn 'Nothing to execute.'
    return 0
  fi
  if ! confirm 'Execute this SQL on the configured database?'; then
    warn 'Cancelled.'
    return 0
  fi
  require_prisma
  require_database_url
  printf '%s\n' "$sql" | "$PRISMA_BIN" db execute --stdin --schema "$SCHEMA_FILE"
}

start_postgres() {
  if [[ ! -f "$ROOT_DIR/docker-compose.yml" ]]; then
    error "docker-compose.yml not found at $ROOT_DIR"
    return 1
  fi
  command -v docker >/dev/null 2>&1 || { error 'Docker is not installed.'; return 1; }

  info 'Starting Karban PostgreSQL container...'
  (cd "$ROOT_DIR" && docker compose up -d postgres)
  ok 'PostgreSQL container requested.'
}

postgres_status() {
  if [[ ! -f "$ROOT_DIR/docker-compose.yml" ]]; then
    error "docker-compose.yml not found at $ROOT_DIR"
    return 1
  fi
  command -v docker >/dev/null 2>&1 || { error 'Docker is not installed.'; return 1; }
  (cd "$ROOT_DIR" && docker compose ps postgres)
}

stop_postgres() {
  if [[ ! -f "$ROOT_DIR/docker-compose.yml" ]]; then
    error "docker-compose.yml not found at $ROOT_DIR"
    return 1
  fi
  command -v docker >/dev/null 2>&1 || { error 'Docker is not installed.'; return 1; }

  if confirm 'Stop the Karban PostgreSQL container?'; then
    (cd "$ROOT_DIR" && docker compose stop postgres)
  fi
}

backend_typecheck() {
  require_node_npm
  info 'Running backend TypeScript typecheck...'
  npm run typecheck
  ok 'Backend typecheck passed.'
}

backend_test() {
  require_node_npm
  info 'Running backend tests...'
  npm test
  ok 'Backend tests passed.'
}

backend_build() {
  require_node_npm
  info 'Building backend...'
  npm run build
  ok 'Backend build passed.'
}

quality_check() {
  validate_schema
  generate_client
  backend_typecheck
  backend_test
  backend_build
  ok 'Prisma + backend quality check passed.'
}

bootstrap_development() {
  printf '\n%bFull development database setup%b\n' "$C_BOLD" "$C_RESET"
  hr
  ensure_env_file

  if [[ -z "$(read_env_value DATABASE_URL)" ]]; then
    set_database_url_menu
  else
    printf 'Using: %s\n' "$(mask_database_url "$(read_env_value DATABASE_URL)")"
    if confirm 'Change DATABASE_URL first?'; then
      set_database_url_menu
    fi
  fi

  if [[ ! -x "$PRISMA_BIN" ]]; then
    install_dependencies
  fi

  if [[ -f "$ROOT_DIR/docker-compose.yml" ]] && command -v docker >/dev/null 2>&1; then
    if confirm 'Start the local PostgreSQL Docker service?'; then
      start_postgres
    fi
  fi

  validate_schema
  format_schema
  generate_client

  local migration_name
  read -r -p 'Migration name for this setup [init]: ' migration_name
  migration_name="${migration_name:-init}"
  prisma migrate dev --schema "$SCHEMA_FILE" --name "$migration_name"

  # Be explicit for predictable Prisma 6/7 behavior.
  generate_client

  if confirm 'Run database seed now?'; then
    seed_database
  fi

  ok 'Development database setup completed.'
}

production_prepare() {
  printf '\n%bProduction/staging migration flow%b\n' "$C_BOLD" "$C_RESET"
  hr
  warn 'Verify DATABASE_URL points to the intended staging/production database before continuing.'
  show_config

  if ! confirm_phrase 'Apply committed migrations to this database.' 'DEPLOY'; then
    warn 'Cancelled.'
    return 0
  fi

  validate_schema
  generate_client
  prisma migrate deploy --schema "$SCHEMA_FILE"
  migrate_status
  ok 'Production/staging migration flow completed.'
}

# ---------- command-line shortcuts ----------
print_help() {
  cat <<'EOF'
Karban Prisma Manager

Usage:
  ./prisma-cli.sh                 Open interactive menu
  ./prisma-cli.sh menu            Open interactive menu
  ./prisma-cli.sh config          Show current database config
  ./prisma-cli.sh set-url         Configure DATABASE_URL
  ./prisma-cli.sh install         Install backend dependencies
  ./prisma-cli.sh test-connection Test DB connection
  ./prisma-cli.sh validate        prisma validate
  ./prisma-cli.sh format          prisma format
  ./prisma-cli.sh generate        prisma generate
  ./prisma-cli.sh status          prisma migrate status
  ./prisma-cli.sh deploy          prisma migrate deploy (asks confirmation)
  ./prisma-cli.sh seed            Seed database
  ./prisma-cli.sh studio          Open Prisma Studio
  ./prisma-cli.sh reset           Reset dev DB (requires RESET confirmation)
  ./prisma-cli.sh bootstrap       Full interactive development setup
  ./prisma-cli.sh quality         Validate + generate + typecheck + test + build
  ./prisma-cli.sh help            Show this help

Optional:
  KARBAN_BACKEND_DIR=/path/to/backend ./prisma-cli.sh
EOF
}

run_shortcut() {
  case "${1:-menu}" in
    menu) return 1 ;;
    config) show_config ;;
    set-url) set_database_url_menu ;;
    install) install_dependencies ;;
    test-connection) test_connection ;;
    validate) validate_schema ;;
    format) format_schema ;;
    generate) generate_client ;;
    status) migrate_status ;;
    deploy) migrate_deploy ;;
    seed) seed_database ;;
    studio) open_studio ;;
    reset) reset_database ;;
    bootstrap) bootstrap_development ;;
    quality) quality_check ;;
    help|-h|--help) print_help ;;
    *)
      error "Unknown command: $1"
      print_help
      exit 2
      ;;
  esac
  return 0
}

# ---------- menu ----------
print_menu() {
  clear 2>/dev/null || true
  load_database_url

  printf '%bKarban Prisma / PostgreSQL Manager%b\n' "$C_BOLD" "$C_RESET"
  printf 'Backend: %s\n' "$BACKEND_DIR"
  printf 'DB:      %s\n' "$(mask_database_url "${DATABASE_URL:-<missing>}")"
  hr
  printf '%s\n' ' 1) Show configuration / versions'
  printf '%s\n' ' 2) Set or change DATABASE_URL'
  printf '%s\n' ' 3) Test database connection'
  printf '%s\n' ' 4) Install backend dependencies'
  printf '%s\n' ' 5) Prisma validate schema'
  printf '%s\n' ' 6) Prisma format schema'
  printf '%s\n' ' 7) Prisma generate client'
  printf '%s\n' ' 8) Migrate dev (create + apply migration)'
  printf '%s\n' ' 9) Migrate create-only (SQL only)'
  printf '%s\n' '10) Migration status'
  printf '%s\n' '11) Migrate deploy (staging/production)'
  printf '%s\n' '12) DB push (no migration history)'
  printf '%s\n' '13) DB pull / introspect'
  printf '%s\n' '14) Seed database'
  printf '%s\n' '15) Open Prisma Studio'
  printf '%s\n' '16) RESET development database (destructive)'
  printf '%s\n' '17) Resolve failed/applied migration'
  printf '%s\n' '18) List migration folders'
  printf '%s\n' '19) Execute one SQL statement'
  printf '%s\n' '20) Start local PostgreSQL with Docker'
  printf '%s\n' '21) PostgreSQL Docker status'
  printf '%s\n' '22) Stop PostgreSQL Docker service'
  printf '%s\n' '23) Full development setup wizard'
  printf '%s\n' '24) Production/staging migration wizard'
  printf '%s\n' '25) Backend typecheck'
  printf '%s\n' '26) Backend tests'
  printf '%s\n' '27) Backend build'
  printf '%s\n' '28) Full Prisma + backend quality check'
  printf '%s\n' ' 0) Exit'
  hr
  printf '> '
}

interactive_menu() {
  local choice
  while true; do
    print_menu
    IFS= read -r choice
    printf '\n'

    # Handle action failures without killing the menu.
    set +e
    case "$choice" in
      1) show_config ;;
      2) set_database_url_menu ;;
      3) test_connection ;;
      4) install_dependencies ;;
      5) validate_schema ;;
      6) format_schema ;;
      7) generate_client ;;
      8) migrate_dev ;;
      9) migrate_create_only ;;
      10) migrate_status ;;
      11) migrate_deploy ;;
      12) db_push ;;
      13) db_pull ;;
      14) seed_database ;;
      15) open_studio ;;
      16) reset_database ;;
      17) resolve_migration ;;
      18) list_migrations ;;
      19) execute_sql ;;
      20) start_postgres ;;
      21) postgres_status ;;
      22) stop_postgres ;;
      23) bootstrap_development ;;
      24) production_prepare ;;
      25) backend_typecheck ;;
      26) backend_test ;;
      27) backend_build ;;
      28) quality_check ;;
      0) printf 'Bye.\n'; exit 0 ;;
      *) error 'Invalid selection.' ;;
    esac
    local status=$?
    set -e

    if [[ $status -ne 0 ]]; then
      error "Action failed with exit code $status."
    fi

    pause
  done
}

if run_shortcut "${1:-menu}"; then
  exit 0
fi

interactive_menu
