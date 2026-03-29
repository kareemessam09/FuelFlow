import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new user
   */
  async create(createUserDto: CreateUserDto) {
    // Check if email already exists
    const existing = await this.prisma.user.findUnique({
      where: { email: createUserDto.email },
    });

    if (existing) {
      throw new ConflictException('User with this email already exists');
    }

    return this.prisma.user.create({
      data: {
        email: createUserDto.email,
        name: createUserDto.name,
        sensitivityLevel: createUserDto.sensitivityLevel ?? 'Sensitive',
        targetGoal: createUserDto.targetGoal ?? 'Maintenance',
      },
    });
  }

  /**
   * Get all users
   */
  async findAll() {
    return this.prisma.user.findMany({
      include: {
        _count: {
          select: {
            mealLogs: true,
            activityLogs: true,
          },
        },
      },
    });
  }

  /**
   * Get a single user by ID
   */
  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        mealLogs: {
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
        activityLogs: {
          orderBy: { startTime: 'desc' },
          take: 5,
        },
      },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
  }

  /**
   * Get user by email
   */
  async findByEmail(email: string) {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new NotFoundException(`User with email ${email} not found`);
    }

    return user;
  }

  /**
   * Update a user
   */
  async update(id: string, updateUserDto: UpdateUserDto) {
    // Check if user exists
    await this.findOne(id);

    // If email is being updated, check for conflicts
    if (updateUserDto.email) {
      const existing = await this.prisma.user.findFirst({
        where: {
          email: updateUserDto.email,
          NOT: { id },
        },
      });

      if (existing) {
        throw new ConflictException('Email already in use by another user');
      }
    }

    return this.prisma.user.update({
      where: { id },
      data: updateUserDto,
    });
  }

  /**
   * Delete a user
   */
  async remove(id: string) {
    // Check if user exists
    await this.findOne(id);

    return this.prisma.user.delete({
      where: { id },
    });
  }
}
