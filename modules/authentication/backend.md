# Authentication - Backend

## Routes

### `auth.routes.js`
- **Path**: `routes/auth.routes.js`
- **Purpose**: All admin authentication endpoints

| Endpoint | Method | Middleware | Controller |
|----------|--------|-----------|------------|
| `/api/auth/register` | POST | - | `registerCinemaAdmin` |
| `/api/auth/login` | POST | - | `loginCinemaAdmin` |
| `/api/auth/logout` | POST | - | `logoutCinemaAdmin` |
| `/api/auth/verify-email` | GET | - | `verifyAdminEmail` |
| `/api/auth/resend-verification` | POST | - | `resendVerificationEmail` |
| `/api/auth/forgot-password` | POST | - | `forgotPassword` |
| `/api/auth/reset-password` | POST | - | `resetPassword` |
| `/api/auth/accept-invite` | GET | - | `validateInviteToken` |
| `/api/auth/accept-invite` | POST | - | `acceptInvite` |
| `/api/auth/google-login` | POST | - | `googleLoginAdmin` |
| `/api/auth/github-login` | POST | - | `githubLoginAdmin` |
| `/api/auth/me` | GET | `verifyCinemaAdminAccessToken` | `getCinemaAdminMe` |
| `/api/auth/onboarding` | POST | `verifyCinemaAdminAccessToken` | `completeOnboarding` |
| `/api/auth/refresh` | POST | `verifyCinemaAdminRefreshToken` | `refreshCinemaAdminToken` |
| `/api/auth/hall` | PATCH | `verifyCinemaAdminAccessToken` | `updateCinemaHall` |
| `/api/auth/change-password` | POST | `verifyCinemaAdminAccessToken` | `changePassword` |
| `/api/auth/logout-all` | POST | `verifyCinemaAdminAccessToken` | `logoutAllDevices` |
| `/api/auth/security` | GET | `verifyCinemaAdminAccessToken` | `getAdminSecurity` |
| `/api/auth/link-provider` | POST | `verifyCinemaAdminAccessToken` | `linkProviderAdmin` |
| `/api/auth/unlink-provider` | POST | `verifyCinemaAdminAccessToken` | `unlinkProviderAdmin` |
| `/api/auth/set-password` | POST | `verifyCinemaAdminAccessToken` | `setPasswordAdmin` |
| `/api/auth/admins` | GET | `verifySuperAdmin` | `getAllAdmins` |
| `/api/auth/admins/:id/logs` | GET | `verifySuperAdmin` | `getAdminSecurityLogs` |

### `customerAuth.routes.js`
- **Path**: `routes/customerAuth.routes.js`
- **Purpose**: All customer authentication endpoints

| Endpoint | Method | Middleware | Controller |
|----------|--------|-----------|------------|
| `/api/customer/signup` | POST | - | `registerCustomer` |
| `/api/customer/login` | POST | - | `loginCustomer` |
| `/api/customer/logout` | POST | - | `logoutCustomer` |
| `/api/customer/google-login` | POST | - | `googleLoginCustomer` |
| `/api/customer/update` | PUT | `verifyCustomer` | `updateCustomerProfile` |
| `/api/customer/me` | GET | `verifyCustomer` | `getCustomerMe` |
| `/api/customer/refresh` | POST | `verifyCustomerRefreshToken` | `refreshCustomerToken` |
| `/api/customer/change-password` | POST | `verifyCustomer` | `changePasswordCustomer` |
| `/api/customer/forgot-password` | POST | - | `forgotPasswordCustomer` |
| `/api/customer/reset-password` | POST | - | `resetPasswordCustomer` |
| `/api/customer/link-provider` | POST | `verifyCustomer` | `linkProviderCustomer` |
| `/api/customer/unlink-provider` | POST | `verifyCustomer` | `unlinkProviderCustomer` |
| `/api/customer/set-password` | POST | `verifyCustomer` | `setPasswordCustomer` |

---

## Controllers

### `auth.Controller.js` (1661 lines)
- **Path**: `controllers/auth.Controller.js`
- **Key Functions**:

