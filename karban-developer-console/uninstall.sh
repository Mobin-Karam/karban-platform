#!/usr/bin/env bash
set -Eeuo pipefail
for p in "$HOME/.local/bin/karban" /usr/local/bin/karban; do
  if [[ -L "$p" ]]; then rm -f "$p" && printf 'Removed %s\n' "$p"; fi
done
