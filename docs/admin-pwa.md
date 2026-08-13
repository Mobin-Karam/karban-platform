# Admin PWA

The admin is a local-first Vite React PWA. It persists TanStack Query cache for faster re-entry while API data is refreshed according to query staleness. The service worker caches only the shell/static assets and deliberately does not cache `/api` responses.

When a changed service worker reaches `waiting`, `UpdateModal` appears. Clicking update sends `SKIP_WAITING`; on `controllerchange` the page reloads once. Update the cache/version string with each release (or inject package version in CI) so a new deployment is never confused with the previous cache.

Data tables use server-side bounded queries, debounced search, cursor navigation and keyboard row focus. Sidebar `G + key` shortcuts support keyboard-heavy administration.
