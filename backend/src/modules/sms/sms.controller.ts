import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from "@nestjs/common";
import { JwtAuthGuard } from "../../common/jwt-auth.guard";
import { CurrentUserId } from "../../common/current-user.decorator";
import { BusinessAccessService } from "../businesses/business-access.service";
import { SendBusinessSmsDto, SmsSettingDto } from "./dto";
import { SmsService } from "./sms.service";
import { FeatureGateGuard, RequireFeature } from "../../common/feature-gate";
@Controller({ path: "businesses/:businessId/sms", version: "1" })
@RequireFeature("sms", "businessId")
@UseGuards(JwtAuthGuard, FeatureGateGuard)
export class SmsController {
  constructor(
    private readonly s: SmsService,
    private readonly a: BusinessAccessService,
  ) {}
  @Get("settings") async settings(
    @CurrentUserId() u: string,
    @Param("businessId") b: string,
  ) {
    await this.a.require(b, u, ["OWNER", "MANAGER"]);
    return this.s.settings(b);
  }
  @Patch("settings") async update(
    @CurrentUserId() u: string,
    @Param("businessId") b: string,
    @Body() d: SmsSettingDto,
  ) {
    await this.a.require(b, u, ["OWNER"]);
    return this.s.updateSettings(b, { ...d });
  }
  @Post("send") async send(
    @CurrentUserId() u: string,
    @Param("businessId") b: string,
    @Body() d: SendBusinessSmsDto,
  ) {
    await this.a.require(b, u, ["OWNER", "MANAGER"]);
    return this.s.request(b, u, d);
  }
}
