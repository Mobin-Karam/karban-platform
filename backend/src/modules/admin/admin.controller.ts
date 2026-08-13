import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import {
  InvoiceStatus,
  PaymentPurpose,
  PaymentStatus,
  Prisma,
  ReviewStatus,
  WalletOwnerType,
} from '@prisma/client';
import { JwtAuthGuard } from '../../common/jwt-auth.guard';
import { CurrentUserId } from '../../common/current-user.decorator';
import { SuperAdminGuard } from '../../common/superadmin.guard';
import { PrismaService } from '../../prisma/prisma.service';
import { ConfigCryptoService } from '../config-crypto/config-crypto.service';
import { SmsService } from '../sms/sms.service';
import { StaffService } from '../staff/staff.service';
import { AdminAuditInterceptor } from './admin-audit.interceptor';
import {
  AdminBusinessSmsPolicyDto,
  BusinessTypeAdminDto,
  DecideDto,
  FeatureAdminDto,
  FeatureOverrideDto,
  FreezeDto,
  InventoryAdjustmentDto,
  ReportDecisionDto,
  ReviewModerationDto,
  UpsertCoinRuleDto,
  UpsertIntegrationDto,
  UpsertLoyaltyLevelDto,
  UpsertPlanDto,
  UpsertPlanLimitDto,
  WalletAdjustmentDto,
} from './dto';

function enumOrUndefined<T extends string>(values: readonly T[], value?: string): T | undefined {
  return value && values.includes(value as T) ? (value as T) : undefined;
}

@Controller({ path: 'admin', version: '1' })
@UseGuards(JwtAuthGuard, SuperAdminGuard)
@UseInterceptors(AdminAuditInterceptor)
export class AdminController {
  constructor(
    private readonly p: PrismaService,
    private readonly crypto: ConfigCryptoService,
    private readonly sms: SmsService,
    private readonly staff: StaffService,
  ) {}

  @Get('dashboard')
  async dashboard() {
    const [users, businesses, invoices, reviews, pendingSms, pendingVerification, openReports] = await Promise.all([
      this.p.user.count(),
      this.p.business.count(),
      this.p.invoice.count(),
      this.p.review.count(),
      this.p.smsMessage.count({ where: { status: 'PENDING_APPROVAL' } }),
      this.p.verificationRequest.count({ where: { status: 'PENDING' } }),
      this.p.report.count({ where: { status: 'OPEN' } }),
    ]);
    return { users, businesses, invoices, reviews, pendingSms, pendingVerification, openReports };
  }

  @Get('integrations')
  async integrations() {
    const rows = await this.p.integrationConfig.findMany({ orderBy: [{ category: 'asc' }, { providerKey: 'asc' }] });
    return rows.map(({ encryptedConfig, ...row }) => ({ ...row, configured: Boolean(encryptedConfig), secretMask: '••••••••' }));
  }

  @Post('integrations')
  upsert(@Body() d: UpsertIntegrationDto) {
    return this.p.integrationConfig.upsert({
      where: { category_providerKey: { category: d.category, providerKey: d.providerKey } },
      update: {
        displayName: d.displayName,
        enabled: d.enabled,
        isDefault: d.isDefault ?? false,
        encryptedConfig: this.crypto.encrypt(d.secretConfig),
        publicConfig: d.publicConfig as never,
      },
      create: {
        category: d.category,
        providerKey: d.providerKey,
        displayName: d.displayName,
        enabled: d.enabled,
        isDefault: d.isDefault ?? false,
        encryptedConfig: this.crypto.encrypt(d.secretConfig),
        publicConfig: d.publicConfig as never,
      },
    });
  }

  @Get('features')
  features() {
    return this.p.feature.findMany({ include: { overrides: true }, orderBy: { key: 'asc' } });
  }

  @Patch('features/:key')
  feature(@Param('key') key: string, @Body() d: FeatureAdminDto) {
    return this.p.feature.update({ where: { key }, data: { status: d.status } });
  }

