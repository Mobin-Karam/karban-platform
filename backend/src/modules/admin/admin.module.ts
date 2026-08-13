import { Module } from '@nestjs/common';
import { SmsModule } from '../sms/sms.module';
import { StaffModule } from '../staff/staff.module';
import { AdminController } from './admin.controller';
import { SuperAdminGuard } from '../../common/superadmin.guard';
import { AdminAuditInterceptor } from './admin-audit.interceptor';

@Module({
  imports: [SmsModule, StaffModule],
  controllers: [AdminController],
  providers: [SuperAdminGuard, AdminAuditInterceptor],
})
export class AdminModule {}
