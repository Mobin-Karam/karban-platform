import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import type { Request } from 'express';
import { mergeMap, type Observable } from 'rxjs';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminAuditInterceptor implements NestInterceptor {
  constructor(private readonly prisma: PrismaService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<Request>();
    const entityId = request.params.id ?? request.params.key;
    if (request.method === 'GET') return next.handle();

    return next.handle().pipe(
      mergeMap(async (result: unknown) => {
        await this.prisma.auditLog.create({
          data: {
            actorId: request.principal?.sub,
            action: `ADMIN_${request.method}`,
            entityType: 'ADMIN_API',
            entityId: Array.isArray(entityId) ? entityId[0] : entityId,
            metadata: { method: request.method, path: request.originalUrl.split('?')[0] },
            ip: request.ip,
            userAgent: request.header('user-agent')?.slice(0, 500),
          },
        });
        return result;
      }),
    );
  }
}
