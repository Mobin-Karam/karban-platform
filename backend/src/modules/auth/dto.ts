import { IsIn, IsOptional, IsString, Length } from 'class-validator';
export class RequestOtpDto {
  @IsString() phone!: string;
  @IsOptional() @IsIn(['sms','call']) channel: 'sms' | 'call' = 'sms';
  @IsOptional() @IsString() purpose = 'login';
}
export class VerifyOtpDto {
  @IsString() phone!: string;
  @IsString() @Length(4, 8) code!: string;
  @IsOptional() @IsString() purpose = 'login';
}
