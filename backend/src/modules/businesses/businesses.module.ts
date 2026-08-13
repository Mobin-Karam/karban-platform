import{FeatureGateModule}from'../feature-gate/feature-gate.module';import { Module } from '@nestjs/common';
import { BusinessesController } from './businesses.controller';
import { BusinessesService } from './businesses.service';
import { BusinessAccessService } from './business-access.service';
@Module({ imports: [FeatureGateModule], controllers: [BusinessesController], providers: [BusinessesService, BusinessAccessService], exports: [BusinessesService, BusinessAccessService] })
export class BusinessesModule {}
