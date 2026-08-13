import { Injectable } from "@nestjs/common";
import { IntegrationCategory } from "@prisma/client";
import { PrismaService } from "../../prisma/prisma.service";
import { ConfigCryptoService } from "../config-crypto/config-crypto.service";
type GenericSmsConfig = {
  url: string;
  method?: string;
  authHeaderName?: string;
  authHeaderValue?: string;
  sender?: string;
  bodyTemplate?: Record<string, unknown>;
  responseIdPath?: string;
};
function replace(value: unknown, vars: Record<string, string>): unknown {
  if (typeof value === "string")
    return value.replace(/\{\{(\w+)\}\}/g, (_m, k: string) => vars[k] ?? "");
  if (Array.isArray(value)) return value.map((v) => replace(v, vars));
  if (value && typeof value === "object")
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([k, v]) => [
        k,
        replace(v, vars),
      ]),
    );
  return value;
}
function dig(obj: unknown, path: string | undefined): string | null {
  if (!path || !obj || typeof obj !== "object") return null;
  let cur: unknown = obj;
  for (const key of path.split(".")) {
    if (!cur || typeof cur !== "object") return null;
    cur = (cur as Record<string, unknown>)[key];
  }
  return typeof cur === "string" || typeof cur === "number"
    ? String(cur)
    : null;
}
@Injectable()
export class SmsGatewayService {
  constructor(
    private readonly p: PrismaService,
    private readonly crypto: ConfigCryptoService,
  ) {}
  async send(providerKey: string, phone: string, message: string) {
    const row = await this.p.integrationConfig.findUnique({
      where: {
        category_providerKey: {
          category: IntegrationCategory.SMS,
          providerKey,
        },
      },
    });
    if (!row?.enabled) throw new Error("SMS_PROVIDER_DISABLED");
    const cfg = this.crypto.decrypt<GenericSmsConfig>(row.encryptedConfig);
    const headers: Record<string, string> = {
      "content-type": "application/json",
      accept: "application/json",
    };
    if (cfg.authHeaderName && cfg.authHeaderValue)
      headers[cfg.authHeaderName] = cfg.authHeaderValue;
    const body = replace(
      cfg.bodyTemplate ?? {
        mobile: "{{phone}}",
        message: "{{message}}",
        sender: "{{sender}}",
      },
      { phone, message, sender: cfg.sender ?? "" },
    );
    const res = await fetch(cfg.url, {
      method: cfg.method ?? "POST",
      headers,
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(12_000),
    });
    const text = await res.text();
    if (!res.ok)
      throw new Error(`SMS_SEND_FAILED:${res.status}:${text.slice(0, 300)}`);
    let data: unknown;
    try {
      data = JSON.parse(text);
    } catch {
      data = { raw: text };
    }
    return { providerMessageId: dig(data, cfg.responseIdPath), raw: data };
  }
  async unitCost(providerKey: string) {
    const row = await this.p.integrationConfig.findUnique({
      where: {
        category_providerKey: {
          category: IntegrationCategory.SMS,
          providerKey,
        },
      },
    });
    const pc = row?.publicConfig as Record<string, unknown> | null;
    const v = pc?.unitCostRial;
    return typeof v === "number"
      ? BigInt(Math.floor(v))
      : typeof v === "string"
        ? BigInt(v)
        : 0n;
  }
}
