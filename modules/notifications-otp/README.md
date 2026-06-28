# Notifications & OTP Module

## Module Purpose
Handle all email-based notification delivery (admin and customer) and customer OTP-based verification for signup and password reset flows. The module is split into a mail transport layer with branded HTML templates and an OTP controller with rate limiting, hashed storage, and verification logic.

## Business Objective
Provide a secure, rate-limited OTP system for customer email verification and password resets, paired with a comprehensive notification email system that keeps both admins and customers informed about account events (verification, password changes, account locks).

## Features
- **OTP Send**: Generate and email 6-digit OTPs for `signup` and `password_reset` types
- **OTP Verify**: Validate OTPs with SHA-256 hash comparison, attempt tracking, and expiry enforcement
- **Rate Limiting**: 3 OTP sends per 10-minute window per (email, type) pair
- **Enumeration Protection**: Password reset requests return generic response for unknown emails
- **Admin Auth Emails**: Verification, password reset, password changed, account locked notifications
- **Customer Auth Emails**: OTP delivery, password changed, account locked notifications
- **Branded HTML Templates**: Dark-themed, CineMax-branded email templates with responsive design
- **Admin Notification Preferences**: Per-admin notification toggle settings via `user_settings` table
- **Admin Notifications Page**: Placeholder UI in admin panel for future notification history
- **Customer Notifications Page**: Placeholder UI in user app for future notification history

## User Roles Involved
- **Super Admin**: Receives admin auth notification emails
- **Cinema Admin**: Receives admin auth notification emails; manages notification preferences
- **Customer**: Receives OTP emails and customer auth notification emails

## Dependencies
- **Nodemailer**: SMTP email transport via Gmail
- **Node.js Crypto**: SHA-256 hashing for OTP storage and comparison
- **PostgreSQL**: `otp_verifications` table with rate-limit and attempt-tracking columns
- **Express**: OTP route handlers (public endpoints)
- **dotenv**: SMTP credentials via `MAIL_ID`, `MAIL_PASSWORD` env vars

## Related Modules
- [Authentication](../authentication/README.md) - OTP used for customer signup and password reset
- [Settings](../settings/README.md) - Notification preferences in `user_settings` table
- [User Management (Customers)](../user-management-customers/README.md) - Customer account activation via OTP
