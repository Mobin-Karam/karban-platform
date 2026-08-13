import { Module } from '@nestjs/common'; import { CatalogController } from './catalog.controller'; import { CatalogService } from './catalog.service'; import { BusinessesModule } from '../businesses/businesses.module';
@Module({imports:[BusinessesModule],controllers:[CatalogController],providers:[CatalogService],exports:[CatalogService]}) export class CatalogModule{}
