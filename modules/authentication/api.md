# Authentication - API

## Admin Authentication

### POST `/api/auth/register`
- **Description**: Register a new cinema admin
- **Auth**: None (public)
- **Body**: `{ name, email, password, phone }`
- **Success (201)**: `{ message, admin: { id, name, email, phone, created_at } }`
- **Errors**: 400 (missing fields, weak password), 409 (email exists), 500

### POST `/api/auth/login`
- **Description**: Log in as cinema admin
- **Auth**: None (public)
- **Body**: `{ email, password }`
- **Success (200)**: `{ message, accessToken, refreshToken, admin: { id, name, email, phone, role, email_verified, permissions, orgId, roleKey }, hall }`
- **Errors**: 400 (missing fields), 401 (invalid credentials), 403 (EMAIL_NOT_VERIFIED), 423 (ACCOUNT_LOCKED with `lockedUntil`)

### POST `/api/auth/logout`
- **Description**: Log out, revoke current session
- **Auth**: Optional (reads cookies if present)
- **Success (200)**: `{ message: "Logged out successfully" }`

### GET `/api/auth/verify-email`
- **Description**: Verify email with token from link
- **Auth**: None (public)
- **Query**: `?token=`
- **Success (200)**: `{ message }`
- **Errors**: 400 (INVALID_TOKEN, TOKEN_EXPIRED)

### POST `/api/auth/resend-verification`
- **Description**: Resend verification email
- **Auth**: None (public)
- **Body**: `{ email }`
- **Rate Limit**: 2 minutes between resends
- **Success (200)**: Generic message (prevents enumeration)

### POST `/api/auth/forgot-password`
- **Description**: Send password reset link
- **Auth**: None (public)
- **Body**: `{ email }`
- **Success (200)**: Generic message (prevents enumeration)

### POST `/api/auth/reset-password`
- **Description**: Reset password with token
- **Auth**: None (public)
- **Body**: `{ token, newPassword }`
- **Success (200)**: `{ message }`
- **Errors**: 400 (INVALID_TOKEN, TOKEN_USED, TOKEN_EXPIRED, same password)

### GET `/api/auth/accept-invite`
- **Description**: Validate team invite token
- **Auth**: None (public)
- **Query**: `?token=`
- **Success (200)**: `{ email, name, orgName, invitedBy }`

### POST `/api/auth/accept-invite`
- **Description**: Accept invite and set password
- **Auth**: None (public)
- **Body**: `{ token, newPassword }`
- **Success (200)**: `{ message }`

### POST `/api/auth/google-login`
- **Description**: Login or register with Google
- **Auth**: None (public)
- **Body**: `{ idToken }`
- **Success (200)**: `{ message, accessToken, refreshToken, admin, hall }`
- **Errors**: 401 (invalid token), 423 (ACCOUNT_LOCKED), 429 (rate limit)

### POST `/api/auth/github-login`
- **Description**: Login or register with GitHub
- **Auth**: None (public)
- **Body**: `{ code }`
- **Success (200)**: `{ message, accessToken, refreshToken, admin, hall }`
- **Errors**: 400 (no verified email), 401 (invalid code), 423 (ACCOUNT_LOCKED), 429

### GET `/api/auth/me`
- **Description**: Get current admin profile + hall + org permissions
- **Auth**: `verifyCinemaAdminAccessToken`
- **Success (200)**: `{ admin: { id, name, email, phone, role, email_verified, permissions, orgId, roleKey, auth_providers, avatar, has_password }, hall }`

### POST `/api/auth/onboarding`
- **Description**: Complete onboarding (create org + hall + seed roles)
- **Auth**: `verifyCinemaAdminAccessToken`
- **Body**: `{ orgName, name, location, district, state, latitude, longitude, phone, description }`
- **Success (201)**: `{ message, orgId, orgName, hall }`

### POST `/api/auth/refresh`
- **Description**: Refresh access token
- **Auth**: `verifyCinemaAdminRefreshToken`
- **Success (200)**: `{ success: true }`

### PATCH `/api/auth/hall`
- **Description**: Update cinema hall details
- **Auth**: `verifyCinemaAdminAccessToken`
- **Body**: `{ hall_name, hall_location, hall_district, hall_state, latitude, longitude }`
- **Success (200)**: `{ message, hall }`

### POST `/api/auth/change-password`
- **Description**: Change password (authenticated)
- **Auth**: `verifyCinemaAdminAccessToken`
- **Body**: `{ currentPassword, newPassword }`
- **Success (200)**: `{ message }`
- **Side effect**: Revokes all other sessions

### POST `/api/auth/logout-all`
- **Description**: Sign out from all devices
- **Auth**: `verifyCinemaAdminAccessToken`
- **Success (200)**: `{ message }`

### GET `/api/auth/security`
- **Description**: Get security info (sessions, logs, email status)
- **Auth**: `verifyCinemaAdminAccessToken`
- **Success (200)**: `{ emailVerified, emailVerifiedAt, failedLoginAttempts, accountLockedUntil, passwordChangedAt, lastLoginAt, activeSessions[], recentLogs[] }`

