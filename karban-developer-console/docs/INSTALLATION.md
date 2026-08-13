# Installation

## Option A — keep the console standalone

```bash
cd karban-developer-console
chmod +x karban install.sh
./install.sh
cd /path/to/karban-platform
karban
```

If the platform cannot be auto-detected:

```bash
export KARBAN_ROOT=/path/to/karban-platform
karban
```

## Option B — attach the console directly to the Karban source tree

From the console folder:

```bash
./attach-to-project.sh /path/to/karban-platform
```

That creates:

```text
karban-platform/
  karban
  tools/
    karban-developer-console/
```

Then:

```bash
cd /path/to/karban-platform
./karban
```

## Optional dependencies

The console itself starts with Bash. Features are enabled when their native tools exist:

- Node + the app package manager — JavaScript/TypeScript applications
- Prisma package in backend — Prisma operations
- PostgreSQL client tools — `psql`, `pg_dump`, `pg_restore`
- Docker Compose — local services
- Rust/Cargo — Tauri Rust checks/builds
- Android SDK/JDK — Android builds, signing, ADB/emulators
- Xcode on macOS — iOS
- `tmux` — optional multi-process workspace
- `shellcheck` — optional Bash linting
