/**
 * Access-token session boundary.
 *
 * The native starter intentionally does not persist bearer tokens in WebView
 * localStorage/sessionStorage. A production persistent-login implementation can
 * hydrate this module from a platform-keystore/Stronghold-backed refresh-token
 * provider during StartupCoordinator initialization.
 */
let accessToken: string | null = null;

export function getAccessToken(): string | null {
  return accessToken;
}

export function setAccessToken(value: string): void {
  accessToken = value;
}

export function clearAccessToken(): void {
  accessToken = null;
}