### POST `/api/auth/link-provider`
- **Description**: Link Google/GitHub to account
- **Auth**: `verifyCinemaAdminAccessToken`
- **Body**: `{ provider, idToken (for google), code (for github) }`
- **Success (200)**: `{ message, auth_providers }`

### POST `/api/auth/unlink-provider`
- **Description**: Unlink Google/GitHub
- **Auth**: `verifyCinemaAdminAccessToken`
- **Body**: `{ provider }`
- **Success (200)**: `{ message, auth_providers }`

### POST `/api/auth/set-password`
- **Description**: Set password for OAuth-only accounts
- **Auth**: `verifyCinemaAdminAccessToken`
- **Body**: `{ newPassword }`
- **Success (200)**: `{ message, auth_providers }`

### GET `/api/auth/admins`
- **Description**: List all cinema admins (super admin only)
- **Auth**: `verifySuperAdmin`
- **Query**: `?search=&page=1&limit=10`
- **Success (200)**: `{ admins[], total }`

### GET `/api/auth/admins/:id/logs`
- **Description**: Get security logs for an admin (super admin only)
- **Auth**: `verifySuperAdmin`
- **Success (200)**: `{ admin, logs[] }`

---

## Customer Authentication

### POST `/api/customer/signup`
- **Description**: Register new customer
- **Auth**: None (public)
- **Body**: `{ name, email, password, phone, district, state }`
- **Success (201)**: `{ message, customer }`
- **Errors**: 400 (missing fields, weak password, email exists)

### POST `/api/customer/login`
- **Description**: Log in as customer
- **Auth**: None (public)
- **Body**: `{ email, password }`
- **Success (200)**: `{ message, customer: { id, name, email, phone, is_verified } }`
- **Errors**: 400 (invalid password with retry hint), 403 (email not verified), 404 (customer not found), 423 (ACCOUNT_LOCKED)

### POST `/api/customer/logout`
- **Description**: Log out, revoke session
- **Auth**: Optional
- **Success (200)**: `{ message }`

### POST `/api/customer/google-login`
- **Description**: Login or register with Google
- **Auth**: None (public)
- **Body**: `{ idToken }`
- **Success (200)**: `{ message, customer }`
- **Errors**: 423 (ACCOUNT_LOCKED), 429 (rate limit)

### PUT `/api/customer/update`
- **Description**: Update customer profile (name, phone, district, state)
- **Auth**: `verifyCustomer`
- **Body**: `{ name, phone, district, state }`
- **Success (200)**: `{ message, customer }`

### GET `/api/customer/me`
- **Description**: Get customer profile
- **Auth**: `verifyCustomer`
- **Success (200)**: `{ customer: { id, name, email, phone, district, state, is_verified, auth_providers, avatar, has_password } }`

### POST `/api/customer/refresh`
- **Description**: Refresh access token
- **Auth**: `verifyCustomerRefreshToken`
- **Success (200)**: `{ success: true }`

### POST `/api/customer/change-password`
- **Description**: Change password
- **Auth**: `verifyCustomer`
- **Body**: `{ currentPassword, newPassword }`
- **Success (200)**: `{ message }`

### POST `/api/customer/forgot-password`
- **Description**: Send password reset OTP
- **Auth**: None (public)
- **Body**: `{ email }`
- **Success (200)**: Generic message

### POST `/api/customer/reset-password`
- **Description**: Reset password with OTP
- **Auth**: None (public)
- **Body**: `{ email, otp, newPassword }`
- **Success (200)**: `{ message }`
- **Errors**: 400 (INVALID_OTP, OTP_EXPIRED, OTP_ATTEMPTS_EXCEEDED)

### POST `/api/customer/link-provider`
- **Description**: Link Google to account
- **Auth**: `verifyCustomer`
- **Body**: `{ provider: "google", idToken }`
- **Success (200)**: `{ message, auth_providers }`

### POST `/api/customer/unlink-provider`
- **Description**: Unlink Google
- **Auth**: `verifyCustomer`
- **Body**: `{ provider: "google" }`
- **Success (200)**: `{ message, auth_providers }`

### POST `/api/customer/set-password`
- **Description**: Set password for OAuth-only accounts
- **Auth**: `verifyCustomer`
- **Body**: `{ newPassword }`
- **Success (200)**: `{ message, auth_providers }`

---

## Common Error Response Format

```json
{
  "error": "Human-readable error message",
  "code": "MACHINE_READABLE_CODE",
  "lockedUntil": "2026-06-28T12:00:00Z",
  "hint": "5 attempts remaining before lockout"
}
```

## Token/Cookie Summary

| Cookie | Type | Duration | Domain |
|--------|------|----------|--------|
| `accessToken` | Admin JWT | 1 day | Admin app |
| `refreshToken` | Admin JWT | 30 days | Admin app |
| `cusAccessToken` | Customer JWT | 1 day | User app |
| `cusRefreshToken` | Customer JWT | 30 days | User app |

All tokens are HttpOnly, Secure in production, SameSite=None (production) or Lax (dev).