  @Post('features/:key/overrides')
  async featureOverride(@Param('key') key: string, @Body() d: FeatureOverrideDto) {
    const f = await this.p.feature.findUniqueOrThrow({ where: { key } });
    return this.p.featureOverride.upsert({
      where: { featureId_scope_scopeId: { featureId: f.id, scope: d.scope, scopeId: d.scopeId } },
      update: { status: d.status, limits: d.limits as never, reason: d.reason },
      create: { featureId: f.id, scope: d.scope, scopeId: d.scopeId, status: d.status, limits: d.limits as never, reason: d.reason },
    });
  }

  @Get('users')
  async users(@Query('cursor') cursor?: string, @Query('q') q?: string) {
    const rows = await this.p.user.findMany({
      where: q ? { OR: [{ phone: { contains: q } }, { profile: { displayName: { contains: q, mode: 'insensitive' } } }] } : {},
      take: 51,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      include: { profile: true },
      orderBy: { id: 'asc' },
    });
    const hasNextPage = rows.length > 50;
    const items = hasNextPage ? rows.slice(0, 50) : rows;
    return { items, pageInfo: { hasNextPage, nextCursor: hasNextPage ? items.at(-1)?.id ?? null : null } };
  }

  @Patch('users/:id/freeze')
  userFreeze(@Param('id') id: string, @Body() d: FreezeDto) {
    return this.p.user.update({
      where: { id },
      data: { status: d.frozen ? 'FROZEN' : 'ACTIVE', frozenAt: d.frozen ? new Date() : null, freezeReason: d.frozen ? d.reason : null },
    });
  }

  @Get('businesses')
  async businesses(@Query('cursor') cursor?: string, @Query('q') q?: string) {
    const rows = await this.p.business.findMany({
      where: q ? { name: { contains: q, mode: 'insensitive' } } : {},
      take: 51,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      include: { businessType: true, owner: { include: { profile: true } } },
      orderBy: { id: 'asc' },
    });
    const hasNextPage = rows.length > 50;
    const items = hasNextPage ? rows.slice(0, 50) : rows;
    return { items, pageInfo: { hasNextPage, nextCursor: hasNextPage ? items.at(-1)?.id ?? null : null } };
  }

  @Patch('businesses/:id/sms-policy')
  async businessSmsPolicy(@Param('id') id: string, @Body() d: AdminBusinessSmsPolicyDto) {
    return this.p.businessSmsSetting.upsert({ where: { businessId: id }, update: d, create: { businessId: id, ...d } });
  }

  @Patch('businesses/:id/freeze')
  businessFreeze(@Param('id') id: string, @Body() d: FreezeDto) {
    return this.p.business.update({
      where: { id },
      data: { frozenAt: d.frozen ? new Date() : null, freezeReason: d.frozen ? d.reason : null },
    });
  }

  @Get('business-types')
  businessTypes() {
    return this.p.businessType.findMany({ orderBy: [{ enabled: 'desc' }, { nameFa: 'asc' }] });
  }

  @Post('business-types')
  businessTypeUpsert(@Body() d: BusinessTypeAdminDto) {
    return this.p.businessType.upsert({
      where: { key: d.key },
      update: { nameFa: d.nameFa, nameEn: d.nameEn, iconKey: d.iconKey, enabled: d.enabled ?? true, schema: d.schema as never },
      create: { key: d.key, nameFa: d.nameFa, nameEn: d.nameEn, iconKey: d.iconKey, enabled: d.enabled ?? true, schema: d.schema as never },
    });
  }

  @Get('invoices')
  async invoices(@Query('cursor') cursor?: string, @Query('q') q?: string, @Query('status') rawStatus?: string, @Query('businessId') businessId?: string) {
    const status = enumOrUndefined(Object.values(InvoiceStatus), rawStatus);
    const rows = await this.p.invoice.findMany({
      where: {
        ...(businessId ? { businessId } : {}),
        ...(status ? { status } : {}),
        ...(q ? { OR: [{ invoiceNo: { contains: q, mode: 'insensitive' } }, { business: { name: { contains: q, mode: 'insensitive' } } }] } : {}),
      },
      take: 51,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      include: { business: true, customer: { include: { profile: true } }, _count: { select: { items: true, renders: true } } },
      orderBy: { id: 'asc' },
    });
    const hasNextPage = rows.length > 50;
    const items = hasNextPage ? rows.slice(0, 50) : rows;
    return { items, pageInfo: { hasNextPage, nextCursor: hasNextPage ? items.at(-1)?.id ?? null : null } };
  }

