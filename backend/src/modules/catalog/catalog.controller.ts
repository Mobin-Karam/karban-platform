import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/jwt-auth.guard'; import { CurrentUserId } from '../../common/current-user.decorator';
import { BusinessAccessService } from '../businesses/business-access.service'; import { CatalogService } from './catalog.service'; import { CreateServiceCategoryDto,CreateServiceDto } from './dto';
@Controller({path:'businesses/:businessId/catalog',version:'1'}) @UseGuards(JwtAuthGuard)
export class CatalogController {
 constructor(private readonly service:CatalogService,private readonly access:BusinessAccessService){}
 @Get() async list(@CurrentUserId()u:string,@Param('businessId')b:string){await this.access.require(b,u);return this.service.categories(b);}
 @Post('categories') async cat(@CurrentUserId()u:string,@Param('businessId')b:string,@Body()d:CreateServiceCategoryDto){await this.access.require(b,u,['OWNER','MANAGER']);return this.service.createCategory(b,d);}
 @Post('services') async create(@CurrentUserId()u:string,@Param('businessId')b:string,@Body()d:CreateServiceDto){await this.access.require(b,u,['OWNER','MANAGER']);return this.service.createService(b,d);}
 @Patch('services/:serviceId') async update(@CurrentUserId()u:string,@Param('businessId')b:string,@Param('serviceId')id:string,@Body()d:CreateServiceDto){await this.access.require(b,u,['OWNER','MANAGER']);return this.service.updateService(id,d);}
}
