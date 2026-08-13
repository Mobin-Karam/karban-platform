# Console architecture

```text
karban
  |
  +-- lib/
  |    +-- ui.sh          terminal components and confirmation flows
  |    +-- core.sh        project/package/Git utilities
  |    +-- app.sh         generic JS application actions
  |    +-- security.sh    masking/redaction helpers
  |    +-- state.sh       logs/artifacts/backups/config
  |    +-- status.sh      lightweight dashboard checks
  |
  +-- modules/
  |    +-- project.sh
  |    +-- workspace.sh
  |    +-- database.sh
  |    +-- backend.sh
  |    +-- admin.sh
  |    +-- mobile.sh
  |    +-- website.sh
  |    +-- docker.sh
  |    +-- integrations.sh
  |    +-- storage.sh
  |    +-- testing.sh
  |    +-- build.sh
  |    +-- release.sh
  |    +-- environment.sh
  |    +-- logs.sh
  |    +-- diagnostics.sh
  |
  +-- tools/
  |    +-- prisma-manager.sh
  |    +-- tauri-android-toolkit.sh
  |
  +-- scripts/
       +-- json-read.mjs
       +-- json-write.mjs
       +-- parse-db-url.mjs
       +-- mobile-manifest-report.mjs
       +-- release-report.mjs
       +-- secret-scan.sh
```

The top level coordinates the project but does not merge application dependency graphs. Every Karban application keeps its own `package.json`, build, TypeScript config and environment configuration.
