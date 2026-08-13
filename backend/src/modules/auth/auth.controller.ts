import { Body, Controller, Post } from "@nestjs/common";
import { Throttle } from "@nestjs/throttler";
import { AuthService } from "./auth.service";
import { RequestOtpDto, VerifyOtpDto } from "./dto";
@Controller({ path: "auth", version: "1" })
export class AuthController {
  constructor(private readonly auth: AuthService) {}
  @Post("otp/request")
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  request(@Body() dto: RequestOtpDto): Promise<{ expiresInSeconds: number }> {
    return this.auth.requestOtp(dto.phone, dto.purpose, dto.channel);
  }
  @Post("otp/verify")
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  verify(@Body() dto: VerifyOtpDto) {
    return this.auth.verifyOtp(dto.phone, dto.purpose, dto.code);
  }
}
