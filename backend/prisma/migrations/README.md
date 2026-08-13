# Prisma migrations

The source schema and seed are included, but an initial migration SQL file is **not fabricated** in this package because the packaging environment could not download/run the Prisma CLI.

On the first networked development machine, create and review the initial migration:

```bash
cd backend
npm ci
npx prisma generate
npx prisma validate
npx prisma migrate dev --name init
npm run prisma:seed
```

Commit the generated `prisma/migrations/<timestamp>_init/` directory before deployment. Production should use `npm run prisma:deploy`, never `migrate dev`.