  @Patch('invoices/:id/status')
  async invoiceStatus(@CurrentUserId() actorId: string, @Param('id') id: string, @Body() body: { status?: string }) {
    const status = enumOrUndefined([InvoiceStatus.VOID, InvoiceStatus.CANCELLED], body.status);
    if (!status) {
      throw new BadRequestException({ code: 'ADMIN_INVOICE_STATUS_RESTRICTED', message: 'مدیر فقط می‌تواند صورتحساب را باطل یا لغو کند؛ وضعیت پرداخت از تراکنش معتبر محاسبه می‌شود.' });
    }
    return this.p.$transaction(async (tx) => {
      const invoice = await tx.invoice.findUniqueOrThrow({ where: { id }, include: { items: true } });
      if (invoice.paidRial > 0n) {
        throw new BadRequestException({ code: 'PAID_INVOICE_CANNOT_BE_VOIDED', message: 'صورتحساب دارای پرداخت است؛ ابتدا فرآیند بازگشت وجه/تطبیق مالی را انجام دهید.' });
      }
      if (invoice.status === 'VOID' || invoice.status === 'CANCELLED') return invoice;
      for (const line of invoice.items) {
        if (!line.inventoryItemId) continue;
        const item = await tx.inventoryItem.findUnique({ where: { id: line.inventoryItemId } });
        if (!item) continue;
        const after = item.currentQty.plus(line.quantity);
        await tx.inventoryItem.update({ where: { id: item.id }, data: { currentQty: after } });
        await tx.inventoryMovement.create({
          data: {
            businessId: invoice.businessId,
            inventoryItemId: item.id,
            type: 'RETURN_IN',
            quantity: line.quantity,
            unitCostRial: item.averageCostRial,
            referenceType: 'INVOICE_VOID',
            referenceId: invoice.id,
            reason: `برگشت موجودی بابت ${status === 'VOID' ? 'ابطال' : 'لغو'} صورتحساب ${invoice.invoiceNo}`,
            createdById: actorId,
            metadata: { before: item.currentQty.toString(), after: after.toString(), adminAction: true },
          },
        });
      }
      const updated = await tx.invoice.update({ where: { id }, data: { status } });
      await tx.notification.create({
        data: {
          userId: invoice.customerId,
          businessId: invoice.businessId,
          type: 'INVOICE_STATUS_CHANGED',
          title: 'وضعیت صورتحساب تغییر کرد',
          body: `صورتحساب ${invoice.invoiceNo} ${status === 'VOID' ? 'باطل' : 'لغو'} شد.`,
          route: `/invoices/${invoice.id}`,
          metadata: { invoiceId: invoice.id, status },
        },
      });
      return updated;
    }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
  }

  @Get('payments')
  async payments(@Query('cursor') cursor?: string, @Query('status') rawStatus?: string, @Query('purpose') rawPurpose?: string, @Query('businessId') businessId?: string) {
    const status = enumOrUndefined(Object.values(PaymentStatus), rawStatus);
    const purpose = enumOrUndefined(Object.values(PaymentPurpose), rawPurpose);
    const rows = await this.p.paymentAttempt.findMany({
      where: { ...(businessId ? { businessId } : {}), ...(status ? { status } : {}), ...(purpose ? { purpose } : {}) },
      take: 51,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      include: { business: true, invoice: { select: { invoiceNo: true } } },
      orderBy: { id: 'asc' },
    });
    const hasNextPage = rows.length > 50;
    const items = hasNextPage ? rows.slice(0, 50) : rows;
    return { items, pageInfo: { hasNextPage, nextCursor: hasNextPage ? items.at(-1)?.id ?? null : null } };
  }

  @Get('reviews')
  async reviews(@Query('cursor') cursor?: string, @Query('q') q?: string, @Query('status') rawStatus?: string, @Query('businessId') businessId?: string) {
    const status = enumOrUndefined(Object.values(ReviewStatus), rawStatus);
    const rows = await this.p.review.findMany({
      where: {
        ...(businessId ? { businessId } : {}),
        ...(status ? { status } : {}),
        ...(q ? { OR: [{ title: { contains: q, mode: 'insensitive' } }, { body: { contains: q, mode: 'insensitive' } }, { business: { name: { contains: q, mode: 'insensitive' } } }] } : {}),
      },
      take: 51,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      include: { business: true, user: { include: { profile: true } } },
      orderBy: { id: 'asc' },
    });
    const hasNextPage = rows.length > 50;
    const items = hasNextPage ? rows.slice(0, 50) : rows;
    return { items, pageInfo: { hasNextPage, nextCursor: hasNextPage ? items.at(-1)?.id ?? null : null } };
  }

  @Patch('reviews/:id/moderation')
  reviewModeration(@Param('id') id: string, @Body() d: ReviewModerationDto) {
    return this.p.$transaction(async (tx) => {
      const review = await tx.review.update({ where: { id }, data: { status: d.status } });
      const aggregate = await tx.review.aggregate({ where: { businessId: review.businessId, status: 'PUBLISHED' }, _avg: { rating: true }, _count: { rating: true } });
      await tx.business.update({ where: { id: review.businessId }, data: { averageRating: aggregate._avg.rating ?? 0, reviewsCount: aggregate._count.rating } });
      return review;
    });
  }

  @Get('inventory')
  async inventory(@Query('cursor') cursor?: string, @Query('q') q?: string, @Query('businessId') businessId?: string) {
    const rows = await this.p.inventoryItem.findMany({
      where: {
        ...(businessId ? { businessId } : {}),
        ...(q ? { OR: [{ name: { contains: q, mode: 'insensitive' } }, { sku: { contains: q, mode: 'insensitive' } }, { barcode: { contains: q } }, { business: { name: { contains: q, mode: 'insensitive' } } }] } : {}),
      },
      take: 51,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      include: { business: true, category: true },
      orderBy: { id: 'asc' },
    });
    const hasNextPage = rows.length > 50;
    const items = hasNextPage ? rows.slice(0, 50) : rows;
    return { items, pageInfo: { hasNextPage, nextCursor: hasNextPage ? items.at(-1)?.id ?? null : null } };
  }

  @Post('inventory/:id/adjust')
  async inventoryAdjust(@CurrentUserId() actorId: string, @Param('id') id: string, @Body() d: InventoryAdjustmentDto) {
    const quantity = new Prisma.Decimal(d.quantity);
    if (quantity.lte(0)) throw new BadRequestException({ code: 'INVALID_QUANTITY', message: 'مقدار باید بیشتر از صفر باشد' });
    return this.p.$transaction(async (tx) => {
      const item = await tx.inventoryItem.findUniqueOrThrow({ where: { id } });
      const next = d.direction === 'IN' ? item.currentQty.plus(quantity) : item.currentQty.minus(quantity);
      if (next.lt(0)) throw new BadRequestException({ code: 'NEGATIVE_STOCK', message: 'موجودی انبار نمی‌تواند منفی شود' });
      await tx.inventoryItem.update({ where: { id }, data: { currentQty: next } });
      return tx.inventoryMovement.create({
        data: {
          businessId: item.businessId,
          inventoryItemId: item.id,
          type: d.direction === 'IN' ? 'ADJUSTMENT_IN' : 'ADJUSTMENT_OUT',
          quantity,
          unitCostRial: item.averageCostRial,
          reason: `اصلاح مدیر: ${d.reason}`,
          createdById: actorId,
          metadata: { before: item.currentQty.toString(), after: next.toString(), adminAdjustment: true },
        },
      });
    }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
  }

  @Get('wallets')
  async wallets(@Query('cursor') cursor?: string, @Query('q') q?: string, @Query('ownerType') rawOwnerType?: string) {
    const ownerType = enumOrUndefined(Object.values(WalletOwnerType), rawOwnerType);
    const rows = await this.p.wallet.findMany({
      where: {
        ...(ownerType ? { ownerType } : {}),
        ...(q ? { OR: [{ user: { is: { phone: { contains: q } } } }, { user: { is: { profile: { displayName: { contains: q, mode: 'insensitive' } } } } }, { business: { is: { name: { contains: q, mode: 'insensitive' } } } }] } : {}),
      },
      take: 51,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      include: { user: { include: { profile: true } }, business: true },
      orderBy: { id: 'asc' },
    });
    const hasNextPage = rows.length > 50;
    const items = hasNextPage ? rows.slice(0, 50) : rows;
    return { items, pageInfo: { hasNextPage, nextCursor: hasNextPage ? items.at(-1)?.id ?? null : null } };
  }

  @Post('wallets/:id/adjust')
  async walletAdjust(@Param('id') id: string, @Body() d: WalletAdjustmentDto) {
    let amount: bigint;
    try { amount = BigInt(d.amountRial); } catch { throw new BadRequestException({ code: 'INVALID_AMOUNT', message: 'مبلغ نامعتبر است' }); }
    if (amount <= 0n) throw new BadRequestException({ code: 'INVALID_AMOUNT', message: 'مبلغ باید بیشتر از صفر باشد' });
    return this.p.$transaction(async (tx) => {
      const wallet = await tx.wallet.findUniqueOrThrow({ where: { id } });
      const next = d.direction === 'CREDIT' ? wallet.balanceRial + amount : wallet.balanceRial - amount;
      if (next < 0n) throw new BadRequestException({ code: 'NEGATIVE_WALLET', message: 'مانده کیف پول نمی‌تواند منفی شود' });
      const updated = await tx.wallet.update({ where: { id }, data: { balanceRial: next } });
      await tx.walletTransaction.create({
        data: {
          walletId: id,
          type: 'ADJUSTMENT',
          status: 'SUCCEEDED',
          amountRial: d.direction === 'CREDIT' ? amount : -amount,
          balanceAfterRial: next,
          referenceType: 'ADMIN_ADJUSTMENT',
          description: d.reason,
          metadata: { direction: d.direction },
        },
      });
      return updated;
    }, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
  }

  @Get('audit-logs')
  async auditLogs(@Query('cursor') cursor?: string, @Query('q') q?: string) {
    const rows = await this.p.auditLog.findMany({
      where: q ? { OR: [{ action: { contains: q, mode: 'insensitive' } }, { entityType: { contains: q, mode: 'insensitive' } }, { entityId: { contains: q } }] } : {},
      take: 51,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      include: { actor: { include: { profile: true } } },
      orderBy: { id: 'asc' },
    });
    const hasNextPage = rows.length > 50;
    const items = hasNextPage ? rows.slice(0, 50) : rows;
    return { items, pageInfo: { hasNextPage, nextCursor: hasNextPage ? items.at(-1)?.id ?? null : null } };
  }

  @Get('sms/pending')
  smsPending() {
    return this.p.smsMessage.findMany({ where: { status: 'PENDING_APPROVAL' }, take: 100, include: { business: true }, orderBy: { createdAt: 'asc' } });
  }

  @Post('sms/:id/decision')
  smsDecision(@CurrentUserId() u: string, @Param('id') id: string, @Body() d: DecideDto) {
    return this.sms.approve(id, u, d.approved, d.note);
  }

  @Get('staff-requests')
  staffRequests() {
    return this.p.staffAccountRequest.findMany({ where: { status: 'PENDING' }, include: { business: true }, take: 100, orderBy: { createdAt: 'asc' } });
  }

  @Post('staff-requests/:id/decision')
  staffDecision(@Param('id') id: string, @Body() d: DecideDto) {
    return this.staff.decide(id, d.approved, d.note);
  }

  @Get('verification')
  verification() {
    return this.p.verificationRequest.findMany({ where: { status: 'PENDING' }, include: { user: { include: { profile: true } }, business: true }, take: 100, orderBy: { createdAt: 'asc' } });
  }

  @Post('verification/:id/decision')
  async verify(@CurrentUserId() u: string, @Param('id') id: string, @Body() d: DecideDto) {
    const req = await this.p.verificationRequest.update({
      where: { id },
      data: { status: d.approved ? 'APPROVED' : 'REJECTED', reviewedById: u, reviewedAt: new Date(), reviewerNote: d.note },
    });
    if (d.approved && req.businessId) await this.p.business.update({ where: { id: req.businessId }, data: { isVerified: true, verifiedAt: new Date() } });
    return req;
  }

  @Get('reports')
  reports() {
    return this.p.report.findMany({ take: 100, include: { reporter: { include: { profile: true } }, business: true }, orderBy: { createdAt: 'desc' } });
  }

  @Patch('reports/:id')
  reportDecision(@Param('id') id: string, @Body() d: ReportDecisionDto) {
    return this.p.report.update({ where: { id }, data: { status: d.status, adminNote: d.adminNote, resolvedAt: d.status === 'RESOLVED' ? new Date() : undefined } });
  }

  @Get('plans')
  plans() {
    return this.p.plan.findMany({ include: { limits: { include: { feature: true } } }, orderBy: { priceRial: 'asc' } });
  }

  @Post('plans/:key/limits')
  async planLimit(@Param('key') key: string, @Body() d: UpsertPlanLimitDto) {
    const [plan, feature] = await Promise.all([
      this.p.plan.findUniqueOrThrow({ where: { key } }),
      this.p.feature.findUniqueOrThrow({ where: { key: d.featureKey } }),
    ]);
    return this.p.planLimit.upsert({
      where: { planId_featureId_limitKey: { planId: plan.id, featureId: feature.id, limitKey: d.limitKey } },
      update: { limitValue: BigInt(d.limitValue), enabled: d.enabled ?? true },
      create: { planId: plan.id, featureId: feature.id, limitKey: d.limitKey, limitValue: BigInt(d.limitValue), enabled: d.enabled ?? true },
    });
  }

  @Post('plans')
  planUpsert(@Body() d: UpsertPlanDto) {
    return this.p.plan.upsert({
      where: { key: d.key },
      update: { nameFa: d.nameFa, description: d.description, priceRial: BigInt(d.priceRial), billingDays: d.billingDays ?? 30, active: d.active ?? true },
      create: { key: d.key, nameFa: d.nameFa, description: d.description, priceRial: BigInt(d.priceRial), billingDays: d.billingDays ?? 30, active: d.active ?? true },
    });
  }

  @Get('coins/rules')
  coinRules() {
    return this.p.coinRule.findMany({ orderBy: { key: 'asc' } });
  }

  @Post('coins/rules')
  coinUpsert(@Body() d: UpsertCoinRuleDto) {
    return this.p.coinRule.upsert({
      where: { key: d.key },
      update: { nameFa: d.nameFa, sourceType: d.sourceType, amountPerRial: d.amountPerRial, fixedCoins: d.fixedCoins, minAmountRial: d.minAmountRial != null ? BigInt(d.minAmountRial) : undefined, maxCoins: d.maxCoins, claimRequired: d.claimRequired ?? true, active: d.active ?? true },
      create: { key: d.key, nameFa: d.nameFa, sourceType: d.sourceType, amountPerRial: d.amountPerRial, fixedCoins: d.fixedCoins, minAmountRial: d.minAmountRial != null ? BigInt(d.minAmountRial) : undefined, maxCoins: d.maxCoins, claimRequired: d.claimRequired ?? true, active: d.active ?? true },
    });
  }

  @Get('loyalty-levels')
  levels() {
    return this.p.loyaltyLevel.findMany({ orderBy: { sortOrder: 'asc' } });
  }

  @Post('loyalty-levels')
  levelUpsert(@Body() d: UpsertLoyaltyLevelDto) {
    return this.p.loyaltyLevel.upsert({
      where: { key: d.key },
      update: { nameFa: d.nameFa, minLifetimeCoins: d.minLifetimeCoins, autoClaimEnabled: d.autoClaimEnabled ?? false, discountBasisPoints: d.discountBasisPoints ?? 0, sortOrder: d.sortOrder ?? 0 },
      create: { key: d.key, nameFa: d.nameFa, minLifetimeCoins: d.minLifetimeCoins, autoClaimEnabled: d.autoClaimEnabled ?? false, discountBasisPoints: d.discountBasisPoints ?? 0, sortOrder: d.sortOrder ?? 0 },
    });
  }
}
