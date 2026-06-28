# Notifications & OTP - Backend

## Mail System

### `mail/mail.config.js`
- **Path**: `mail/mail.config.js`
- **Purpose**: Nodemailer transporter configuration
- **Transport**: Gmail SMTP via `nodemailer.createTransport`
  - `service`: `'gmail'`
  - `host`: `'smtp.gmail.com'`
  - `port`: `465`
  - `secure`: `true`
  - `auth.user`: `MAIL_ID` env var
  - `auth.pass`: `MAIL_PASSWORD` env var
- **Exports**: `transporter` (configured Nodemailer transport instance)

### `mail/emailTemplate.js`
- **Path**: `mail/emailTemplate.js`
- **Purpose**: HTML email template builder with CineMax branding

#### Admin Templates (dark theme, rose/pink primary)

| Template Constant | Placeholders | Used By |
|-------------------|--------------|---------|
| `ADMIN_VERIFY_EMAIL_TEMPLATE` | `{name}`, `{verificationLink}` | `sendAdminVerificationEmail` |
| `ADMIN_PASSWORD_RESET_TEMPLATE` | `{name}`, `{resetLink}` | `sendAdminPasswordResetEmail` |
| `ADMIN_PASSWORD_CHANGED_TEMPLATE` | `{name}`, `{changedAt}` | `sendAdminPasswordChangedEmail` |
| `ADMIN_ACCOUNT_LOCKED_TEMPLATE` | `{name}`, `{lockedUntil}` | `sendAdminAccountLockedEmail` |

#### Customer Templates (dark theme, matching admin branding)

| Template Constant | Placeholders | Used By |
|-------------------|--------------|---------|
| `CUSTOMER_OTP_TEMPLATE` | `{name}`, `{otp}`, `{otpTitle}`, `{otpSubtitle}` | `sendCustomerOtpEmail` |
| `CUSTOMER_ACCOUNT_LOCKED_TEMPLATE` | `{name}`, `{lockedUntil}` | `sendCustomerAccountLockedEmail` |
| `CUSTOMER_PASSWORD_CHANGED_TEMPLATE` | `{name}`, `{changedAt}` | `sendCustomerPasswordChangedEmail` |

#### Legacy Customer Templates (light theme, green primary)

| Template Constant | Placeholders | Used By |
|-------------------|--------------|---------|
| `VERIFICATION_EMAIL_TEMPLATE` | `{verificationCode}` | `sendVerificationEmail` |
| `WELCOME_EMAIL_TEMPLATE` | `{name}` | `sendWelcomeEmail` |
| `PASSWORD_RESET_REQUEST_TEMPLATE` | `{resetURL}` | `sendPasswordResetEmail` |
| `PASSWORD_RESET_SUCCESS_TEMPLATE` | - | `sendResetSuccessEmail` |

### `mail/emails.js`
- **Path**: `mail/emails.js`
- **Purpose**: Email sending functions for admin and customer auth flows

| Function | Recipient | Subject | Template |
|----------|-----------|---------|----------|
| `sendAdminVerificationEmail(email, name, verificationLink)` | Admin | "Verify your CineMax Admin email" | `ADMIN_VERIFY_EMAIL_TEMPLATE` |
| `sendAdminPasswordResetEmail(email, name, resetLink)` | Admin | "Reset your CineMax Admin password" | `ADMIN_PASSWORD_RESET_TEMPLATE` |
| `sendAdminPasswordChangedEmail(email, name)` | Admin | "Your CineMax Admin password was changed" | `ADMIN_PASSWORD_CHANGED_TEMPLATE` |
| `sendAdminAccountLockedEmail(email, name, lockedUntil)` | Admin | "Your CineMax Admin account has been locked" | `ADMIN_ACCOUNT_LOCKED_TEMPLATE` |
| `sendCustomerOtpEmail(email, name, otp, type)` | Customer | "Verify your CineMax account" or "Your CineMax password reset OTP" | `CUSTOMER_OTP_TEMPLATE` |
| `sendCustomerPasswordChangedEmail(email, name)` | Customer | "Your CineMax password was changed" | `CUSTOMER_PASSWORD_CHANGED_TEMPLATE` |
| `sendCustomerAccountLockedEmail(email, name, lockedUntil)` | Customer | "Your CineMax account has been locked" | `CUSTOMER_ACCOUNT_LOCKED_TEMPLATE` |

