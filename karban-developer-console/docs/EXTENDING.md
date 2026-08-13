# Extending the console

Add a Bash module under `modules/` and source it from `karban`.

A module should:

1. expose a `<name>_menu` function;
2. use `k_header`, `k_section`, `k_info`, `k_ok`, `k_warn`, `k_err` for consistent UI;
3. use `k_danger_confirm` for destructive operations;
4. use `k_log_run` for build/test operations worth retaining;
5. never log raw secrets;
6. gracefully detect missing optional dependencies;
7. keep application-specific logic in the application, not the console.

Use Node helpers only when structured JSON manipulation is safer than shell parsing. Do not add a Rust sidecar merely for terminal presentation; the console is intentionally portable Bash.
