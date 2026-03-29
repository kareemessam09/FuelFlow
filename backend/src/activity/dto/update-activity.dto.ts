import { PartialType } from '@nestjs/mapped-types';
import { ToggleActivityDto } from './create-activity.dto';

export class UpdateActivityDto extends PartialType(ToggleActivityDto) {}
