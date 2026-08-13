import { Controller, Get, Param, Post, Body, UseGuards } from "@nestjs/common";
import { JwtAuthGuard } from "../../common/jwt-auth.guard";
import { CurrentUserId } from "../../common/current-user.decorator";
import { BusinessAccessService } from "../businesses/business-access.service";
import { ClaimCoinDto } from "./dto";
import { WalletsService } from "./wallets.service";
import { FeatureGateGuard, RequireFeature } from "../../common/feature-gate";
@Controller({ path: "wallets", version: "1" })
@RequireFeature("wallet")
@UseGuards(JwtAuthGuard, FeatureGateGuard)
export class WalletsController {
  constructor(
    private readonly s: WalletsService,
    private readonly a: BusinessAccessService,
  ) {}
  @Get("mine") mine(@CurrentUserId() u: string) {
    return this.s.userWallet(u);
  }
  @Get("mine/coins") coins(@CurrentUserId() u: string) {
    return this.s.coins({ userId: u });
  }
  @Post("mine/coins/claim") claim(
    @CurrentUserId() u: string,
    @Body() d: ClaimCoinDto,
  ) {
    return this.s.claim(u, d.grantId);
  }
  @RequireFeature("wallet", "businessId")
  @Get("business/:businessId")
  async biz(@CurrentUserId() u: string, @Param("businessId") b: string) {
    await this.a.require(b, u);
    return this.s.businessWallet(b);
  }
  @RequireFeature("coins", "businessId")
  @Post("business/:businessId/coins/claim")
  async bclaim(
    @CurrentUserId() u: string,
    @Param("businessId") b: string,
    @Body() d: ClaimCoinDto,
  ) {
    await this.a.require(b, u, ["OWNER", "MANAGER"]);
    return this.s.claimBusiness(b, d.grantId);
  }
  @RequireFeature("coins", "businessId")
  @Get("business/:businessId/coins")
  async bcoins(@CurrentUserId() u: string, @Param("businessId") b: string) {
    await this.a.require(b, u);
    return this.s.coins({ businessId: b });
  }
}
