# Authentication Module

## Module Purpose
Handles identity verification, session management, and access control for both cinema admin staff and end customers across the Cinema Hall platform.

## Business Objective
Provide a secure, multi-provider authentication system supporting email/password, Google OAuth, and GitHub OAuth with tiered account lockout, session revocation, and role-based access control.

## Features
- **Admin Authentication**: Register, login, logout, email verification, password reset, session management
- **Customer Authentication**: Signup with OTP verification, login with account lockout, password reset via OTP
- **OAuth Integration**: Google Login (ID token + access token), GitHub Login (authorization code flow)
- **Security**: Tiered account lockout (5/10/15 failed attempts), password policy enforcement, security event logging
- **Session Management**: HttpOnly JWT cookies, refresh token rotation, session revocation on password change
- **Provider Linking**: Link/unlink OAuth providers, set password for OAuth-only accounts
- **Invite System**: Validate and accept team invite tokens
- **Onboarding**: Complete organization, cinema hall, and role setup for new admins

### Onboarding Eligibility

- Only an account holder without an active organization membership may create a new organization.
- Platform `staff` accounts cannot create organizations; they must be invited by an organization owner.
- An admin already belonging to another owner's organization cannot create a second organization.
- An existing owner may retry onboarding idempotently. The server-side check is authoritative; the frontend redirect is only a convenience.

## User Roles Involved
- **Super Admin**: Platform-level admin who can view all admins and security logs
- **Cinema Admin**: Cinema hall operator who manages their hall, team, and settings
- **Staff**: Organization members with role-based permissions
- **Customer**: End user who browses movies and books tickets

## Dependencies
- **bcrypt**: Password hashing (12 rounds)
- **jsonwebtoken**: JWT access/refresh token generation and verification
- **google-auth-library**: Google OAuth token verification
- **nodemailer**: Email sending for verification, password reset, OTP
- **winston**: Security event logging
- **PostgreSQL**: Session, token, and security log storage

## Related Modules
- [Roles, Permissions & Team Management](../roles-permissions-team/README.md) - Role-based access after authentication
- [Settings](../settings/README.md) - Password policy and lockout configuration
- [Notifications & OTP](../notifications-otp/README.md) - OTP generation and email notifications for auth events