| Function | Purpose |
|----------|---------|
| `registerCinemaAdmin` | Creates admin with hashed password, generates verification token, sends email |
| `verifyAdminEmail` | Validates verification token, marks email verified |
| `resendVerificationEmail` | Re-generates verification token with 2-min rate limit |
| `loginCinemaAdmin` | Validates credentials, checks lockout, checks email verification, issues JWT tokens, loads org permissions |
| `refreshCinemaAdminToken` | Issues new access token from valid refresh token |
| `getCinemaAdminMe` | Returns full admin profile + hall + org permissions |
| `forgotPassword` | Sends password reset link with 15-min expiry |
| `resetPassword` | Validates token, ensures different password, hashes new password, revokes all sessions |
| `changePassword` | Verifies current password, updates, revokes other sessions |
| `logoutCinemaAdmin` | Revokes specific session, clears cookies |
| `logoutAllDevices` | Revokes all admin sessions, clears cookies |
| `getAdminSecurity` | Returns email status, failed attempts, active sessions, recent security logs |
| `getAllAdmins` | Lists all cinema admins with search/pagination (super admin) |
| `getAdminSecurityLogs` | Returns security logs for specific admin (super admin) |
| `updateCinemaHall` | Updates cinema hall name, location, coordinates |
| `googleLoginAdmin` | Verifies Google token, creates/linked account, issues JWT |
| `githubLoginAdmin` | Exchanges GitHub code, creates/links account, issues JWT |
| `linkProviderAdmin` | Links Google/GitHub to existing admin account |
| `unlinkProviderAdmin` | Unlinks provider, prevents removing last auth method |
| `setPasswordAdmin` | Sets password for OAuth-only accounts |
| `validateInviteToken` | Validates team invite token |
| `acceptInvite` | Accepts invite and sets initial password |
| `completeOnboarding` | Creates organization, seeds roles/permissions, creates hall, seeds default settings |

### `customerAuth.Controller.js` (707 lines)
- **Path**: `controllers/customerAuth.Controller.js`
- **Key Functions**:

| Function | Purpose |
|----------|---------|
| `registerCustomer` | Creates customer record, returns user |
| `loginCustomer` | Validates credentials, checks tiered lockout, checks email verification, issues JWT |
| `logoutCustomer` | Revokes customer session, clears cookies |
| `updateCustomerProfile` | Updates name, phone, district, state |
| `changePasswordCustomer` | Verifies current password, updates, revokes other sessions |
| `forgotPasswordCustomer` | Sends password reset OTP (generic response to prevent enumeration) |
| `resetPasswordCustomer` | Verifies OTP hash, ensures different password, updates, revokes all sessions |
| `refreshCustomerToken` | Issues new access token |
| `getCustomerMe` | Returns customer profile |
| `googleLoginCustomer` | Verifies Google token, creates/links account, issues JWT |
| `linkProviderCustomer` | Links Google to existing customer account |
| `unlinkProviderCustomer` | Unlinks Google, prevents removing last auth method |
| `setPasswordCustomer` | Sets password for OAuth-only accounts |

---

## Middleware

### `verifyCinemaAdmin.js`
- **Path**: `middleware/verifyCinemaAdmin.js`
- **Key Functions**:

| Function | Purpose |
|----------|---------|
| `verifyCinemaAdminAccessToken` | Verifies JWT access token from cookie or Bearer header, attaches `req.admin` |
| `verifyCinemaAdminRefreshToken` | Verifies JWT refresh token, checks session not revoked in DB |
| `verifySuperAdmin` | Verifies token + checks `role === 'superAdmin'` |
| `verifyCinemaHall` | Verifies token + fetches cinema hall(s) for admin |
| `verifyScreenOwnership` | Verifies screen IDs belong to admin's halls |
| `verifyCustomer` | Verifies customer access token (`cusAccessToken` cookie), attaches `req.customer` |
| `requireActiveHall` | Reads `X-Hall-Id` header, verifies hall ownership/by assignment |
| `verifyCustomerRefreshToken` | Verifies customer refresh token, checks session revocation |

### `requirePermission.js`
- **Path**: `middleware/requirePermission.js`
- **Purpose**: Checks that the authenticated admin has a specific permission key

---

## Utilities

### `generateTokenAndSetCookie.js`
- **Path**: `utils/generateTokenAndSetCookie.js`
- **Purpose**: Generates access token (1d) + refresh token (30d), stores hash in DB, sets HttpOnly cookies
- **Admin**: `accessToken`/`refreshToken` cookies, `admin_sessions` table
- **Customer**: `cusAccessToken`/`cusRefreshToken` cookies, `customer_sessions` table
- **Extra**: Resolves orgId, roleKey, permissionsVersion from DB for admin tokens

### `oauthProviders.js`
- **Path**: `utils/oauthProviders.js`
- **Purpose**: Google token verification (ID token + access token fallback), GitHub code exchange + user info fetch

### `hashToken.js`
- **Path**: `utils/hashToken.js`
- **Purpose**: SHA-256 hashing of tokens for DB storage

### `passwordPolicy.js`
- **Path**: `utils/passwordPolicy.js`
- **Purpose**: Password validation (min length, uppercase, lowercase, digit, special char)

### `oauthRateLimit.js`
- **Path**: `utils/oauthRateLimit.js`
- **Purpose**: In-memory rate limiting for OAuth login attempts per IP

---

## Mail

### `emails.js`
- **Path**: `mail/emails.js`
- **Purpose**: Email sending functions for auth events
- **Admin Emails**: verification, password reset, password changed, account locked
- **Customer Emails**: OTP, password changed, account locked

### `mail.config.js`
- **Path**: `mail/mail.config.js`
- **Purpose**: Nodemailer transporter configuration

### `emailTemplate.js`
- **Path**: `mail/emailTemplate.js`
- **Purpose**: HTML email template builder
