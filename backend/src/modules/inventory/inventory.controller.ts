import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from "@nestjs/common";
import { JwtAuthGuard } from "../../common/jwt-auth.guard";
import { CurrentUserId } from "../../common/current-user.decorator";
import { BusinessAccessService } from "../businesses/business-access.service";
import { InventoryService } from "./inventory.service";
import {
  CreateInventoryCategoryDto,
  CreateInventoryItemDto,
  StockMovementDto,
} from "./dto";
import { FeatureGateGuard, RequireFeature } from "../../common/feature-gate";
@Controller({ path: "businesses/:businessId/inventory", version: "1" })
@RequireFeature("inventory", "businessId")
@UseGuards(JwtAuthGuard, FeatureGateGuard)
export class InventoryController {
  constructor(
    private readonly s: InventoryService,
    private readonly a: BusinessAccessService,
  ) {}
  @Get() async list(
    @CurrentUserId() u: string,
    @Param("businessId") b: string,
    @Query("cursor") c?: string,
    @Query("limit") l?: string,
    @Query("q") q?: string,
  ) {
    await this.a.require(b, u);
    return this.s.list(b, c, l ? Number(l) : undefined, q);
  }
  @Get("low-stock") async low(
    @CurrentUserId() u: string,
    @Param("businessId") b: string,
  ) {
    await this.a.require(b, u);
    return this.s.lowStock(b);
  }
  @Post("categories") async cat(
    @CurrentUserId() u: string,
    @Param("businessId") b: string,
    @Body() d: CreateInventoryCategoryDto,
  ) {
    await this.a.require(b, u, ["OWNER", "MANAGER"]);
    return this.s.createCategory(b, d);
  }
  @Post("items") async item(
    @CurrentUserId() u: string,
    @Param("businessId") b: string,
    @Body() d: CreateInventoryItemDto,
  ) {
    await this.a.require(b, u, ["OWNER", "MANAGER"]);
    return this.s.createItem(b, d);
  }
  @Post("movements") async move(
    @CurrentUserId() u: string,
    @Param("businessId") b: string,
    @Body() d: StockMovementDto,
  ) {
    await this.a.require(b, u, ["OWNER", "MANAGER", "STAFF"]);
    return this.s.movement(b, u, d);
  }
}
