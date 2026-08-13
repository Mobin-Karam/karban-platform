#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PREFIX="${HOME}/.local/bin"
if [[ "${1:-}" == '--system' ]]; then PREFIX='/usr/local/bin'; fi
mkdir -p "$PREFIX"
ln -sfn "$ROOT/karban" "$PREFIX/karban"
printf 'Installed command: %s/karban\n' "$PREFIX"
case ":$PATH:" in *":$PREFIX:"*) :;; *) printf '\nAdd this to your shell profile:\n  export PATH="%s:$PATH"\n' "$PREFIX";; esac
printf '\nRun from the Karban project root:\n  karban\n'
