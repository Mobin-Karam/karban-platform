#!/usr/bin/env bash
set -Eeuo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET="${1:-$PWD}"
TARGET="$(cd "$TARGET" && pwd -P)"
for d in backend mobile admin website; do [[ -d "$TARGET/$d" ]] || { echo "Missing $TARGET/$d" >&2; exit 1; }; done
DEST="$TARGET/tools/karban-developer-console"
mkdir -p "$TARGET/tools"
rm -rf "$DEST"
cp -R "$SRC" "$DEST"
cat > "$TARGET/karban" <<WRAP
#!/usr/bin/env bash
export KARBAN_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd -P)"
exec "\$KARBAN_ROOT/tools/karban-developer-console/karban" "\$@"
WRAP
chmod +x "$TARGET/karban" "$DEST/karban" "$DEST"/*.sh "$DEST"/tools/*.sh "$DEST"/scripts/*.sh "$DEST"/tests/*.sh
printf 'Attached Karban Developer Console.\n\nRun:\n  cd %s\n  ./karban\n' "$TARGET"
