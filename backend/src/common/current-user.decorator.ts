import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';
export const CurrentUserId = createParamDecorator((_data: unknown, ctx: ExecutionContext): string => {
  const request = ctx.switchToHttp().getRequest<Request>();
  if (!request.principal) throw new Error('JwtAuthGuard must run before CurrentUserId');
  return request.principal.sub;
});
