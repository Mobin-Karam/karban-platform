import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from "@nestjs/common";
import { JwtAuthGuard } from "../../common/jwt-auth.guard";
import { CurrentUserId } from "../../common/current-user.decorator";
import { BusinessAccessService } from "./business-access.service";
import { BusinessesService } from "./businesses.service";
import {
  BusinessSearchDto,
  CreateBusinessDto,
  UpdateBusinessDto,
  VerificationRequestDto,
} from "./dto";
import { PrismaService } from "../../prisma/prisma.service";
import { FeatureGateGuard, RequireFeature } from "../../common/feature-gate";
@Controller({ path: "businesses", version: "1" })
export class BusinessesController {
  constructor(
    private readonly service: BusinessesService,
    private readonly access: BusinessAccessService,
    private readonly prisma: PrismaService,
  ) {}
  @RequireFeature("business_discovery")
  @UseGuards(FeatureGateGuard)
  @Get("discover")
  discover(@Query() query: BusinessSearchDto) {
    return this.service.search(query);
  }
  @RequireFeature("business_discovery")
  @UseGuards(FeatureGateGuard)
  @Get("public/:slug")
  detail(@Param("slug") slug: string) {
    return this.service.publicDetail(slug);
  }
  @UseGuards(JwtAuthGuard) @Get("mine") mine(@CurrentUserId() userId: string) {
    return this.service.mine(userId);
  }
  @UseGuards(JwtAuthGuard) @Post() create(
    @CurrentUserId() userId: string,
    @Body() dto: CreateBusinessDto,
  ) {
    return this.service.create(userId, dto);
  }
  @UseGuards(JwtAuthGuard) @Post(":id/verification") async verification(
    @CurrentUserId() userId: string,
    @Param("id") id: string,
    @Body() dto: VerificationRequestDto,
  ) {
    await this.access.require(id, userId, ["OWNER"]);
    return this.prisma.verificationRequest.create({
      data: { userId, businessId: id, ...dto },
    });
  }
  @UseGuards(JwtAuthGuard) @Patch(":id") async update(
    @CurrentUserId() userId: string,
    @Param("id") id: string,
    @Body() dto: UpdateBusinessDto,
  ) {
    await this.access.require(id, userId, ["OWNER", "MANAGER"]);
    return this.service.update(id, dto);
  }
}
