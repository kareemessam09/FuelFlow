import { PartialType } from '@nestjs/mapped-types';
import { CreateCustomActivityDto, CreateActivityGoalDto } from './create-custom-activity.dto';

export class UpdateCustomActivityDto extends PartialType(CreateCustomActivityDto) {}

export class UpdateActivityGoalDto extends PartialType(CreateActivityGoalDto) {}
