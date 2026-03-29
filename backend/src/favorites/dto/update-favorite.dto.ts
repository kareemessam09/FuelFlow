import { PartialType } from '@nestjs/mapped-types';
import { CreateFavoriteDto, CreateTemplateDto, CreateCustomFoodDto } from './create-favorite.dto';

export class UpdateFavoriteDto extends PartialType(CreateFavoriteDto) {}

export class UpdateTemplateDto extends PartialType(CreateTemplateDto) {}

export class UpdateCustomFoodDto extends PartialType(CreateCustomFoodDto) {}
