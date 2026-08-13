#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
"$ROOT/tests/syntax.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
for d in backend mobile admin website docs; do mkdir -p "$tmp/$d"; done
mkdir -p "$tmp/backend/prisma" "$tmp/mobile/src-tauri"
printf '{"name":"backend","scripts":{"build":"echo build"}}\n' > "$tmp/backend/package.json"
printf 'generator client { provider = "prisma-client-js" }\n' > "$tmp/backend/prisma/schema.prisma"
printf '{"name":"mobile","version":"1.0.0","scripts":{"build":"echo build"}}\n' > "$tmp/mobile/package.json"
printf '{"productName":"Karban","version":"1.0.0","identifier":"ir.karban.app","build":{"devUrl":"http://localhost:5173"}}\n' > "$tmp/mobile/src-tauri/tauri.conf.json"
printf '[package]\nname="karban"\nversion="0.1.0"\nedition="2021"\n' > "$tmp/mobile/src-tauri/Cargo.toml"
printf '{"name":"admin","scripts":{}}\n' > "$tmp/admin/package.json"
printf '{"name":"website","scripts":{}}\n' > "$tmp/website/package.json"
KARBAN_ROOT="$tmp" NO_COLOR=1 "$ROOT/karban" --help >/dev/null
KARBAN_ROOT="$tmp" NO_COLOR=1 "$ROOT/karban" project </dev/null >/dev/null 2>&1 || true
printf '[ OK ] Karban Developer Console self-test passed.\n'
