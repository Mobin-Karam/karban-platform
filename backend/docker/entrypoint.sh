#!/bin/sh
set -eu

if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  ./node_modules/.bin/prisma migrate deploy
fi

if [ "${RUN_SEED:-false}" = "true" ]; then
  echo "RUN_SEED=true is not supported in the production image because seed.ts depends on dev tooling." >&2
  echo "Run npm run prisma:seed from a development/admin environment instead." >&2
fi

exec node dist/main.js
