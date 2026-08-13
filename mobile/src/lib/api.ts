import { getAccessToken } from "./session";
const base =
  (import.meta.env.VITE_API_URL as string | undefined)?.replace(/\/$/, "") ??
  "http://localhost:3000/api/v1";
export class ApiError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly status: number,
    public readonly details?: unknown,
  ) {
    super(message);
  }
}
function token() {
  return getAccessToken();
}
export async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers);
  headers.set("accept", "application/json");
  if (init.body && !headers.has("content-type"))
    headers.set("content-type", "application/json");
  const t = token();
  if (t) headers.set("authorization", `Bearer ${t}`);
  const res = await fetch(`${base}${path}`, {
    ...init,
    headers,
    signal: init.signal ?? AbortSignal.timeout(15000),
  });
  const payload = (await res.json().catch(() => null)) as {
    success?: boolean;
    data?: T;
    error?: { code?: string; message?: string; details?: unknown };
  } | null;
  if (!res.ok || !payload?.success)
    throw new ApiError(
      payload?.error?.code ?? `HTTP_${res.status}`,
      payload?.error?.message ?? "خطا در ارتباط با سرور",
      res.status,
      payload?.error?.details,
    );
  return payload.data as T;
}
export const post = <T>(path: string, body: unknown) =>
  api<T>(path, { method: "POST", body: JSON.stringify(body) });
export const patch = <T>(path: string, body: unknown) =>
  api<T>(path, { method: "PATCH", body: JSON.stringify(body) });

export async function uploadFile(
  file: File,
  options: {
    purpose: string;
    businessId?: string;
    visibility?: "PUBLIC" | "PRIVATE";
  },
) {
  const form = new FormData();
  form.append("file", file);
  const qs = new URLSearchParams({
    purpose: options.purpose,
    visibility: options.visibility ?? "PRIVATE",
  });
  if (options.businessId) qs.set("businessId", options.businessId);
  const headers: Record<string, string> = { accept: "application/json" };
  const t = token();
  if (t) headers.authorization = `Bearer ${t}`;
  const res = await fetch(`${base}/media/upload?${qs.toString()}`, {
    method: "POST",
    headers,
    body: form,
  });
  const payload = (await res.json()) as {
    success?: boolean;
    data?: { url: string };
    error?: { message?: string };
  };
  if (!res.ok || !payload.success || !payload.data)
    throw new ApiError(
      "UPLOAD_FAILED",
      payload.error?.message ?? "بارگذاری ناموفق بود",
      res.status,
    );
  return payload.data;
}
