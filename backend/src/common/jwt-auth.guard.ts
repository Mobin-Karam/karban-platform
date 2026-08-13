import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import type { Request } from 'express';
import type { AuthPrincipal } from './types';

declare module 'express-serve-static-core' { interface Request { principal?: AuthPrincipal } }

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const token = request.header('authorization')?.replace(/^Bearer\s+/i, '');
    if (!token) throw new UnauthorizedException({ code: 'AUTH_REQUIRED', message: 'Authentication required' });
    try {
      request.principal = await this.jwt.verifyAsync<AuthPrincipal>(token, { secret: process.env.JWT_SECRET });
      return true;
    } catch {
      throw new UnauthorizedException({ code: 'INVALID_TOKEN', message: 'Invalid or expired token' });
    }
  }
}
