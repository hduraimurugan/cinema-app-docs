# Notifications & OTP - File Reference

## Admin App (`cinema-hall-admin`)

| File Path | Purpose | Key Imports | Exports |
|-----------|---------|-------------|---------|
| `src/pages/Notifications.jsx` | Admin notification preferences and history page (placeholder) | lucide-react (Bell, User, Settings) | `Notifications` (default) |

## User App (`cinema-hall-users`)

| File Path | Purpose | Key Imports | Exports |
|-----------|---------|-------------|---------|
| `src/pages/Notifications.jsx` | Customer notification settings page (placeholder) | lucide-react (User, Settings, Bell) | `Notifications` (default) |

## Backend API (`cinema-hall-api`)

### Mail System

| File Path | Purpose | Key Imports | Exports |
|-----------|---------|-------------|---------|
| `mail/mail.config.js` | Nodemailer Gmail SMTP transporter | nodemailer, dotenv | `transporter` |
| `mail/emailTemplate.js` | HTML email templates (admin + customer, branded) | - | 11 template constants |
| `mail/emails.js` | Email sending functions for auth events | emailTemplate.js, mail.config.js, dotenv, logger | 10 email functions |

### OTP System

| File Path | Purpose | Key Imports | Exports |
|-----------|---------|-------------|---------|
| `controllers/otp.Controller.js` | OTP send/verify logic with rate limiting, hashing, attempt tracking | pool, crypto, logger, sendCustomerOtpEmail | `sendOtp`, `verifyOtp` |
| `routes/otp.routes.js` | OTP route definitions (public) | express, otp.Controller | `router` (default) |

### Tests

| File Path | Purpose | Key Imports |
|-----------|---------|-------------|
| `tests/unit/controllers/otp.test.js` | OTP controller unit tests | vitest, pool, factories, mocks |
| `tests/mocks/email.js` | Nodemailer mock utilities | vitest |

## Database

| Object | Type | Schema | Description |
|--------|------|--------|-------------|
| `otp_verifications` | Table | public | OTP records with hash, expiry, attempt tracking, and verification status |
| `otp_verifications.id` | PK | UUID | Primary identifier |
| `otp_verifications.email` | FK | → customers(email) ON DELETE CASCADE | Customer email reference |
| `otp_verifications.email` + `type` | UNIQUE | (email, type) | One active OTP per (email, type) pair |
| `customers.email_verified` | Column | BOOLEAN | Set to true on successful signup OTP verification |

## Environment Variables

| Variable | Description | Used By |
|----------|-------------|---------|
| `MAIL_ID` | Gmail SMTP username / sender email | `mail.config.js`, `emails.js` |
| `MAIL_PASSWORD` | Gmail SMTP password or app password | `mail.config.js` |
