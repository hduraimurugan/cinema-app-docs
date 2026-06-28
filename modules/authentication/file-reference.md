# Authentication - File Reference

## Admin App (`cinema-hall-admin`)

| File Path | Purpose | Imports | Exports |
|-----------|---------|---------|---------|
| `src/pages/Auth/AuthPage.jsx` | Auth container with slide transitions | framer-motion, lucide-react, LoginForm, RegisterForm, ForgotPasswordForm, VerifyEmailForm, ResetPasswordForm | `AuthPage` |
| `src/pages/Auth/LoginForm.jsx` | Admin login (email/password + OAuth) | useAuth, authAPI, shadcn/ui, @react-oauth/google | `LoginForm` |
| `src/pages/Auth/RegisterForm.jsx` | Admin registration form | useAuth, authAPI, shadcn/ui | `RegisterForm` |
| `src/pages/Auth/ForgotPasswordForm.jsx` | Request password reset | authAPI, shadcn/ui | `ForgotPasswordForm` |
| `src/pages/Auth/ResetPasswordForm.jsx` | Set new password from token | authAPI, useSearchParams, shadcn/ui | `ResetPasswordForm` |
| `src/pages/Auth/VerifyEmailForm.jsx` | Verify email from token link | authAPI, useSearchParams, shadcn/ui | `VerifyEmailForm` |
| `src/pages/Auth/GitHubCallback.jsx` | Handle GitHub OAuth redirect | useAuth, useSearchParams | `GitHubCallback` |
| `src/context/AuthContext.jsx` | Global admin auth state | react, authAPI | `AuthProvider`, `useAuth` |
| `src/context/PermissionContext.jsx` | Permission checking for RBAC | react, teamService | `PermissionProvider`, `usePermissions` |
| `src/routes/ProtectedRoutes.jsx` | Auth guard requiring login | react-router-dom, useAuth, Loader | `ProtectedRoute` |
| `src/routes/AdminProtectedRoutes.jsx` | Enhanced guard (auth + superadmin + permission + org) | react-router-dom, useAuth, usePermissions, Loader | `AdminProtectedRoute` |
| `src/routes/HallGuard.jsx` | Guard requiring at least one hall | react-router-dom, useHall, useAuth | `HallGuard` |
| `src/services/api.js` | HTTP client (authAPI section) | fetch | `authAPI` |

## User App (`cinema-hall-users`)

| File Path | Purpose | Imports | Exports |
|-----------|---------|---------|---------|
| `src/components/LoginModal.jsx` | Customer login/signup modal | @react-oauth/google, shadcn/ui, useCustomerAuth, customerAuthAPI, passwordPolicy | `LoginModal` |
| `src/context/CustomerAuthContext.jsx` | Global customer auth + location | react, customerAuthAPI | `CustomerAuthProvider`, `useCustomerAuth` |
| `src/routes/ProtectedRoutes.jsx` | Auth guard for customers | react-router-dom, useCustomerAuth, Loader | `ProtectedRoute` |
| `src/services/api.js` | HTTP client (customerAuthAPI section) | fetch | `customerAuthAPI` |
| `src/utils/passwordPolicy.js` | Password validation rules | - | `PASSWORD_POLICY_CHECKS` |

## Backend API (`cinema-hall-api`)

| File Path | Purpose | Imports | Exports |
|-----------|---------|---------|---------|
| `routes/auth.routes.js` | Admin auth route definitions | express, auth.Controller, verifyCinemaAdmin | `router` |
| `routes/customerAuth.routes.js` | Customer auth route definitions | express, customerAuth.Controller, verifyCinemaAdmin | `router` |
| `controllers/auth.Controller.js` | Admin auth business logic | pool, bcrypt, jwt, generateTokenAndSetCookie, generateVerificationToken, hashToken, passwordPolicy, oauthProviders, oauthRateLimit, emails, logger, teamService | 26 controller functions |
| `controllers/customerAuth.Controller.js` | Customer auth business logic | pool, bcrypt, jwt, crypto, generateCustomerTokenAndSetCookie, hashToken, passwordPolicy, oauthProviders, oauthRateLimit, emails, logger | 14 controller functions |
| `middleware/verifyCinemaAdmin.js` | Auth middleware (token verification, hall verification, ownership checks) | jwt, pool, db, logger, hashToken | `verifyCinemaAdminAccessToken`, `verifyCinemaAdminRefreshToken`, `verifySuperAdmin`, `verifyCinemaHall`, `verifyScreenOwnership`, `verifyCustomer`, `requireActiveHall`, `verifyCustomerRefreshToken` |
| `middleware/requirePermission.js` | Permission-based access control | pool, logger | `requirePermission` |
| `utils/generateTokenAndSetCookie.js` | JWT token generation + cookie setter + DB session persistence | jwt, pool, hashToken, logger | `generateTokenAndSetCookie`, `generateCustomerTokenAndSetCookie` |
| `utils/generateVerificationToken.js` | Crypto-random token generator | crypto | `generateVerificationToken` |
| `utils/hashToken.js` | SHA-256 token hasher | crypto | `hashToken` |
| `utils/passwordPolicy.js` | Password strength validation | - | `validatePassword` |
| `utils/oauthProviders.js` | Google/GitHub OAuth verification | google-auth-library, logger | `verifyGoogleToken`, `exchangeGithubCode`, `getGithubUser` |
| `utils/oauthRateLimit.js` | In-memory OAuth rate limiter | - | `checkOAuthRateLimit` |
| `utils/logger.js` | Winston logger | winston | `logger` |
| `mail/emails.js` | Email sending functions | mail.config, emailTemplate | `sendAdminVerificationEmail`, `sendAdminPasswordResetEmail`, `sendAdminPasswordChangedEmail`, `sendAdminAccountLockedEmail`, `sendCustomerOtpEmail`, `sendCustomerPasswordChangedEmail`, `sendCustomerAccountLockedEmail` |
| `mail/mail.config.js` | Nodemailer transporter config | nodemailer | `transporter` |
| `mail/emailTemplate.js` | HTML email template builder | - | `emailTemplate` |
| `db.js` | PostgreSQL connection pool | postgres/pg | `pool` (default export) |
| `services/team.service.js` | Team/permission service (used for loading permissions on login) | pool, logger | `loadAdminPermissions`, `validateInviteToken`, `acceptInvite` |
