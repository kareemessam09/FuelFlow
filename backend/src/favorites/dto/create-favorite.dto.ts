import {
  IsString,
  IsNumber,
  IsOptional,
  Min,
  Max,
  IsIn,
} from 'class-validator';

export class CreateFavoriteDto {
  @IsString()
  foodName: string;

  @IsNumber()
  @Min(0)
  @Max(100)
  fullnessVolume: number;

  @IsNumber()
  @Min(1)
  @Max(100)
  absorptionRate: number;

  @IsOptional()
  @IsString()
  @IsIn(['Fast', 'Balanced', 'Slow'])
  absorptionProfile?: string = 'Balanced';

  @IsNumber()
  @Min(10)
  @Max(480)
  estimatedSatiety: number;

  @IsOptional()
  @IsString()
  @IsIn(['breakfast', 'lunch', 'dinner', 'snack', 'other'])
  category?: string = 'other';

  @IsOptional()
  @IsNumber()
  calories?: number;

  @IsOptional()
  @IsNumber()
  protein?: number;

  @IsOptional()
  @IsNumber()
  carbs?: number;

  @IsOptional()
  @IsNumber()
  fat?: number;

  @IsOptional()
  @IsString()
  imageUrl?: string;
}

export class CreateTemplateDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsString()
  foodName: string;

  @IsNumber()
  @Min(0)
  @Max(100)
  fullnessVolume: number;

  @IsNumber()
  @Min(1)
  @Max(100)
  absorptionRate: number;

  @IsOptional()
  @IsString()
  @IsIn(['Fast', 'Balanced', 'Slow'])
  absorptionProfile?: string = 'Balanced';

  @IsNumber()
  @Min(10)
  @Max(480)
  estimatedSatiety: number;

  @IsOptional()
  @IsString()
  @IsIn(['breakfast', 'lunch', 'dinner', 'snack', 'other'])
  category?: string = 'other';

  @IsOptional()
  @IsNumber()
  calories?: number;

  @IsOptional()
  @IsNumber()
  protein?: number;

  @IsOptional()
  @IsNumber()
  carbs?: number;

  @IsOptional()
  @IsNumber()
  fat?: number;
}

export class CreateCustomFoodDto {
  @IsString()
  foodName: string;

  @IsNumber()
  @Min(0)
  @Max(100)
  fullnessVolume: number;

  @IsNumber()
  @Min(1)
  @Max(100)
  absorptionRate: number;

  @IsOptional()
  @IsString()
  @IsIn(['Fast', 'Balanced', 'Slow'])
  absorptionProfile?: string = 'Balanced';

  @IsNumber()
  @Min(10)
  @Max(480)
  estimatedSatiety: number;

  @IsOptional()
  @IsString()
  servingSize?: string;

  @IsOptional()
  @IsNumber()
  calories?: number;

  @IsOptional()
  @IsNumber()
  protein?: number;

  @IsOptional()
  @IsNumber()
  carbs?: number;

  @IsOptional()
  @IsNumber()
  fat?: number;
}
