import { Injectable } from '@nestjs/common';
import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';
@Injectable()
export class ConfigCryptoService {
  private key(): Buffer { return Buffer.from(process.env.CONFIG_ENCRYPTION_KEY ?? '', 'hex'); }
  encrypt(value: Record<string, unknown>): string {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.key(), iv);
    const encrypted = Buffer.concat([cipher.update(JSON.stringify(value), 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();
    return `${iv.toString('base64url')}.${tag.toString('base64url')}.${encrypted.toString('base64url')}`;
  }
  decrypt<T extends Record<string, unknown>>(payload: string): T {
    const [ivPart, tagPart, bodyPart] = payload.split('.');
    if (!ivPart || !tagPart || !bodyPart) throw new Error('Invalid encrypted config');
    const decipher = createDecipheriv('aes-256-gcm', this.key(), Buffer.from(ivPart, 'base64url'));
    decipher.setAuthTag(Buffer.from(tagPart, 'base64url'));
    const decrypted = Buffer.concat([decipher.update(Buffer.from(bodyPart, 'base64url')), decipher.final()]).toString('utf8');
    return JSON.parse(decrypted) as T;
  }
}
