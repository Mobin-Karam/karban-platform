import{IsBoolean,IsIn,IsOptional,IsString,MaxLength}from'class-validator';
export class SendBusinessSmsDto{@IsString()phone!:string;@IsIn(['INVOICE','INVITE','TRANSACTIONAL','CAMPAIGN'])kind!:'INVOICE'|'INVITE'|'TRANSACTIONAL'|'CAMPAIGN';@IsOptional()@IsString()templateKey?:string;@IsOptional()@IsString()@MaxLength(1000)body?:string}
/** Owner-controllable preferences. Platform approval policy is intentionally absent. */
export class SmsSettingDto{@IsOptional()@IsBoolean()ownerEnabled?:boolean;@IsOptional()@IsBoolean()invoiceSmsEnabled?:boolean;@IsOptional()@IsBoolean()inviteSmsEnabled?:boolean;@IsOptional()@IsBoolean()campaignSmsEnabled?:boolean;}
export class AdminSmsPolicyDto{@IsOptional()@IsBoolean()enabled?:boolean;@IsOptional()@IsIn(['AUTO','REVIEW','DISABLED'])approvalMode?:'AUTO'|'REVIEW'|'DISABLED';@IsOptional()@IsString()providerKey?:string;@IsOptional() maxDailyMessages?:number;@IsOptional()@IsBoolean()ownerTemplateEditing?:boolean;}
