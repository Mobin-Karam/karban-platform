import { IsBoolean, IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';
export class CreateServiceCategoryDto { @IsString() name!: string; @IsOptional() @IsString() description?: string; @IsOptional() @IsInt() sortOrder?: number; }
export class CreateServiceDto {
  @IsString() name!: string; @IsOptional() @IsString() description?: string; @IsOptional() @IsString() categoryId?: string;
  @IsNumber() @Min(0) priceRial!: number; @IsOptional() @IsString() unitLabel?: string; @IsOptional() @IsInt() taxRateBasisPoints?: number;
  @IsOptional() @IsString() taxProductServiceId?: string; @IsOptional() @IsInt() durationMinutes?: number; @IsOptional() @IsBoolean() active?: boolean;
}
export class UpdateServiceDto extends CreateServiceDto {}
