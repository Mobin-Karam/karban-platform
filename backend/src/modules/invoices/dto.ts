import { IsArray, IsIn, IsInt, IsNumber, IsOptional, IsString, Min, ValidateNested } from 'class-validator'; import { Type } from 'class-transformer';
export class InvoiceLineDto {
 @IsIn(['SERVICE','INVENTORY','CUSTOM']) type!: 'SERVICE'|'INVENTORY'|'CUSTOM'; @IsOptional() @IsString() serviceId?:string; @IsOptional() @IsString() inventoryItemId?:string;
 @IsOptional() @IsString() title?:string; @IsOptional() @IsString() description?:string; @IsNumber() @Min(0.001) quantity!:number; @IsOptional() @IsString() unitLabel?:string;
 @IsOptional() @IsNumber() @Min(0) unitPriceRial?:number; @IsOptional() @IsNumber() @Min(0) discountRial?:number; @IsOptional() @IsInt() taxRateBasisPoints?:number; @IsOptional() @IsString() taxProductServiceId?:string;
}
export class CreateInvoiceDto {
 @IsString() customerPhone!:string; @IsArray() @ValidateNested({each:true}) @Type(()=>InvoiceLineDto) items!:InvoiceLineDto[]; @IsOptional() @IsNumber() @Min(0) invoiceDiscountRial?:number;
 @IsOptional() @IsNumber() @Min(0) shippingRial?:number; @IsOptional() @IsString() notes?:string; @IsOptional() @IsString() dueAt?:string;
}
