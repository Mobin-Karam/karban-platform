import{IsOptional,IsString}from'class-validator';export class RegenRequestDto{@IsString()invoiceId!:string;@IsOptional()@IsString()message?:string}
