#!/usr/bin/env bash
set -Eeuo pipefail
root="${1:-.}"
patterns='(-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|postgres(ql)?://[^[:space:]]+:[^*@[:space:]]+@|JWT_SECRET[[:space:]]*=[[:space:]]*[^<${][^[:space:]]{15,}|MASTER_ENCRYPTION_KEY[[:space:]]*=[[:space:]]*[A-Fa-f0-9]{32,}|Authorization:[[:space:]]*Bearer[[:space:]]+[A-Za-z0-9._~-]{20,})'
set +e
matches=$(grep -RniE --binary-files=without-match --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.next --exclude-dir=dist --exclude-dir=target --exclude='*.lock' "$patterns" "$root" 2>/dev/null | grep -vE 'karban:karban_dev@(localhost|postgres)|\$\{enc_pass\}' || true)
rc=$?
set -e
if [[ $rc -eq 0 && -n "$matches" ]]; then
  printf '[WARN] Possible secret-like literals found. Review manually:\n%s\n' "$matches"
  exit 1
fi
printf '[ OK ] No obvious secret literals detected by the lightweight scan.\n'
