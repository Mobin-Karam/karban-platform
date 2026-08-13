import { IsBoolean, IsIn, IsInt, IsObject, IsOptional, IsString, Min } from 'class-validator';
export class CreatePaymentDto {
  @IsIn(['WALLET_CHARGE', 'INVOICE', 'PAYMENT_PLAN']) purpose!: 'WALLET_CHARGE' | 'INVOICE' | 'PAYMENT_PLAN';
  @IsInt() @Min(10000) amountRial!: number;
  @IsOptional() @IsString() invoiceId?: string;
  @IsOptional() @IsString() businessId?: string;
  @IsOptional() @IsString() description?: string;
}
export class CreateBusinessPaymentMethodDto {
  @IsIn(['CARD', 'IBAN', 'ZARINPAL', 'WALLET', 'OTHER']) type!: 'CARD' | 'IBAN' | 'ZARINPAL' | 'WALLET' | 'OTHER';
  @IsString() label!: string;
  @IsOptional() @IsObject() publicDetails?: Record<string, unknown>;
  @IsOptional() @IsObject() secretConfig?: Record<string, unknown>;
  @IsOptional() @IsBoolean() isDefault?: boolean;
}