**Error Handling**: `sendAdminPasswordChangedEmail`, `sendAdminAccountLockedEmail`, `sendCustomerAccountLockedEmail`, and `sendCustomerPasswordChangedEmail` catch errors and log them without throwing — these are non-fatal notifications. All other email functions throw on failure.

## OTP System

### `otp.Controller.js`
- **Path**: `controllers/otp.Controller.js`

#### `sendOtp` (POST /api/otp/send)
| Step | Action |
|------|--------|
| 1 | Validate `email` and `type` (`'signup'` or `'password_reset'`) |
| 2 | Look up customer by email in `customers` table |
| 3 | If customer not found: `password_reset` returns generic 200 (prevents enumeration); `signup` returns 404 |
| 4 | Rate limit check: count recent OTPs (last 10 min) per (email, type); max 3 |
| 5 | Generate 6-digit random OTP (`Math.floor(100000 + Math.random() * 900000).toString()`) |
| 6 | Hash OTP with SHA-256 |
| 7 | Upsert into `otp_verifications` (keyed by `UNIQUE(email, type)`), resetting `is_verified`, `otp_attempts`, and `expires_at` |
| 8 | Send email via `sendCustomerOtpEmail` with plain-text OTP |
| 9 | Return generic message for `password_reset`; "OTP sent successfully" for `signup` |

#### `verifyOtp` (POST /api/otp/verify)
| Step | Action |
|------|--------|
| 1 | Validate `email` and `otp` presence |
| 2 | Fetch OTP record by (email, type) |
| 3 | Reject if: not found (404), already verified (400), expired (400 with `code: 'OTP_EXPIRED'`), or attempts >= 5 (400 with `code: 'OTP_ATTEMPTS_EXCEEDED'`) |
| 4 | Hash input OTP and compare with stored hash |
| 5 | On mismatch: increment `otp_attempts`, return 400 with remaining attempts count |
| 6 | On match: set `is_verified = true` |
| 7 | If type is `'signup'`: set `customers.is_verified = true` (activates account) |
| 8 | Return success message |

### `otp.routes.js`
- **Path**: `routes/otp.routes.js`

| Endpoint | Method | Controller | Auth |
|----------|--------|------------|------|
| `/api/otp/send` | POST | `sendOtp` | Public (no middleware) |
| `/api/otp/verify` | POST | `verifyOtp` | Public (no middleware) |

### OTP Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `OTP_RATE_LIMIT` | 3 | Max OTP sends per window |
| `OTP_RATE_WINDOW_MS` | 600,000 (10 min) | Rate limit sliding window |
| `OTP_EXPIRY` | 300,000 (5 min) | OTP validity duration |
| `MAX_OTP_ATTEMPTS` | 5 | Max wrong guesses before invalidation |

### Tests

**File**: `tests/unit/controllers/otp.test.js`
- Uses `vitest` with mocked `sendCustomerOtpEmail` and logger
- Test DB setup via `tests/setup/db.js` and `tests/setup/factories.js`

**sendOtp tests**:
- Returns 400 if email missing
- Returns 400 for invalid OTP type
- Returns 404 for unknown email (signup type)
- Returns generic 200 for unknown email (password_reset type) — prevents enumeration
- Sends OTP for known customer (signup) and verifies email was sent with correct params

**verifyOtp tests**:
- Returns 400 if email or OTP missing
- Returns 404 if OTP record not found
- Returns 400 with attempt count for wrong OTP
- Verifies correct OTP and confirms `customers.is_verified = true` in database

**File**: `tests/mocks/email.js`
- Provides `mockSendMail`, `mockCreateTransport`, `setupEmailMock()`, and `resetEmailMocks()` utilities
