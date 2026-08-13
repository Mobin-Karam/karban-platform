import {
  IsBoolean,
  IsIn,
  IsInt,
  IsNumber,
  IsNumberString,
  IsObject,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class UpsertIntegrationDto {
  @IsIn(['OTP', 'SMS', 'PAYMENT', 'MAP', 'STORAGE', 'TAX', 'OTHER'])
  category!: 'OTP' | 'SMS' | 'PAYMENT' | 'MAP' | 'STORAGE' | 'TAX' | 'OTHER';
  @IsString() providerKey!: string;
  @IsString() displayName!: string;
  @IsBoolean() enabled!: boolean;
  @IsOptional() @IsBoolean() isDefault?: boolean;
  @IsObject() secretConfig!: Record<string, unknown>;
  @IsOptional() @IsObject() publicConfig?: Record<string, unknown>;
}

export class FreezeDto {
  @IsBoolean() frozen!: boolean;
  @IsOptional() @IsString() reason?: string;
}

export class FeatureAdminDto {
  @IsIn(['ENABLED', 'DISABLED', 'COMING_SOON', 'MAINTENANCE'])
  status!: 'ENABLED' | 'DISABLED' | 'COMING_SOON' | 'MAINTENANCE';
}

export class DecideDto {
  @IsBoolean() approved!: boolean;
  @IsOptional() @IsString() note?: string;
}

export class UpsertPlanDto {
  @IsString() key!: string;
  @IsString() nameFa!: string;
  @IsOptional() @IsString() description?: string;
  @IsInt() @Min(0) priceRial!: number;
  @IsOptional() @IsInt() @Min(1) billingDays?: number;
  @IsOptional() @IsBoolean() active?: boolean;
}

export class UpsertCoinRuleDto {
  @IsString() key!: string;
  @IsString() nameFa!: string;
  @IsString() sourceType!: string;
  @IsOptional() @IsNumber() amountPerRial?: number;
  @IsOptional() @IsInt() fixedCoins?: number;
  @IsOptional() @IsInt() minAmountRial?: number;
  @IsOptional() @IsInt() maxCoins?: number;
  @IsOptional() @IsBoolean() claimRequired?: boolean;
  @IsOptional() @IsBoolean() active?: boolean;
}

export class UpsertLoyaltyLevelDto {
  @IsString() key!: string;
  @IsString() nameFa!: string;
  @IsInt() @Min(0) minLifetimeCoins!: number;
  @IsOptional() @IsBoolean() autoClaimEnabled?: boolean;
  @IsOptional() @IsInt() discountBasisPoints?: number;
  @IsOptional() @IsInt() sortOrder?: number;
}

export class FeatureOverrideDto {
  @IsIn(['USER', 'BUSINESS', 'BUSINESS_TYPE', 'PLAN']) scope!: 'USER' | 'BUSINESS' | 'BUSINESS_TYPE' | 'PLAN';
  @IsString() scopeId!: string;
  @IsIn(['ENABLED', 'DISABLED', 'COMING_SOON', 'MAINTENANCE']) status!: 'ENABLED' | 'DISABLED' | 'COMING_SOON' | 'MAINTENANCE';
  @IsOptional() @IsObject() limits?: Record<string, unknown>;
  @IsOptional() @IsString() reason?: string;
}

export class ReportDecisionDto {
  @IsIn(['OPEN', 'IN_REVIEW', 'RESOLVED', 'REJECTED']) status!: 'OPEN' | 'IN_REVIEW' | 'RESOLVED' | 'REJECTED';
  @IsOptional() @IsString() adminNote?: string;
}

export class AdminBusinessSmsPolicyDto {
  @IsOptional() @IsBoolean() enabled?: boolean;
  @IsOptional() @IsIn(['AUTO', 'REVIEW', 'DISABLED']) approvalMode?: 'AUTO' | 'REVIEW' | 'DISABLED';
  @IsOptional() @IsString() providerKey?: string;
  @IsOptional() @IsInt() @Min(1) maxDailyMessages?: number;
  @IsOptional() @IsBoolean() ownerTemplateEditing?: boolean;
}

export class UpsertPlanLimitDto {
  @IsString() featureKey!: string;
  @IsString() limitKey!: string;
  @IsInt() @Min(0) limitValue!: number;
  @IsOptional() @IsBoolean() enabled?: boolean;
}

export class ReviewModerationDto {
  @IsIn(['PUBLISHED', 'HIDDEN', 'REJECTED']) status!: 'PUBLISHED' | 'HIDDEN' | 'REJECTED';
}

export class WalletAdjustmentDto {
  @IsIn(['CREDIT', 'DEBIT']) direction!: 'CREDIT' | 'DEBIT';
  @IsNumberString() amountRial!: string;
  @IsString() reason!: string;
}

export class InventoryAdjustmentDto {
  @IsIn(['IN', 'OUT']) direction!: 'IN' | 'OUT';
  @IsNumberString() quantity!: string;
  @IsString() reason!: string;
}

export class BusinessTypeAdminDto {
  @IsString() key!: string;
  @IsString() nameFa!: string;
  @IsOptional() @IsString() nameEn?: string;
  @IsString() iconKey!: string;
  @IsOptional() @IsBoolean() enabled?: boolean;
  @IsOptional() @IsObject() schema?: Record<string, unknown>;
}
