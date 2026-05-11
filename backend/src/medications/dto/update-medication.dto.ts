import { PartialType } from '@nestjs/mapped-types';
import { CreateMedicationDto } from './create-medication.dto';

/**
 * DTO for updating an existing medication
 * All fields are optional
 */
export class UpdateMedicationDto extends PartialType(CreateMedicationDto) {}
