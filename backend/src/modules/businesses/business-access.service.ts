import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { MembershipRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
@Injectable()
export class BusinessAccessService {
  constructor(private readonly prisma: PrismaService) {}
  async require(businessId: string, userId: string, roles: MembershipRole[] = ['OWNER','MANAGER','STAFF']): Promise<void> {
    const business = await this.prisma.business.findUnique({ where: { id: businessId }, select: { ownerId: true, frozenAt: true } });
    if (!business) throw new NotFoundException({ code: 'BUSINESS_NOT_FOUND', message: 'کسب‌وکار پیدا نشد' });
    if (business.frozenAt) throw new ForbiddenException({ code: 'BUSINESS_FROZEN', message: 'کسب‌وکار غیرفعال شده است' });
    if (business.ownerId === userId && roles.includes('OWNER')) return;
    const membership = await this.prisma.businessMembership.findUnique({ where: { businessId_userId: { businessId, userId } } });
    if (!membership || membership.status !== 'ACTIVE' || !roles.includes(membership.role)) throw new ForbiddenException({ code: 'BUSINESS_ACCESS_DENIED', message: 'دسترسی کافی ندارید' });
  }
}
