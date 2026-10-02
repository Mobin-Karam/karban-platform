# Prisma migrations

The repository now includes the initial PostgreSQL migration under:

```text
backend/prisma/migrations/20260811173844_start/
```

## First local bootstrap

```bash
cd backend
npm ci
npx prisma generate
npx prisma validate
npm run prisma:deploy
npm run prisma:seed
```

For normal schema development, edit `prisma/schema.prisma` and create a reviewed migration:

```bash
npm run prisma:migrate -- --name describe_the_change
```

Commit both the schema change and generated migration.

## Production

Production environments should apply committed migrations with:

```bash
npm run prisma:deploy
```

Do not use `prisma migrate dev` as the production deployment mechanism.
