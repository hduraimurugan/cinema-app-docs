# Authentication - Workflows

## 1. Admin Login Flow

```mermaid
sequenceDiagram
    actor A as Admin
    participant F as LoginForm
    participant C as AuthContext
    participant API as authAPI.js
    participant BE as Express Backend
    participant DB as PostgreSQL
    
    A->>F: Enter email + password
    F->>C: login(email, password)
    C->>API: authAPI.login(email, password)
    API->>BE: POST /api/auth/login
    
    BE->>DB: SELECT admin + hall (LEFT JOIN)
    DB-->>BE: admin record
    
    alt Account Locked
        BE->>DB: Check account_locked_until
        BE-->>API: 423 ACCOUNT_LOCKED
        API-->>C: Error with lockedUntil
        C-->>F: { success: false }
        F->>A: Show locked banner + unlock time
    else Invalid Password
        BE->>DB: Increment failed_login_attempts
        BE->>DB: INSERT admin_security_logs
        alt Reached Lockout Threshold
            BE->>DB: SET account_locked_until
            BE-->>API: 423 ACCOUNT_LOCKED
        else
            BE-->>API: 401 Invalid credentials + hint
        end
        API-->>C: Error
        C-->>F: { success: false }
    else Email Not Verified
        BE-->>API: 403 EMAIL_NOT_VERIFIED
        API-->>C: Error
        C-->>F: Redirect to verify-email
    else Success
        BE->>DB: Reset failed_login_attempts=0, UPDATE last_login_at
        BE->>DB: INSERT admin_sessions (refresh token hash)
        BE->>DB: INSERT security_log (LOGIN_SUCCESS)
        BE->>DB: Load org permissions
        BE-->>API: 200 { admin, hall, accessToken, refreshToken }
        API-->>C: Response data
        C->>C: setUser(admin), setCinemaHall(hall)
        C-->>F: { success: true }
        F->>A: Redirect to dashboard
    end
```

## 2. Admin Registration Flow

```mermaid
sequenceDiagram
    actor A as Admin
    participant F as RegisterForm
    participant C as AuthContext
    participant API as authAPI.js
    participant BE as Express Backend
    participant DB as PostgreSQL
    participant Mail as Nodemailer
    
    A->>F: Fill name, email, password, phone
    F->>F: Client-side password validation
    F->>C: register(data)
    C->>API: authAPI.register(data)
    API->>BE: POST /api/auth/register
    
    BE->>DB: Check email uniqueness
    alt Email Exists
        BE-->>API: 409 Conflict
    else Valid
        BE->>DB: INSERT cinema_admin_user (bcrypt hash, 12 rounds)
        BE->>DB: INSERT admin_verification_tokens (SHA-256 hash)
        BE->>Mail: sendAdminVerificationEmail(admin.email, verificationLink)
        BE->>DB: INSERT security_log (REGISTER)
        BE-->>API: 201 { message, admin }
        API-->>C: Success
        C-->>F: { success: true }
        F->>A: "Check email to verify"
    end
    
    A->>A: Open email, click link
    A->>BE: GET /api/auth/verify-email?token=xxx
    BE->>DB: SELECT token hash
    alt Valid Token
        BE->>DB: UPDATE email_verified=TRUE
        BE->>DB: DELETE used tokens
        BE-->>A: "Email verified! You can now log in."
    else Invalid/Expired
        BE-->>A: Error page
    end
```

## 3. Admin OAuth Login Flow (Google)

```mermaid
sequenceDiagram
    actor A as Admin
    participant F as LoginForm
    participant C as AuthContext
    participant API as authAPI.js
    participant BE as Express Backend
    participant DB as PostgreSQL
    participant Google as Google API
    
    A->>F: Click "Sign in with Google"
    F->>Google: Google OAuth popup
    Google-->>F: idToken / accessToken
    F->>C: googleLogin(idToken)
    C->>API: authAPI.googleLogin(idToken)
    API->>BE: POST /api/auth/google-login
    
    BE->>Google: verifyGoogleToken(idToken)
    Google-->>BE: { email, name, googleId, picture }
    
    BE->>DB: SELECT admin by email
    alt New Account
        BE->>DB: INSERT cinema_admin_user (OAuth, verified)
        BE->>DB: INSERT security_log (REGISTER_GOOGLE)
    else Existing Account (no Google linked)
        BE->>DB: UPDATE link Google provider
        BE->>DB: INSERT security_log (LINK_GOOGLE)
    else Existing Google Account
        BE->>DB: UPDATE avatar
    end
    
    BE->>DB: INSERT admin_sessions
    BE-->>API: 200 { admin, hall, tokens }
    API-->>C: Response
    C->>F: { success: true }
```

