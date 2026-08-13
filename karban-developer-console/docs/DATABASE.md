# Database console

The console treats Prisma migrations as the application database history and PostgreSQL tools as operational utilities.

Development:

- `prisma migrate dev`
- create-only migrations
- seed/reset
- Studio
- db pull/push for deliberate development use

Staging/production:

- inspect status
- preview diff
- create backup
- use `prisma migrate deploy`
- never use development reset

Backups use PostgreSQL custom format (`pg_dump --format=custom`) and create a checksum next to the dump. Restore requires typing the target database name.
