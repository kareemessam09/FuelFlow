import {
  Injectable,
  UnauthorizedException,
  ConflictException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { RegisterDto, LoginDto } from './dto';
import { OAuth2Client } from 'google-auth-library';
import { ConfigService } from '@nestjs/config';
import { randomBytes, createHash } from 'crypto';
import { EmailService } from './email.service';

@Injectable()
export class AuthService {
  private googleClient: OAuth2Client;

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private emailService: EmailService,
  ) {
    const clientId = this.configService.get<string>('GOOGLE_CLIENT_ID');
    this.googleClient = new OAuth2Client(clientId);
  }

  async register(dto: RegisterDto) {
    // Check if user already exists
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existingUser) {
      throw new ConflictException('Email already registered');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(dto.password, 10);

    // Create user
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        name: dto.name,
        password: hashedPassword,
        authProvider: 'local',
      },
    });

    // Generate tokens
    const tokens = await this.generateTokens(user.id, user.email);

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
      },
      ...tokens,
    };
  }

  async login(dto: LoginDto) {
    // Find user
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (!user || !user.password) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(dto.password, user.password);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Generate tokens
    const tokens = await this.generateTokens(user.id, user.email);

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
      },
      ...tokens,
    };
  }

  async googleAuth(idToken: string) {
    try {
      // Verify Google ID token
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: this.configService.get<string>('GOOGLE_CLIENT_ID'),
      });

      const payload = ticket.getPayload();
      if (!payload) {
        throw new UnauthorizedException('Invalid Google token');
      }

      const { sub: googleId, email, name } = payload;

      if (!email) {
        throw new UnauthorizedException('Email not provided by Google');
      }

      // Find or create user
      let user = await this.prisma.user.findUnique({
        where: { email },
      });

      if (!user) {
        // Create new user with Google auth
        user = await this.prisma.user.create({
          data: {
            email,
            name: name || email.split('@')[0],
            googleId,
            authProvider: 'google',
          },
        });
      } else if (!user.googleId) {
        // Link existing account to Google
        user = await this.prisma.user.update({
          where: { id: user.id },
          data: { googleId },
        });
      }

      // Generate tokens
      const tokens = await this.generateTokens(user.id, user.email);

      return {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
        },
        ...tokens,
      };
    } catch (error) {
      throw new UnauthorizedException('Invalid Google token');
    }
  }

  async updateFcmToken(userId: string, fcmToken: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });

    return { message: 'FCM token updated successfully' };
  }

  async forgotPassword(email: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || !user.password) {
      return {
        message:
          'If an account exists for this email, a password reset message has been sent.',
      };
    }

    const resetToken = randomBytes(24).toString('hex');
    const resetTokenHash = createHash('sha256')
      .update(resetToken)
      .digest('hex');
    const tokenExpiresAt = new Date(Date.now() + 15 * 60 * 1000);
    await this.prisma.notification.create({
      data: {
        userId: user.id,
        type: 'password_reset',
        title: 'Password reset token issued',
        body: 'Use this token to reset your password in the app.',
        data: {
          tokenHash: resetTokenHash,
          expiresAt: tokenExpiresAt.toISOString(),
          used: false,
        },
      },
    });
    await this.emailService.sendPasswordResetEmail(
      email,
      resetToken,
      tokenExpiresAt.toISOString(),
    );

    return {
      message:
        'If an account exists for this email, a password reset message has been sent.',
    };
  }

  async resetPassword(email: string, token: string, newPassword: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || !user.password) {
      throw new UnauthorizedException('Invalid reset request');
    }

    const latestResetRequest = await this.prisma.notification.findFirst({
      where: {
        userId: user.id,
        type: 'password_reset',
      },
      orderBy: { sentAt: 'desc' },
    });

    if (!latestResetRequest || !latestResetRequest.data) {
      throw new UnauthorizedException('Reset token not requested');
    }

    const resetData = latestResetRequest.data as {
      tokenHash?: string;
      expiresAt?: string;
      used?: boolean;
    };
    const storedHash = resetData.tokenHash;
    const expiresAt =
      resetData.expiresAt != null ? new Date(resetData.expiresAt) : new Date(0);
    if (!storedHash || resetData.used == true) {
      throw new UnauthorizedException('Reset token already used or invalid');
    }
    if (Number.isNaN(expiresAt.getTime()) || expiresAt.getTime() < Date.now()) {
      throw new UnauthorizedException('Reset token expired');
    }

    const providedHash = createHash('sha256').update(token).digest('hex');
    if (providedHash != storedHash) {
      throw new UnauthorizedException('Invalid reset token');
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await this.prisma.user.update({
      where: { id: user.id },
      data: { password: hashedPassword },
    });
    await this.prisma.notification.update({
      where: { id: latestResetRequest.id },
      data: {
        read: true,
        data: {
          tokenHash: storedHash,
          expiresAt: resetData.expiresAt,
          used: true,
          usedAt: new Date().toISOString(),
        },
      },
    });

    return { message: 'Password reset successfully' };
  }

  async changePassword(
    userId: string,
    currentPassword: string,
    newPassword: string,
  ) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.password) {
      throw new UnauthorizedException('Invalid user account');
    }

    const isValid = await bcrypt.compare(currentPassword, user.password);
    if (!isValid) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await this.prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword },
    });

    return { message: 'Password changed successfully' };
  }

  private async generateTokens(userId: string, email: string) {
    const payload = { sub: userId, email };

    const accessToken = await this.jwtService.signAsync(payload, {
      expiresIn: '7d',
    });

    return {
      accessToken,
    };
  }
}