## 4. Customer Signup with OTP Flow

```mermaid
sequenceDiagram
    actor U as Customer
    participant M as LoginModal
    participant C as CustomerAuthContext
    participant API as customerAuthAPI.js
    participant BE as Express Backend
    participant DB as PostgreSQL
    participant Mail as Nodemailer
    
    U->>M: Fill signup form
    M->>M: Password policy validation
    M->>C: signup(data)
    C->>API: authAPI.signup(data)
    API->>BE: POST /api/customer/signup
    BE->>DB: INSERT customers (bcrypt)
    BE-->>API: 201 { message, customer }
    API-->>C: Success
    
    M->>API: customerAuthAPI.sendOtp(email, 'signup')
    API->>BE: POST /api/otp/send
    BE->>DB: INSERT/UPDATE otp_verifications (SHA-256 OTP)
    BE->>Mail: sendCustomerOtpEmail(email, otp)
    BE-->>API: Success
    API-->>M: OTP sent
    
    U->>M: Enter 6-digit OTP
    M->>API: customerAuthAPI.verifyOtp(email, otp, 'signup')
    API->>BE: POST /api/otp/verify
    BE->>DB: Verify OTP hash + expiry + attempts
    alt Valid OTP
        BE->>DB: UPDATE customers SET is_verified=TRUE
        BE-->>API: Success
        API-->>M: Verification complete
        M->>U: "Account created!"
    else Invalid OTP
        BE->>DB: Increment otp_attempts
        BE-->>API: Error
        API-->>M: "Invalid OTP. X attempts remaining."
    end
```

## 5. Password Reset Flow (Customer)

```mermaid
sequenceDiagram
    actor U as Customer
    participant P as ForgotPassword Page
    participant API as customerAuthAPI.js
    participant BE as Express Backend
    participant DB as PostgreSQL
    participant Mail as Nodemailer
    
    U->>P: Enter email
    P->>API: forgotPassword(email)
    API->>BE: POST /api/customer/forgot-password
    
    BE->>DB: Check rate limit (3 per 10 min)
    BE->>DB: Generate OTP, SHA-256 hash, store
    BE->>Mail: sendCustomerOtpEmail(email, otp, 'password_reset')
    BE-->>API: Generic success (don't reveal if email exists)
    API-->>P: "If account exists, OTP sent"
    
    U->>P: Enter OTP + new password
    P->>API: resetPassword(email, otp, newPassword)
    API->>BE: POST /api/customer/reset-password
    
    BE->>DB: SELECT otp_verifications
    BE->>DB: Verify OTP hash
    alt OTP Valid
        BE->>DB: Ensure new != old password
        BE->>DB: UPDATE password (bcrypt)
        BE->>DB: REVOKE all customer_sessions
        BE-->>API: 200 { message }
        API-->>P: Success
        U->>U: Login with new password
    else OTP Invalid/Expired
        BE-->>API: Error with code
        API-->>P: Error message
    end
```

## 6. Session Revocation Flow

```mermaid
sequenceDiagram
    actor A as Admin
    participant FE as Frontend
    participant BE as Express Backend
    participant DB as PostgreSQL
    
    A->>FE: Change password
    FE->>BE: POST /api/auth/change-password
    BE->>DB: Verify current password
    BE->>DB: UPDATE password (bcrypt)
    
    alt Has Refresh Token
        BE->>DB: UPDATE admin_sessions SET is_revoked=TRUE WHERE token_hash != current
    else No Token
        BE->>DB: UPDATE admin_sessions SET is_revoked=TRUE WHERE admin_id = X
    end
    
    BE-->>FE: { message }
    
    Note over A,DB: Other devices now have revoked sessions
    Note over A,DB: Next API call from another device fails with 401
    
    alt Auto-Logout (other device)
        OtherDevice->>BE: Any API call (e.g., GET /api/auth/me)
        BE->>BE: verifyCinemaAdminAccessToken (still valid 1d)
        BE-->>OtherDevice: Data (still works until accessToken expires)
    end
    
    alt Refresh triggers revocation check
        OtherDevice->>BE: POST /api/auth/refresh
        BE->>DB: Check is_revoked flag
        DB-->>BE: is_revoked = TRUE
        BE-->>OtherDevice: 401 "Session has been revoked"
        OtherDevice->>OtherDevice: Force logout, redirect to login
    end
```
