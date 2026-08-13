import {
  BadRequestException,
  HttpException,
  HttpStatus,
  Injectable,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { createHash, randomInt } from "node:crypto";
import { PrismaService } from "../../prisma/prisma.service";
import { normalizeIranPhone } from "../../common/phone";
import { ApiIrOtpProvider } from "./apiir-otp.provider";

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly apiir: ApiIrOtpProvider,
  ) {}
  private hash(phone: string, purpose: string, code: string): string {
    return createHash("sha256")
      .update(`${phone}:${purpose}:${code}:${process.env.JWT_SECRET}`)
      .digest("hex");
  }
  async requestOtp(
    inputPhone: string,
    purpose: string,
    channel: "sms" | "call",
  ): Promise<{ expiresInSeconds: number }> {
    let phone: string;
    try {
      phone = normalizeIranPhone(inputPhone);
    } catch {
      throw new BadRequestException({
        code: "INVALID_PHONE",
        message: "شماره موبایل معتبر نیست",
      });
    }
    const oneMinuteAgo = new Date(Date.now() - 60_000);
    const recent = await this.prisma.otpChallenge.count({
      where: { phone, purpose, createdAt: { gte: oneMinuteAgo } },
    });
    if (recent >= 3)
      throw new HttpException(
        { code: "OTP_RATE_LIMIT", message: "درخواست‌های زیادی ثبت شده است" },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    const code = String(randomInt(10000, 100000));
    const providerRef = await this.apiir.send(phone, code, channel);
    await this.prisma.otpChallenge.create({
      data: {
        phone,
        purpose,
        providerKey: "apiir",
        providerRef,
        codeHash: this.hash(phone, purpose, code),
        expiresAt: new Date(Date.now() + 2 * 60_000),
      },
    });
    return { expiresInSeconds: 120 };
  }
  async verifyOtp(
    inputPhone: string,
    purpose: string,
    code: string,
  ): Promise<{
    accessToken: string;
    user: { id: string; phone: string; accountType: string };
  }> {
    let phone: string;
    try {
      phone = normalizeIranPhone(inputPhone);
    } catch {
      throw new BadRequestException({
        code: "INVALID_PHONE",
        message: "شماره موبایل معتبر نیست",
      });
    }
    const challenge = await this.prisma.otpChallenge.findFirst({
      where: { phone, purpose, consumedAt: null },
      orderBy: { createdAt: "desc" },
    });
    if (!challenge || challenge.expiresAt < new Date())
      throw new BadRequestException({
        code: "OTP_EXPIRED",
        message: "کد منقضی شده است",
      });
    if (challenge.attempts >= 5)
      throw new BadRequestException({
        code: "OTP_LOCKED",
        message: "تعداد تلاش بیش از حد مجاز است",
      });
    if (challenge.codeHash !== this.hash(phone, purpose, code)) {
      await this.prisma.otpChallenge.update({
        where: { id: challenge.id },
        data: { attempts: { increment: 1 } },
      });
      throw new BadRequestException({
        code: "OTP_INVALID",
        message: "کد واردشده صحیح نیست",
      });
    }
    const user = await this.prisma.$transaction(async (tx) => {
      await tx.otpChallenge.update({
        where: { id: challenge.id },
        data: { consumedAt: new Date() },
      });
      const found = await tx.user.upsert({
        where: { phone },
        update: { phoneVerifiedAt: new Date() },
        create: { phone, phoneVerifiedAt: new Date() },
      });
      await tx.wallet.upsert({
        where: { userId: found.id },
        update: {},
        create: { ownerType: "USER", userId: found.id },
      });
      await tx.coinWallet.upsert({
        where: { userId: found.id },
        update: {},
        create: { userId: found.id, levelKey: "starter" },
      });
      return found;
    });
    if (user.status !== "ACTIVE")
      throw new BadRequestException({
        code: "ACCOUNT_FROZEN",
        message: "حساب کاربری فعال نیست",
      });
    const accessToken = await this.jwt.signAsync({
      sub: user.id,
      phone: user.phone,
      accountType: user.accountType,
    });
    return {
      accessToken,
      user: { id: user.id, phone: user.phone, accountType: user.accountType },
    };
  }
}
