import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';
const bool=({value}:{value:unknown})=>value===true||value==='true'?true:value===false||value==='false'?false:value;
export class CreateBusinessDto {
  @IsString() name!: string; @IsString() slug!: string;
  @IsOptional() @IsString() username?: string; @IsOptional() @IsString() bio?: string;
  @IsOptional() @IsString() phone?: string; @IsOptional() @IsString() city?: string;
  @IsOptional() @IsString() province?: string; @IsOptional() @IsString() address?: string;
  @IsOptional() @IsNumber() latitude?: number; @IsOptional() @IsNumber() longitude?: number;
}
export class UpdateBusinessDto {
  @IsOptional() @IsString() name?: string; @IsOptional() @IsString() bio?: string;
  @IsOptional() @IsString() address?: string; @IsOptional() @IsString() city?: string;
  @IsOptional() @IsString() province?: string; @IsOptional() @IsNumber() latitude?: number;
  @IsOptional() @IsNumber() longitude?: number; @IsOptional() @IsBoolean() isAvailable?: boolean;
  @IsOptional() @IsBoolean() isPublic?: boolean; @IsOptional() @IsString() logoUrl?: string;
  @IsOptional() @IsString() coverUrl?: string; @IsOptional() @IsString() signatureUrl?: string;
  @IsOptional() @IsString() stampUrl?: string; @IsOptional() @IsString() paymentInstructions?: string;
}
export class BusinessSearchDto {
  @IsOptional() @IsString() q?: string; @IsOptional() @IsString() city?: string; @IsOptional() @IsString() province?: string;
  @IsOptional() @Type(()=>Number) @IsNumber() latitude?: number; @IsOptional() @Type(()=>Number) @IsNumber() longitude?: number;
  @IsOptional() @Type(()=>Number) @IsNumber() @Min(1) @Max(100) limit?: number; @IsOptional() @IsString() cursor?: string;
  @IsOptional() @Transform(bool) @IsBoolean() availableOnly?: boolean; @IsOptional() @Transform(bool) @IsBoolean() verifiedOnly?: boolean;
}
export class VerificationRequestDto {
  @IsOptional() @IsString() legalName?: string; @IsOptional() @IsString() nationalId?: string;
  @IsOptional() @IsString() nationalCardFrontUrl?: string; @IsOptional() @IsString() nationalCardBackUrl?: string;
  @IsOptional() @IsString() licenseUrl?: string; @IsOptional() @IsString() selfieUrl?: string; @IsOptional() @IsString() notes?: string;
}
