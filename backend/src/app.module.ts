import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerModule } from '@nestjs/throttler';
import { JwtModule } from '@nestjs/jwt';
import { PrismaModule } from './prisma/prisma.module';
import { HealthModule } from './modules/health/health.module';
import { AuthModule } from './modules/auth/auth.module';
import { BusinessesModule } from './modules/businesses/businesses.module';
import { CatalogModule } from './modules/catalog/catalog.module';
import { InventoryModule } from './modules/inventory/inventory.module';
import { InvoicesModule } from './modules/invoices/invoices.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { WalletsModule } from './modules/wallets/wallets.module';
import { SmsModule } from './modules/sms/sms.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { AdminModule } from './modules/admin/admin.module';
import { StaffModule } from './modules/staff/staff.module';
import { ReportsModule } from './modules/reports/reports.module';
import { MessagingModule } from './modules/messaging/messaging.module';
import { ConfigCryptoModule } from './modules/config-crypto/config-crypto.module';
import { FeaturesModule } from './modules/features/features.module';
import { MediaModule } from './modules/media/media.module';
import { EntitlementsModule } from './modules/entitlements/entitlements.module';
import { NotificationsModule } from './modules/notifications/notifications.module';

function validateEnv(env: Record<string, string | undefined>): Record<string, string | undefined> {
  const required = ['DATABASE_URL', 'JWT_SECRET', 'CONFIG_ENCRYPTION_KEY'];
  const missing = required.filter((key) => !env[key]);
  if (missing.length) throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  if (!/^[0-9a-fA-F]{64}$/.test(env.CONFIG_ENCRYPTION_KEY ?? '')) throw new Error('CONFIG_ENCRYPTION_KEY must be exactly 64 hexadecimal characters');
  if ((env.JWT_SECRET ?? '').length < 32) throw new Error('JWT_SECRET must be at least 32 characters');
  if (!(env.DATABASE_URL ?? '').startsWith('postgresql://') && !(env.DATABASE_URL ?? '').startsWith('postgres://')) throw new Error('DATABASE_URL must be a PostgreSQL URL');
  return env;
}

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.getOrThrow<string>('JWT_SECRET'),
        signOptions: { expiresIn: '15m' },
      }),
    }),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 120 }]),
    ScheduleModule.forRoot(),
    PrismaModule,
    ConfigCryptoModule,
    MediaModule,
    EntitlementsModule,
    NotificationsModule,
    HealthModule,
    AuthModule,
    BusinessesModule,
    CatalogModule,
    InventoryModule,
    InvoicesModule,
    ReviewsModule,
    WalletsModule,
    SmsModule,
    PaymentsModule,
    FeaturesModule,
    StaffModule,
    ReportsModule,
    MessagingModule,
    AdminModule,
  ],
})
export class AppModule {}
