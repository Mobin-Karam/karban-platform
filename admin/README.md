# Karban Admin PWA

Local-first administration console. Static shell/assets are cached by the service worker; API responses are intentionally not stored by the service worker. TanStack Query persists its cache in browser storage with a version buster, giving fast reloads while still allowing controlled data refresh.

When a new service worker is installed and waiting, the app shows a modal. Clicking update sends `SKIP_WAITING`; `controllerchange` reloads once, so users do not manually clear browser cache.

Keyboard navigation: press `G` then the shortcut shown in the sidebar, e.g. `G D` dashboard, `G U` users, `G B` businesses.
