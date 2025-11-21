'use strict';

const nodemailer = require('nodemailer');

// Store OTPs temporarily (in production, use Redis)
const otpStore = new Map();

const transporter = nodemailer.createTransport({
  host: 'smtp-relay.brevo.com',
  port: 587,
  auth: {
    user: '943fa5001@smtp-brevo.com',
    pass: 'xsmtpsib-df3171ae9c3d06aac09c5670390e0fa46b73a82bf9fc1cb1830d811121a5a8aa-vXAC1KEIspgyVHaeso'
  }
});

module.exports = {
  async sendOtp(ctx) {
    console.log('=== SEND OTP REQUEST ===');
    const { email } = ctx.request.body;
    console.log('Email received:', email);

    if (!email) {
      console.log('ERROR: No email provided');
      return ctx.badRequest('Email is required');
    }

    // Check if user exists
    console.log('Checking if user exists...');
    const user = await strapi.query('plugin::users-permissions.user').findOne({
      where: { email }
    });

    if (!user) {
      console.log('ERROR: User not found for email:', email);
      return ctx.badRequest('User not found');
    }

    console.log('User found:', user.username);

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    console.log('Generated OTP:', otp);
    
    // Store OTP with 10 minute expiry
    otpStore.set(email, {
      otp,
      expires: Date.now() + 10 * 60 * 1000
    });
    console.log('OTP stored in memory');

    // Send email
    console.log('Attempting to send email...');
    try {
      await transporter.sendMail({
        from: '943fa5001@smtp-brevo.com',
        to: email,
        subject: 'Password Reset OTP - Chat App',
        text: `Your OTP for password reset is: ${otp}\n\nThis code will expire in 10 minutes.\n\nIf you didn't request this, please ignore this email.`,
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px;">
            <h2 style="color: #333;">Password Reset Request</h2>
            <p>You requested to reset your password. Use the OTP code below in the app:</p>
            <div style="background: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px;">
              <h1 style="color: #2196F3; font-size: 36px; letter-spacing: 8px; margin: 0;">${otp}</h1>
            </div>
            <p style="color: #666;">This code will expire in <strong>10 minutes</strong>.</p>
            <p style="color: #999; font-size: 12px; margin-top: 30px;">If you didn't request this, please ignore this email.</p>
          </div>
        `
      });

      console.log('Email sent successfully!');
      ctx.send({ message: 'OTP sent successfully' });
    } catch (error) {
      console.error('=== EMAIL ERROR ===');
      console.error('Error details:', error);
      console.error('Error message:', error.message);
      ctx.badRequest('Failed to send email');
    }
  },

  async verifyOtpAndReset(ctx) {
    const { email, otp, newPassword } = ctx.request.body;

    if (!email || !otp || !newPassword) {
      return ctx.badRequest('Email, OTP, and new password are required');
    }

    const stored = otpStore.get(email);

    if (!stored) {
      return ctx.badRequest('No OTP found for this email');
    }

    if (Date.now() > stored.expires) {
      otpStore.delete(email);
      return ctx.badRequest('OTP expired');
    }

    if (stored.otp !== otp) {
      return ctx.badRequest('Invalid OTP');
    }

    // Update password
    const user = await strapi.query('plugin::users-permissions.user').findOne({
      where: { email }
    });

    if (!user) {
      return ctx.badRequest('User not found');
    }

    await strapi.plugins['users-permissions'].services.user.edit(user.id, {
      password: newPassword
    });

    otpStore.delete(email);

    ctx.send({ message: 'Password reset successfully' });
  }
};
