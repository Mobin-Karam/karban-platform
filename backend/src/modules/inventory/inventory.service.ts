import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { safeLimit } from '../../common/pagination';
import { CreateInventoryCategoryDto, CreateInventoryItemDto, StockMovementDto } from './dto';
import { EntitlementsService } from '../entitlements/entitlements.service';

const incoming = new Set(['OPENING', 'PURCHASE', 'RETURN_IN', 'ADJUSTMENT_IN', 'TRANSFER_IN']);

@Injectable()
export class InventoryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly entitlements: EntitlementsService,
  ) {}

  createCategory(businessId: string, d: CreateInventoryCategoryDto) {
    return this.prisma.inventoryCategory.create({ data: { businessId, ...d } });
  }

  async createItem(businessId: string, d: CreateInventoryItemDto) {
    const count = await this.prisma.inventoryItem.count({ where: { businessId, active: true } });
    await this.entitlements.assertCount(businessId, 'inventory', 'inventory_items', count);
    return this.prisma.inventoryItem.create({
      data: {
        businessId,
        name: d.name,
        categoryId: d.categoryId,
        sku: d.sku,
        barcode: d.barcode,
        description: d.description,
        unit: d.unit ?? 'عدد',
        minQty: d.minQty != null ? new Prisma.Decimal(d.minQty) : undefined,
        reorderQty: d.reorderQty != null ? new Prisma.Decimal(d.reorderQty) : undefined,
        averageCostRial: BigInt(d.averageCostRial ?? 0),
        salePriceRial: d.salePriceRial != null ? BigInt(d.salePriceRial) : undefined,
        taxRateBasisPoints: d.taxRateBasisPoints ?? 0,
        taxProductServiceId: d.taxProductServiceId,
        supplierName: d.supplierName,
        locationLabel: d.locationLabel,
        trackSerial: d.trackSerial ?? false,
        trackBatch: d.trackBatch ?? false,
      },
    });
  }

  async movement(businessId: string, userId: string, d: StockMovementDto) {
    return this.prisma.$transaction(async (tx) => {
      const item = await tx.inventoryItem.findFirst({ where: { id: d.inventoryItemId, businessId } });
      if (!item) {
        throw new BadRequestException({ code: 'INVENTORY_ITEM_NOT_FOUND', message: 'قلم انبار پیدا نشد' });
      }

      const quantity = new Prisma.Decimal(d.quantity);
      if (quantity.lte(0)) {
        throw new BadRequestException({ code: 'INVALID_QUANTITY', message: 'مقدار گردش انبار باید بیشتر از صفر باشد' });
      }
      const isIncoming = incoming.has(d.type);
      const signed = isIncoming ? quantity : quantity.negated();
      const current = new Prisma.Decimal(item.currentQty);
      const next = current.plus(signed);
      if (next.lessThan(0)) {
        throw new BadRequestException({ code: 'NEGATIVE_STOCK', message: 'موجودی انبار نمی‌تواند منفی شود' });
      }

      let nextAverageCost = item.averageCostRial;
      if (isIncoming && d.unitCostRial != null && next.gt(0)) {
        const incomingCost = new Prisma.Decimal(String(d.unitCostRial));
        const existingValue = current.mul(item.averageCostRial.toString());
        const incomingValue = quantity.mul(incomingCost);
        const weightedAverage = existingValue.plus(incomingValue).div(next).toDecimalPlaces(0, Prisma.Decimal.ROUND_HALF_UP);
        nextAverageCost = BigInt(weightedAverage.toString());
      }

      const movement = await tx.inventoryMovement.create({
        data: {
          businessId,
          inventoryItemId: item.id,
          type: d.type,
          quantity,
          unitCostRial: d.unitCostRial != null ? BigInt(d.unitCostRial) : item.averageCostRial,
          reason: d.reason,
          batchNo: d.batchNo,
          serialNo: d.serialNo,
          createdById: userId,
          metadata: { before: current.toString(), after: next.toString() },
        },
      });

      await tx.inventoryItem.update({
        where: { id: item.id },
        data: { currentQty: next, averageCostRial: nextAverageCost },
      });
      return movement;
    });
  }

  async list(businessId: string, cursor?: string, limit?: number, q?: string) {
    const take = safeLimit(limit, 30, 100);
    const rows = await this.prisma.inventoryItem.findMany({
      where: {
        businessId,
        ...(q ? { OR: [{ name: { contains: q, mode: 'insensitive' } }, { sku: { contains: q, mode: 'insensitive' } }] } : {}),
      },
      take: take + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      include: { category: true },
      orderBy: { id: 'asc' },
    });
    const hasNextPage = rows.length > take;
    const items = rows.slice(0, take);
    return { items, pageInfo: { hasNextPage, nextCursor: hasNextPage ? items.at(-1)?.id ?? null : null } };
  }

  async lowStock(businessId: string) {
    const rows = await this.prisma.inventoryItem.findMany({
      where: { businessId, active: true, minQty: { not: null } },
      take: 500,
      orderBy: { name: 'asc' },
    });
    return rows.filter((i) => i.minQty != null && new Prisma.Decimal(i.currentQty).lte(i.minQty));
  }
}
