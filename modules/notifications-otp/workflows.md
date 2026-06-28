# Notifications & OTP - Workflows

## 1. Send OTP (Signup)

```mermaid
sequenceDiagram
    actor C as Customer
    participant FE as User App
    participant API as otp.Controller
    participant DB as PostgreSQL
    participant Mail as mail/emails.js
    participant SMTP as Gmail SMTP

    C->>FE: Submit signup form
    FE->>API: POST /api/otp/send { email, type: "signup" }
    API->>DB: SELECT id, name, email FROM customers WHERE email = $1
    DB-->>API: Customer found
    API->>DB: SELECT COUNT(*) FROM otp_verifications WHERE email=$1 AND type=$2 AND created_at > $3
    DB-->>API: count < 3 (within rate limit)
    API->>API: Generate 6-digit OTP + SHA-256 hash
    API->>DB: INSERT INTO otp_verifications ... ON CONFLICT DO UPDATE
    DB-->>API: Upserted
    API->>Mail: sendCustomerOtpEmail(email, name, plainOtp, "signup")
    Mail->>SMTP: Send branded HTML email with OTP
    SMTP-->>Mail: Delivered
    Mail-->>API: Success
    API-->>FE: 200 { message: "OTP sent successfully" }
    FE-->>C: Show OTP input screen
```

## 2. Send OTP (Password Reset — Enumeration Protection)

```mermaid
sequenceDiagram
    actor C as Customer
    participant FE as User App
    participant API as otp.Controller
    participant DB as PostgreSQL

    C->>FE: Enter email on forgot-password page
    FE->>API: POST /api/otp/send { email, type: "password_reset" }
    API->>DB: SELECT id, name, email FROM customers WHERE email = $1
    DB-->>API: No rows (email unknown)
    API-->>FE: 200 { message: "If an account with that email exists, an OTP has been sent." }
    FE-->>C: Show generic success message
    Note over C,API: No distinction between known/unknown email — prevents user enumeration
```

## 3. Verify OTP (Signup — Account Activation)

```mermaid
sequenceDiagram
    actor C as Customer
    participant FE as User App
    participant API as otp.Controller
    participant DB as PostgreSQL

    C->>FE: Enter 6-digit OTP
    FE->>API: POST /api/otp/verify { email, otp, type: "signup" }
    API->>DB: SELECT * FROM otp_verifications WHERE email=$1 AND type=$2
    DB-->>API: OTP record
    API->>API: Check is_verified? No. Expired? No. Attempts >= 5? No.
    API->>API: Hash input OTP, compare with stored hash
    Note over API: Hash matches
    API->>DB: UPDATE otp_verifications SET is_verified = true WHERE id = $1
    API->>DB: UPDATE customers SET is_verified = true WHERE email = $1
    DB-->>API: Account activated
    API-->>FE: 200 { message: "OTP verified successfully. Account activated!" }
    FE-->>C: Redirect to login / show success
```

## 4. Verify OTP — Wrong Attempts

```mermaid
sequenceDiagram
    actor C as Customer
    participant API as otp.Controller
    participant DB as PostgreSQL

    C->>API: POST /api/otp/verify { email, otp: "000000" }
    API->>DB: SELECT * FROM otp_verifications WHERE email=$1 AND type=$2
    DB-->>API: OTP record (attempts: 2)
    API->>API: Hash "000000", compare with stored hash
    Note over API: Hash mismatch
    API->>DB: UPDATE otp_verifications SET otp_attempts = otp_attempts + 1 WHERE id = $1
    DB-->>API: Attempts now 3
    API-->>C: 400 { error: "Invalid OTP. 2 attempts remaining." }

    Note over C,API: After 5 wrong attempts:
    API-->>C: 400 { code: "OTP_ATTEMPTS_EXCEEDED", error: "Too many incorrect attempts. Please request a new OTP." }
```

## 5. OTP Expired Flow

```mermaid
sequenceDiagram
    actor C as Customer
    participant API as otp.Controller
    participant DB as PostgreSQL

    C->>API: POST /api/otp/verify { email, otp, type }
    API->>DB: SELECT * FROM otp_verifications WHERE email=$1 AND type=$2
    DB-->>API: OTP record (expires_at < now())
    API-->>C: 400 { code: "OTP_EXPIRED", error: "OTP has expired. Please request a new one." }
    C->>API: POST /api/otp/send { email, type }
    Note over C,API: Request new OTP (upserts old record)
    API-->>C: 200 { message: "OTP sent successfully" }
```

## 6. Admin Account Locked Email

```mermaid
sequenceDiagram
    participant Auth as Auth Controller
    participant Mail as mail/emails.js
    participant SMTP as Gmail SMTP

    Auth->>Auth: Detect 5th failed login attempt
    Auth->>DB: UPDATE cinema_admin_user SET account_locked_until = $1
    Auth->>Mail: sendAdminAccountLockedEmail(email, name, lockedUntil)
    Mail->>SMTP: Send "Your CineMax Admin account has been locked"
    SMTP-->>Mail: Delivered
    Note over Mail: Non-fatal — logged but does not throw
```

## 7. Admin Password Changed Notification

```mermaid
sequenceDiagram
    participant Auth as Auth Controller
    participant Mail as mail/emails.js
    participant SMTP as Gmail SMTP

    Auth->>Auth: Password change successful
    Auth->>DB: UPDATE cinema_admin_user SET password = $1, password_changed_at = now()
    Auth->>Mail: sendAdminPasswordChangedEmail(email, name)
    Mail->>SMTP: Send "Your CineMax Admin password was changed"
    SMTP-->>Mail: Delivered
    Note over Mail: Non-fatal — logged but does not throw
```
