import { IsBoolean, IsIn, IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';
export class CreateInventoryCategoryDto { @IsString() name!:string; @IsOptional() @IsString() description?:string; }
export class CreateInventoryItemDto {
 @IsString() name!:string; @IsOptional() @IsString() categoryId?:string; @IsOptional() @IsString() sku?:string; @IsOptional() @IsString() barcode?:string;
 @IsOptional() @IsString() description?:string; @IsOptional() @IsString() unit?:string; @IsOptional() @IsNumber() @Min(0) minQty?:number; @IsOptional() @IsNumber() @Min(0) reorderQty?:number;
 @IsOptional() @IsNumber() @Min(0) averageCostRial?:number; @IsOptional() @IsNumber() @Min(0) salePriceRial?:number; @IsOptional() @IsInt() taxRateBasisPoints?:number;
 @IsOptional() @IsString() taxProductServiceId?:string; @IsOptional() @IsString() supplierName?:string; @IsOptional() @IsString() locationLabel?:string;
 @IsOptional() @IsBoolean() trackSerial?:boolean; @IsOptional() @IsBoolean() trackBatch?:boolean;
}
export class StockMovementDto {
 @IsString() inventoryItemId!:string;
 @IsIn(['OPENING','PURCHASE','CONSUMPTION','SALE','RETURN_IN','RETURN_OUT','ADJUSTMENT_IN','ADJUSTMENT_OUT','TRANSFER_IN','TRANSFER_OUT']) type!: 'OPENING'|'PURCHASE'|'CONSUMPTION'|'SALE'|'RETURN_IN'|'RETURN_OUT'|'ADJUSTMENT_IN'|'ADJUSTMENT_OUT'|'TRANSFER_IN'|'TRANSFER_OUT';
 @IsNumber() @Min(0.001) quantity!:number; @IsOptional() @IsNumber() @Min(0) unitCostRial?:number; @IsOptional() @IsString() reason?:string; @IsOptional() @IsString() batchNo?:string; @IsOptional() @IsString() serialNo?:string;
}
