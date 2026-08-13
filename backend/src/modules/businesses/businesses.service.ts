import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { safeLimit } from '../../common/pagination';
import { CreateBusinessDto, BusinessSearchDto, UpdateBusinessDto } from './dto';

function distanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const r = 6371; const dLat = (lat2-lat1)*Math.PI/180; const dLon = (lon2-lon1)*Math.PI/180;
  const a = Math.sin(dLat/2)**2 + Math.cos(lat1*Math.PI/180)*Math.cos(lat2*Math.PI/180)*Math.sin(dLon/2)**2;
  return r * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
}
@Injectable()
export class BusinessesService {
  constructor(private readonly prisma: PrismaService) {}
  async create(ownerId: string, dto: CreateBusinessDto) {
    const type = await this.prisma.businessType.findUnique({ where: { key: 'plumber' } });
    if (!type?.enabled) throw new BadRequestException({ code: 'BUSINESS_TYPE_DISABLED', message: 'ثبت این نوع کسب‌وکار فعال نیست' });
    return this.prisma.$transaction(async (tx) => {
      const business = await tx.business.create({ data: { ownerId, businessTypeId: type.id, ...dto, settings: { onboardingVersion: 1, completedSteps: ['identity','profile'] } } });
      await tx.businessMembership.create({ data: { businessId: business.id, userId: ownerId, role: 'OWNER', status: 'ACTIVE', title: 'مالک' } });
      await tx.wallet.create({ data: { ownerType: 'BUSINESS', businessId: business.id } });
      await tx.coinWallet.create({ data: { businessId: business.id, levelKey: 'starter' } });
      await tx.businessSmsSetting.create({ data: { businessId: business.id } });
      const free = await tx.plan.findUnique({ where: { key: 'free' } });
      if (free) await tx.businessSubscription.create({ data: { businessId: business.id, planId: free.id } });
      return business;
    });
  }
  async update(id: string, dto: UpdateBusinessDto) { return this.prisma.business.update({ where: { id }, data: dto }); }
  async mine(userId: string) {
    return this.prisma.business.findMany({ where: { OR: [{ ownerId: userId }, { memberships: { some: { userId, status: 'ACTIVE' } } }] }, include: { businessType: true }, orderBy: { createdAt: 'desc' } });
  }
  async publicDetail(slug: string) {
    const item = await this.prisma.business.findFirst({ where: { slug, isPublic: true, frozenAt: null }, include: { owner:{include:{profile:true}}, businessType: true, serviceCategories: { where: { active: true }, include: { services: { where: { active: true }, take: 50 } } }, reviews: { where: { status: 'PUBLISHED' }, orderBy: { createdAt: 'desc' }, take: 10, include: { user: { include: { profile: true } } } } } });
    if (!item) throw new NotFoundException({ code: 'BUSINESS_NOT_FOUND', message: 'کسب‌وکار پیدا نشد' });
    return { ...item, description:item.bio, availableNow:item.isAvailable, services:item.serviceCategories.flatMap(c=>c.services), reviews:item.reviews.map(({user,...r})=>({...r,customer:user})) };
  }
  async search(dto: BusinessSearchDto) {
    const take = safeLimit(dto.limit, 20, 50);
    const where: Prisma.BusinessWhereInput = { isPublic: true, frozenAt: null, ...(dto.availableOnly ? { isAvailable: true } : {}), ...(dto.verifiedOnly ? { isVerified: true } : {}), ...(dto.city ? { city: dto.city } : {}), ...(dto.province ? { province: dto.province } : {}) };
    if (dto.q) where.OR = [{ name: { contains: dto.q, mode: 'insensitive' } }, { bio: { contains: dto.q, mode: 'insensitive' } }, { services: { some: { name: { contains: dto.q, mode: 'insensitive' }, active: true } } }];
    const rows = await this.prisma.business.findMany({ where, take: take + 1, ...(dto.cursor ? { cursor: { id: dto.cursor }, skip: 1 } : {}), orderBy: [{ isVerified: 'desc' }, { averageRating: 'desc' }, { id: 'asc' }], select: { id:true, slug:true, name:true, bio:true, city:true, province:true, latitude:true, longitude:true, logoUrl:true, coverUrl:true, isAvailable:true, isVerified:true, averageRating:true, reviewsCount:true, businessType:{ select:{key:true,nameFa:true,iconKey:true} } } });
    const hasNextPage = rows.length > take; const sliced = rows.slice(0, take);
    const items = sliced.map((row) => ({ ...row, description:row.bio, availableNow:row.isAvailable, distanceKm: dto.latitude != null && dto.longitude != null && row.latitude != null && row.longitude != null ? Math.round(distanceKm(dto.latitude,dto.longitude,row.latitude,row.longitude)*10)/10 : null })).sort((a,b) => a.distanceKm != null && b.distanceKm != null ? a.distanceKm-b.distanceKm : 0);
    return { items, pageInfo: { hasNextPage, nextCursor: hasNextPage ? sliced.at(-1)?.id ?? null : null } };
  }
}
