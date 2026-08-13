import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import type { Request } from 'express';
@Injectable()
export class SuperAdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request>();
    if (request.principal?.accountType !== 'SUPERADMIN') throw new ForbiddenException({ code: 'SUPERADMIN_REQUIRED', message: 'Superadmin access required' });
    return true;
  }
}
