import { Injectable } from '@nestjs/common';
import { IntegrationCategory } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { ConfigCryptoService } from '../config-crypto/config-crypto.service';

type ApiIrConfig = { token?: string; baseUrl?: string; smsPath?: string; callPath?: string };
@Injectable()
export class ApiIrOtpProvider {
  constructor(private readonly prisma: PrismaService, private readonly crypto: ConfigCryptoService) {}
  async send(phone: string, code: string, channel: 'sms' | 'call'): Promise<string | null> {
    const row = await this.prisma.integrationConfig.findUnique({ where: { category_providerKey: { category: IntegrationCategory.OTP, providerKey: 'apiir' } } });
    if (!row?.enabled) {
      if (process.env.NODE_ENV !== 'production') { console.info(`[DEV OTP] ${phone} => ${code}`); return 'dev-console'; }
      throw new Error('OTP_PROVIDER_NOT_CONFIGURED');
    }
    const config = this.crypto.decrypt<ApiIrConfig>(row.encryptedConfig);
    if (!config.token) throw new Error('APIIR_TOKEN_MISSING');
    const baseUrl = config.baseUrl ?? 'https://s.api.ir';
    const path = channel === 'call' ? (config.callPath ?? '/api/sw1/CallOTP') : (config.smsPath ?? '/api/sw1/SmsOTP');
    const response = await fetch(`${baseUrl}${path}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${config.token}` },
      body: JSON.stringify({ number: phone, code }),
      signal: AbortSignal.timeout(10_000),
    });
    const text = await response.text();
    if (!response.ok) throw new Error(`APIIR_OTP_FAILED:${response.status}:${text.slice(0, 240)}`);
    try {
      const data = JSON.parse(text) as Record<string, unknown>;
      return typeof data.id === 'string' ? data.id : typeof data.requestId === 'string' ? data.requestId : null;
    } catch { return null; }
  }
}
