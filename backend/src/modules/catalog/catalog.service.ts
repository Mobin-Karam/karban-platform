import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateServiceCategoryDto, CreateServiceDto } from './dto';
@Injectable()
export class CatalogService {
  constructor(private readonly prisma: PrismaService) {}
  categories(businessId: string) { return this.prisma.serviceCategory.findMany({ where:{businessId}, include:{services:{orderBy:{name:'asc'}}}, orderBy:[{sortOrder:'asc'},{name:'asc'}] }); }
  createCategory(businessId:string,dto:CreateServiceCategoryDto){return this.prisma.serviceCategory.create({data:{businessId,...dto}});}
  createService(businessId:string,dto:CreateServiceDto){ return this.prisma.service.create({data:{businessId,name:dto.name,description:dto.description,categoryId:dto.categoryId,priceRial:BigInt(dto.priceRial),unitLabel:dto.unitLabel ?? 'خدمت',taxRateBasisPoints:dto.taxRateBasisPoints ?? 0,taxProductServiceId:dto.taxProductServiceId,durationMinutes:dto.durationMinutes,active:dto.active ?? true}}); }
  updateService(id:string,dto:Partial<CreateServiceDto>){ return this.prisma.service.update({where:{id},data:{...dto,priceRial:dto.priceRial != null?BigInt(dto.priceRial):undefined}}); }
}
