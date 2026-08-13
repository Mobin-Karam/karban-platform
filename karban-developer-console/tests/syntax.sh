#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fail=0 count=0
while IFS= read -r -d '' file; do
  count=$((count+1)); bash -n "$file" || fail=1
done < <(find "$ROOT" -type f \( -name '*.sh' -o -name 'karban' \) -print0)
if command -v node >/dev/null 2>&1; then
  while IFS= read -r -d '' file; do count=$((count+1)); node --check "$file" || fail=1; done < <(find "$ROOT/scripts" -type f -name '*.mjs' -print0)
fi
printf 'Checked %d console source files.\n' "$count"
(( fail == 0 ))
