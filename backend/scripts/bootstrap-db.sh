#!/usr/bin/env sh
set -eu
npx prisma generate
npx prisma validate
npx prisma migrate dev --name init
npm run prisma:seed
