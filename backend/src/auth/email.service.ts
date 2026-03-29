import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter?: nodemailer.Transporter;
  private readonly fromAddress: string;

  constructor(private readonly configService: ConfigService) {
    const host = this.configService.get<string>('SMTP_HOST');
    const port = Number(this.configService.get<string>('SMTP_PORT') ?? '587');
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');
    this.fromAddress =
      this.configService.get<string>('SMTP_FROM') ?? 'no-reply@fuelflow.local';

    if (host && user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: { user, pass },
      });
    } else {
      this.logger.warn(
        'SMTP is not fully configured. Password reset emails will be logged instead of sent.',
      );
    }
  }

  async sendPasswordResetEmail(
    recipientEmail: string,
    resetToken: string,
    expiresAtIso: string,
  ): Promise<void> {
    const subject = 'FuelFlow password reset token';
    const text =
      `Use this token to reset your password: ${resetToken}\n\n` +
      `This token expires at: ${expiresAtIso}\n\n` +
      'If you did not request this, you can ignore this email.';

    const html = `
      <p>Use this token to reset your FuelFlow password:</p>
      <p><strong style="font-size:18px;">${resetToken}</strong></p>
      <p>This token expires at: <strong>${expiresAtIso}</strong></p>
      <p>If you did not request this, you can ignore this email.</p>
    `;

    if (!this.transporter) {
      this.logger.log(
        `Password reset token for ${recipientEmail}: ${resetToken} (expires ${expiresAtIso})`,
      );
      return;
    }

    await this.transporter.sendMail({
      from: this.fromAddress,
      to: recipientEmail,
      subject,
      text,
      html,
    });
  }
}
