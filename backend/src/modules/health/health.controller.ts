import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
@Controller({ path: 'health', version: '1' })
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}
  @Get() health(): { status: string; time: string } { return { status: 'ok', time: new Date().toISOString() }; }
  @Get('ready') async ready(): Promise<{ status: string }> { await this.prisma.$queryRaw`SELECT 1`; return { status: 'ready' }; }
}
