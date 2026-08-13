import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from '@nestjs/common';
import type { Request, Response } from 'express';
import { randomUUID } from 'node:crypto';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(error: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const requestId = request.header('x-request-id') ?? randomUUID();
    const status = error instanceof HttpException ? error.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR;
    const raw = error instanceof HttpException ? error.getResponse() : null;
    const message = typeof raw === 'string' ? raw : (raw && typeof raw === 'object' && 'message' in raw ? (raw as { message: unknown }).message : 'Internal server error');
    const code = raw && typeof raw === 'object' && 'code' in raw ? String((raw as { code: unknown }).code) : `HTTP_${status}`;
    response.status(status).json({ success: false, error: { code, message, requestId } });
  }
}
