# Backend API Documentation

## Overview

The Cinema Hall Ticket Booking backend is built with **Express.js** and **PostgreSQL (via Neon)**, providing RESTful APIs for both cinema administrators and end-users. The system supports JWT-based authentication, role-based access control, and comprehensive cinema management features.

**Tech Stack:**

- **Runtime**: Node.js with Express.js
- **Database**: PostgreSQL — Neon serverless (production), local PostgreSQL 18 via pgAdmin (development)
- **Authentication**: JWT with HttpOnly cookies (access + refresh tokens)
- **Deployment**: Vercel-ready with local development support
- **Monitoring**: Sentry (`@sentry/node`) for error tracking and performance traces
- **Logging**: Winston — JSON in production (Vercel Function Logs), colorized in development

---

## Database Schema

### Entity Relationship Diagram

```mermaid
erDiagram
    cinema_admin_user ||--o{ organizations : "owns"
    organizations ||--o{ organization_members : "has"
    cinema_admin_user ||--o{ organization_members : "member of"
    organizations ||--o{ roles : "defines"
    roles ||--o{ role_permissions : "has"
    permissions ||--o{ role_permissions : "granted to"
    organization_members ||--o{ hall_assignments : "assigned to"
    cinema_hall ||--o{ hall_assignments : "has"
    organizations ||--o{ cinema_hall : "owns"
    organizations ||--o{ organization_settings : "has"
    cinema_hall ||--o{ hall_settings : "has"
    cinema_admin_user ||--o{ user_settings : "has"
    
    cinema_admin_user ||--o{ admin_verification_tokens : "verifies via"
    cinema_admin_user ||--o{ admin_password_reset_tokens : "resets via"
    cinema_admin_user ||--o{ admin_sessions : "has sessions"
    cinema_admin_user ||--o{ admin_security_logs : "audited by"
    cinema_hall ||--o{ screens : "contains"
    screens ||--o{ shows : "hosts"
    movies ||--o{ shows : "featured in"
    shows ||--o{ show_booked_seats : "has bookings"
    shows ||--o{ bookings : "has bookings"
    shows ||--o{ payment_orders : "has orders"
    customers ||--o{ bookings : "makes"
    customers ||--o{ payment_orders : "creates"
    customers ||--o{ otp_verifications : "verifies"
    customers ||--o{ customer_sessions : "has sessions"
    customers ||--o{ ad_clicks : "clicks"
    ads ||--o{ ad_clicks : "receives"
    offers ||--o{ offer_redemptions : "redeemed via"
    customers ||--o{ offer_redemptions : "uses"
    bookings ||--o| offer_redemptions : "linked to"
    cinema_hall ||--o{ offers : "scoped to (optional)"
    cinema_admin_user ||--o{ offers : "created by"
    organizations ||--o{ audit_logs : "has audit trail"
    cinema_admin_user ||--o{ audit_logs : "actor in"
    cinema_hall ||--o{ audit_logs : "hall context"
    organizations ||--o{ notifications : "has in-app"
    customers ||--o{ notifications : "receives"
    cinema_admin_user ||--o{ notifications : "receives"
    notifications ||--o{ notification_dispatch_log : "dispatch attempts"
    organizations ||--o{ notification_dispatch_log : "scoped"
    customers ||--o{ device_tokens : "device"
    cinema_admin_user ||--o{ device_tokens : "device"
    customers ||--o{ customer_settings : "has"

    organizations {
        uuid id PK
        text name
        text slug UK
        uuid owner_id FK
        text default_timezone
        text default_currency
        boolean is_active
        text plan
        timestamptz created_at
        timestamptz updated_at
    }

    organization_members {
        uuid id PK
        uuid org_id FK
        uuid admin_id FK
        uuid role_id FK
        varchar status
        uuid invited_by FK
        timestamptz invited_at
        timestamptz joined_at
        timestamptz created_at
    }

    roles {
        uuid id PK
        uuid org_id FK
        varchar key
        varchar label
        text description
        boolean is_system
        int permissions_version
        timestamptz created_at
        timestamptz updated_at
    }

    permissions {
        uuid id PK
        varchar key UK
        varchar label
        varchar resource
    }

    role_permissions {
        uuid role_id PK, FK
        uuid permission_id PK, FK
    }

    hall_assignments {
        uuid id PK
        uuid org_member_id FK
        uuid hall_id FK
        varchar scope
        uuid assigned_by FK
        timestamptz created_at
    }

    organization_settings {
        uuid id PK
        uuid org_id FK
        text section
        jsonb value
        int schema_version
        uuid updated_by FK
        timestamptz updated_at
    }

    hall_settings {
        uuid id PK
        uuid hall_id FK
        text section
        jsonb value
        int schema_version
        uuid updated_by FK
        timestamptz updated_at
    }

    user_settings {
        uuid id PK
        uuid admin_id FK
        text section
        jsonb value
        timestamptz updated_at
    }

    cinema_admin_user {
        uuid id PK
        text email UK
        text password "nullable (OAuth-only accounts)"
        text name
        text phone
        text role
        boolean email_verified
        timestamptz email_verified_at
        int failed_login_attempts
        timestamptz account_locked_until
        timestamptz password_changed_at
        timestamptz last_login_at
        text[] auth_providers "e.g. ['local','google','github']"
        jsonb provider_ids "e.g. {google: '123', github: '456'}"
        text avatar "profile picture URL from OAuth provider"
        timestamptz created_at
    }

    admin_verification_tokens {
        uuid id PK
        uuid admin_id FK
        text token_hash UK
        varchar purpose "email_verification | invite"
        timestamptz expires_at
        timestamptz created_at
    }

    admin_password_reset_tokens {
        uuid id PK
        uuid admin_id FK
        text token_hash UK
        boolean used
        timestamptz expires_at
        timestamptz created_at
    }

    admin_sessions {
        uuid id PK
        uuid admin_id FK
        text refresh_token_hash
        text ip_address
        text user_agent
        boolean is_revoked
        timestamptz last_used_at
        timestamptz created_at
    }

    admin_security_logs {
        uuid id PK
        uuid admin_id FK
        text action
        text ip_address
        text user_agent
        jsonb metadata
        timestamptz created_at
    }

    cinema_hall {
        uuid id PK
        uuid admin_id FK
        uuid org_id FK
        text name
        text location
        text district
        text state
        numeric latitude
        numeric longitude
        text phone
        text description
        boolean is_active
        timestamptz created_at
    }

    screens {
        uuid id PK
        uuid cinema_hall_id FK
        text name
        int total_seats
        int premium_seats
        int gold_seats
        int silver_seats
        numeric premium_price
        numeric gold_price
        numeric silver_price
        int rows
        int columns
        text screen_position
        jsonb layout
        timestamptz created_at
    }

    movies {
        uuid id PK
        int tmdb_id
        text title
        text description
        text poster_url
        text backdrop_path
        text trailer_url
        int duration_mins
        text[] genre
        text[] language
        text status
        date release_date
        jsonb cast
        numeric vote_average
        int vote_count
        timestamptz created_at
    }

    shows {
        uuid id PK
        uuid movie_id FK
        uuid screen_id FK
        date show_date
        time start_time
        time end_time
        text status
        text language_version
        jsonb price_override
        timestamptz created_at
    }

    show_booked_seats {
        uuid id PK
        uuid show_id FK
        text seat_id
        text seat_label
        text row_label
        int column_number
        text status
        uuid held_by FK
        timestamptz hold_expires_at
        timestamptz booked_at
        timestamptz created_at
    }

    offers {
        uuid id PK
        varchar code UK
        varchar title
        text description
        varchar discount_type
        numeric discount_value
        numeric max_discount_amount
        numeric min_booking_amount
        boolean is_active
        timestamptz valid_until
        varchar scope
        uuid cinema_hall_id FK
        varchar user_eligibility
        timestamptz user_joined_after
        uuid created_by FK
        timestamptz created_at
    }

    offer_redemptions {
        uuid id PK
        uuid offer_id FK
        uuid customer_id FK
        uuid booking_id FK
        numeric discount_applied
        timestamptz created_at
    }

    notifications {
        uuid id PK
        uuid org_id FK
        uuid customer_id FK "one of customer_id/admin_id NOT NULL"
        uuid admin_id FK
        text event "booking_confirmed, refund_initiated, show_reminder…"
        text title
        text body
        jsonb data "event payload, default {}"
        uuid booking_id FK
        uuid show_id FK
        uuid refund_id FK
        timestamptz read_at
        timestamptz created_at
    }

    notification_dispatch_log {
        uuid id PK
        uuid notification_id FK
        uuid org_id FK
        uuid customer_id FK
        uuid admin_id FK
        text event
        text channel "email|push|in_app|sms|whatsapp"
        text status "queued|sent|delivered|failed|skipped, default queued"
        text qstash_message_id
        text target "email/token used"
        text error
        timestamptz attempted_at
        timestamptz created_at
    }

    device_tokens {
        uuid id PK
        uuid customer_id FK
        uuid admin_id FK
        text token "UNIQUE"
        text platform "web|android|ios"
        timestamptz last_seen_at
        timestamptz created_at
    }

    customer_settings {
        uuid id PK
        uuid customer_id FK "NOT NULL"
        text section
        jsonb value "default {}"
        timestamptz updated_at
    }

    audit_logs {
        uuid id PK
        uuid org_id FK "NOT NULL, ON DELETE CASCADE"
        uuid admin_id FK "ON DELETE SET NULL"
        text actor_name "denormalized snapshot"
        text actor_role_key "denormalized snapshot"
        text action "e.g. offers.create, shows.cancel.bulk"
        text resource_type "e.g. offer, show, hall"
        uuid resource_id "optional"
        text resource_label "human-readable label"
        uuid hall_id FK "ON DELETE SET NULL"
        jsonb metadata "extra fields, default {}"
        text ip_address
        text user_agent
        timestamptz created_at
    }

    bookings {
        uuid id PK
        uuid customer_id FK
        uuid show_id FK
        jsonb seats
        decimal total_amount
        decimal convenience_fee
        decimal gst_amount
        varchar payment_status
        varchar payment_id
        varchar booking_status
        varchar offer_code
        numeric discount_amount
        timestamptz created_at
        timestamptz updated_at
    }

    refunds {
        uuid id PK
        uuid booking_id FK
        varchar payment_id
        varchar razorpay_refund_id
        decimal amount
        varchar refund_status
        timestamptz initiated_at
        timestamptz settled_at
        text failure_reason
        timestamptz created_at
    }

    customers {
        uuid id PK
        text email UK
        text password "nullable (OAuth-only accounts)"
        text name
        text phone
        text district
        text state
        boolean is_verified
        int failed_login_attempts
        timestamptz account_locked_until
        timestamptz last_login_at
        timestamptz password_changed_at
        text[] auth_providers "e.g. ['local','google']"
        jsonb provider_ids "e.g. {google: '123'}"
        text avatar "profile picture URL from OAuth provider"
        timestamptz created_at
        timestamptz updated_at
    }

    customer_sessions {
        uuid id PK
        uuid customer_id FK
        text refresh_token_hash UK
        text ip_address
        text user_agent
        boolean is_revoked
        timestamptz last_used_at
        timestamptz created_at
    }

    payment_orders {
        uuid id PK
        varchar order_id UK
        uuid show_id FK
        uuid customer_id FK
        jsonb seats
        decimal amount
        decimal convenience_fee
        decimal gst_amount
        varchar status
        varchar payment_id
        varchar payment_signature
        varchar offer_code
        numeric discount_amount
        timestamptz created_at
        timestamptz updated_at
    }

    otp_verifications {
        uuid id PK
        text email FK
        text type "signup | password_reset"
        text otp "SHA-256 hashed"
        boolean is_verified
        int otp_attempts
        timestamptz created_at
        timestamptz expires_at
    }

    ads {
        uuid id PK
        varchar title
        text image_url
        text click_url
        varchar placement
        date start_date
        date end_date
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    ad_clicks {
        uuid id PK
        uuid ad_id FK
        uuid customer_id FK
        timestamptz clicked_at
    }
```

### Key Database Features

#### Constraints

- **Unique screen showtime**: Prevents double-booking same screen at same time
- **Show overlap prevention**: Trigger function prevents overlapping shows on same screen
- **Show status values**: `scheduled` | `booking_started` | `in_progress` | `show_ended` | `cancelled`

#### Triggers

- **`prevent_overlapping_shows()`**: Validates show times don't overlap on INSERT/UPDATE
- **`update_updated_at_column()`**: Auto-updates `updated_at` timestamp for customers

#### Data Types

- **Arrays**: `genre[]`, `language[]` for multi-value fields
- **JSONB**: `layout`, `price_override`, `seats` for flexible structured data
- **UUID**: All primary keys use `gen_random_uuid()`

---

## Authentication System

### Admin Authentication Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant DB
    participant JWT

    Client->>API: POST /api/auth/register
    API->>DB: Insert cinema_admin_user
    DB-->>API: Return admin data
    API-->>Client: 201 Created

    Client->>API: POST /api/auth/login
    API->>DB: SELECT admin + hall by email
    DB-->>API: Return admin data
    API->>JWT: Generate access + refresh tokens
    JWT-->>API: Return tokens
    API->>Client: Set HttpOnly cookies
    API-->>Client: 200 OK + admin data

    Client->>API: GET /api/auth/me (with cookies)
    API->>JWT: Verify access token
    JWT-->>API: Decoded payload
    API->>DB: Fetch admin + hall details
    DB-->>API: Return data
    API-->>Client: 200 OK + admin info

    Client->>API: POST /api/auth/refresh (refresh token)
    API->>JWT: Verify refresh token
    JWT-->>API: Valid
    API->>JWT: Generate new access token
    API->>Client: Set new access token cookie
    API-->>Client: 200 OK

    Client->>API: POST /api/auth/logout
    API->>Client: Clear cookies
    API-->>Client: 200 OK
```

### Customer Authentication Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant DB
    participant Email

    Client->>API: POST /api/customer/signup
    API->>DB: Insert customer (is_verified=false)
    DB-->>API: Return customer data
    API-->>Client: 201 Created

    Client->>API: POST /api/otp/send
    API->>DB: Insert OTP record
    API->>Email: Send OTP email
    Email-->>Client: OTP received
    API-->>Client: 200 OK

    Client->>API: POST /api/otp/verify
    API->>DB: Validate OTP + update customer.is_verified
    DB-->>API: Success
    API-->>Client: 200 OK

    Client->>API: POST /api/customer/login
    API->>DB: Validate credentials + check lockout + is_verified
    DB-->>API: Customer data
    API->>DB: INSERT customer_sessions (hashed refresh token)
    API->>Client: Set cusAccessToken + cusRefreshToken
    API-->>Client: 200 OK + customer data

    note over API,DB: Failed login increments failed_login_attempts
    note over API,DB: 5 fails=15min lock, 10=60min, 15=24h; lockout email sent

    Client->>API: POST /api/customer/forgot-password
    API->>DB: Generate + hash OTP (type=password_reset)
    API->>Email: Send OTP email
    API-->>Client: Generic response (no enumeration)

    Client->>API: POST /api/customer/reset-password
    API->>DB: Verify hashed OTP + update password
    API->>DB: Revoke ALL customer_sessions
    API-->>Client: 200 OK

    Client->>API: POST /api/customer/change-password (+ cusAccessToken)
    API->>DB: Verify current password + update
    API->>DB: Revoke OTHER customer_sessions (keep current)
    API-->>Client: 200 OK
```

### Token Strategy

| Token Type       | Cookie Name       | Expiry  | Purpose                              |
| ---------------- | ----------------- | ------- | ------------------------------------ |
| Admin Access     | `accessToken`     | 1 day   | API authentication                   |
| Admin Refresh    | `refreshToken`    | 30 days | Token renewal (hash stored in DB)    |
| Customer Access  | `cusAccessToken`  | 1 day   | API authentication                   |
| Customer Refresh | `cusRefreshToken` | 30 days | Token renewal (hash stored in DB)    |

**Non-cookie clients (mobile app):** `verifyCustomer` and `verifyCustomerRefreshToken` also accept a `Bearer <token>` in the `Authorization` header as a fallback when `cusAccessToken`/`cusRefreshToken` cookies aren't present (httpOnly cookies aren't usable from React Native). `verifyCustomerRefreshToken` additionally accepts the refresh token via `req.body.refreshToken`. To support this, `POST /api/customer/login`, `POST /api/customer/google-login`, and `POST /api/customer/refresh` now also return `accessToken` (and `refreshToken`, for login/google-login) in the JSON body alongside the httpOnly cookies — the cookie remains the source of truth for the web app.

**Security Features:**

- HttpOnly cookies (prevents XSS)
- SameSite policy (production: `None`, dev: `Lax`)
- Secure flag in production
- Bcrypt password hashing (12 rounds)
- Refresh tokens stored as **SHA-256 hashes** in `admin_sessions` / `customer_sessions` — raw token never persisted
- Server-side session revocation — refresh token checked against DB `is_revoked` on every use (both admin and customer)
- **Brute-force lockout** (admin + customer): 5 attempts → 15 min, 10 → 60 min, 15 → 24 hrs; lockout notification email sent
- **Email verification** required before first login (admin: token link; customer: OTP)
- **Password policy** (admin + customer): min 8 chars, uppercase, lowercase, digit, special character; enforced on signup, reset, and change
- Reset/change password revokes all other sessions
- Full security audit log in `admin_security_logs`
- **Customer OTP security**: SHA-256 hashed before storage; max 5 wrong-guess attempts; max 3 sends per 10 minutes per flow type (rate limited)
- **OAuth rate limiting**: Custom in-memory counter — max 10 OAuth attempts per IP per 15-minute window; auto-cleanup every 5 minutes

### OAuth Authentication

The system supports **Google OAuth** (admin + customer) and **GitHub OAuth** (admin only) alongside the traditional email/password flow.

#### OAuth Flow Architecture

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant Backend
    participant Google
    participant GitHub

    note over User,Google: Google OAuth (Implicit Flow)
    User->>Frontend: Click "Google" / "Continue with Google"
    Frontend->>Google: useGoogleLogin() popup
    Google-->>Frontend: access_token
    Frontend->>Backend: POST /google-login {token}
    Backend->>Google: GET userinfo (verify token)
    Google-->>Backend: {email, name, picture, sub}
    Backend->>Backend: Find/create user, set cookies
    Backend-->>Frontend: {admin/customer, tokens}

    note over User,GitHub: GitHub OAuth (Redirect Flow - Admin only)
    User->>Frontend: Click "GitHub"
    Frontend->>GitHub: Redirect to /login/oauth/authorize
    GitHub-->>Frontend: Redirect to /auth/github/callback?code=xxx
    Frontend->>Backend: POST /github-login {code}
    Backend->>GitHub: Exchange code for access_token
    GitHub-->>Backend: access_token
    Backend->>GitHub: GET /user + GET /user/emails
    GitHub-->>Backend: {login, name, avatar, email}
    Backend->>Backend: Find/create user, set cookies
    Backend-->>Frontend: {admin, tokens}
```

#### Account Linking Rules

- **Email matching**: OAuth login matches existing accounts by email. If found, the provider is auto-linked.
- **New accounts**: If no account with that email exists, a new account is created (no password, `auth_providers: ['google']` or `['github']`).
- **Auto-verification**: OAuth accounts are auto-verified (`email_verified = TRUE` for admin, `is_verified = TRUE` for customer).
- **Duplicate prevention**: Partial unique indexes on `(provider_ids->>'google')` and `(provider_ids->>'github')` prevent the same OAuth ID from being linked to multiple accounts.
- **Unlink safety**: Cannot unlink a provider if it would leave the account with no login method (must have password or another provider).
- **Password nullable**: `password` column is nullable to support OAuth-only accounts. Users can later set a password via `/set-password`.

#### Environment Variables

| Variable | App | Description |
| -------- | --- | ----------- |
| `GOOGLE_CLIENT_ID` | Backend | Google OAuth Client ID (for ID token verification) |
| `GITHUB_CLIENT_ID` | Backend | GitHub OAuth App Client ID |
| `GITHUB_CLIENT_SECRET` | Backend | GitHub OAuth App Client Secret |
| `VITE_GOOGLE_CLIENT_ID` | Admin + User Frontend | Google OAuth Client ID (for `@react-oauth/google`) |
| `VITE_GITHUB_CLIENT_ID` | Admin Frontend | GitHub OAuth App Client ID (for redirect URL) |

---

## API Endpoints

### Admin Authentication (`/api/auth`)

| Method | Endpoint               | Auth          | Description                                               |
| ------ | ---------------------- | ------------- | --------------------------------------------------------- |
| POST   | `/register`            | None          | Register admin — sends verification email                 |
| GET    | `/verify-email`        | None          | Verify email via token from link                          |
| POST   | `/resend-verification` | None          | Resend verification email (2-min rate limit)              |
| POST   | `/login`               | None          | Login (blocked if unverified or locked)                   |
| POST   | `/logout`              | None          | Clear cookies + revoke session                            |
| POST   | `/logout-all`          | Access Token  | Revoke ALL sessions for this admin                        |
| GET    | `/me`                  | Access Token  | Get logged-in admin + hall + security fields              |
| POST   | `/refresh`             | Refresh Token | Refresh access token (revocation-checked)                 |
| PATCH  | `/hall`                | Access Token  | Update cinema hall details + coordinates                  |
| POST   | `/forgot-password`     | None          | Send password reset email (generic response always)       |
| POST   | `/reset-password`      | None          | Set new password via reset token (revokes all sessions)   |
| POST   | `/change-password`     | Access Token  | Change password while logged in (revokes other sessions)  |
| POST   | `/google-login`        | None          | Login/register via Google OAuth (access token or ID token) |
| POST   | `/github-login`        | None          | Login/register via GitHub OAuth (authorization code)      |
| POST   | `/link-provider`       | Access Token  | Link a new OAuth provider to existing account             |
| POST   | `/unlink-provider`     | Access Token  | Unlink an OAuth provider (requires password or 2+ providers) |
| POST   | `/set-password`        | Access Token  | Set password for OAuth-only accounts (no current password) |
| GET    | `/security`            | Access Token  | Get security info: sessions, logs, lockout, verified status |
| GET    | `/admins`              | SuperAdmin    | List all cinema hall admins with hall info                |
| GET    | `/admins/:id/logs`     | SuperAdmin    | Get security audit logs for a specific admin              |

#### POST `/api/auth/register`

Registers a new admin account. Sets `email_verified = FALSE` and sends a verification email. Password must meet the policy (8+ chars, uppercase, lowercase, digit, special character).

**Request Body:**

```json
{
  "name": "John Doe",
  "email": "admin@cinema.com",
  "password": "SecurePass@1",
  "phone": "+1234567890"
}
```

**Response (201):**

```json
{
  "message": "Account created. Please check your email to verify your account.",
  "admin": {
    "id": "uuid",
    "name": "John Doe",
    "email": "admin@cinema.com",
    "phone": "+1234567890",
    "created_at": "2024-01-29T10:00:00Z"
  }
}
```

#### GET `/api/auth/verify-email?token=<token>`

Verifies email using the token from the verification link. Token is SHA-256 hashed and looked up in `admin_verification_tokens`. Atomically marks `email_verified = TRUE` and deletes the token.

**Response (200):** `{ "message": "Email verified successfully. You can now log in." }`

**Error codes**: `INVALID_TOKEN` (400), `TOKEN_EXPIRED` (400)

#### POST `/api/auth/resend-verification`

Resends a verification email. Rate-limited to one email per 2 minutes. Always returns the same generic response whether or not the account exists, to prevent enumeration.

**Request Body:** `{ "email": "admin@cinema.com" }`

**Response (200):** `{ "message": "If an unverified account with that email exists, a verification email has been sent." }`

#### POST `/api/auth/forgot-password`

Sends a password reset link via email. Token valid for 15 minutes. Only sent if account exists AND is email-verified. Always returns a generic response to prevent user enumeration.

**Request Body:** `{ "email": "admin@cinema.com" }`

**Response (200):** `{ "message": "If an account with that email exists, a password reset link has been sent." }`

#### POST `/api/auth/reset-password`

Resets password using the token from the reset link. Prevents reuse of the same password. Revokes ALL sessions on success (forces re-login everywhere).

**Request Body:** `{ "token": "<raw-token>", "newPassword": "NewPass@1" }`

**Error codes**: `INVALID_TOKEN`, `TOKEN_USED`, `TOKEN_EXPIRED`

**Response (200):** `{ "message": "Password reset successfully. Please log in with your new password." }`

#### POST `/api/auth/change-password`

Changes password for the currently logged-in admin. Verifies the current password, enforces the new password policy, and revokes all **other** sessions (current session remains active).

**Request Body:** `{ "currentPassword": "OldPass@1", "newPassword": "NewPass@2" }`

**Response (200):** `{ "message": "Password changed successfully." }`

#### POST `/api/auth/logout-all`

Revokes ALL active sessions for the admin. Clears cookies. Admin must re-login on all devices.

**Response (200):** `{ "message": "Signed out from all devices." }`

#### GET `/api/auth/security`

Returns a comprehensive security snapshot for the logged-in admin.

**Response (200):**

```json
{
  "emailVerified": true,
  "emailVerifiedAt": "2026-05-31T10:00:00Z",
  "failedLoginAttempts": 0,
  "accountLockedUntil": null,
  "passwordChangedAt": "2026-05-31T10:00:00Z",
  "lastLoginAt": "2026-05-31T10:00:00Z",
  "activeSessions": [
    { "id": "uuid", "ip_address": "1.2.3.4", "user_agent": "...", "created_at": "...", "last_used_at": "..." }
  ],
  "recentLogs": [
    { "action": "LOGIN_SUCCESS", "ip_address": "1.2.3.4", "metadata": {}, "created_at": "..." }
  ]
}
```

#### PATCH `/api/auth/hall`

Updates the logged-in admin's cinema hall details. Requires `Access Token`.

**Request Body:**

```json
{
  "hall_name": "Grand Cinema",
  "hall_location": "Downtown Plaza, 1st Floor",
  "hall_district": "Mumbai",
  "hall_state": "Maharashtra",
  "latitude": 19.076090,
  "longitude": 72.877426
}
```

**Response (200):**

```json
{
  "message": "Cinema hall updated successfully.",
  "hall": {
    "id": "uuid",
    "name": "Grand Cinema",
    "location": "Downtown Plaza, 1st Floor",
    "district": "Mumbai",
    "state": "Maharashtra",
    "latitude": 19.07609,
    "longitude": 72.877426,
    "created_at": "2024-01-29T10:00:00Z"
  }
}
```

#### POST `/api/auth/login`

**Request Body:**

```json
{
  "email": "admin@cinema.com",
  "password": "securepass123"
}
```

**Response (200):**

```json
{
  "message": "Login successful",
  "accessToken": "jwt-token",
  "refreshToken": "jwt-refresh-token",
  "admin": {
    "id": "uuid",
    "name": "John Doe",
    "email": "admin@cinema.com",
    "phone": "+1234567890",
    "role": "admin",
    "email_verified": true,
    "created_at": "2024-01-29T10:00:00Z"
  },
  "hall": { "..." }
}
```

**Error codes:**

| HTTP | Code | Condition |
|------|------|-----------|
| 401  | — | Wrong password / unknown email |
| 403  | `EMAIL_NOT_VERIFIED` | Account not yet verified |
| 423  | `ACCOUNT_LOCKED` | Too many failed attempts; includes `lockedUntil` timestamp |
```

#### POST `/api/auth/google-login`

Authenticates an admin using a Google OAuth access token (or ID token). If the email matches an existing admin, links Google as a provider and logs in. If no account exists, creates a new admin with `auth_providers: ['google']` and no password (OAuth-only account). Email is auto-verified. Rate-limited: 10 attempts per IP per 15 minutes.

**Request Body:**

```json
{
  "token": "<google-access-token-or-id-token>"
}
```

**Response (200):**

```json
{
  "message": "Login successful",
  "admin": { "id": "uuid", "name": "...", "email": "...", "role": "admin", "auth_providers": ["google"], "avatar": "https://..." },
  "hall": null
}
```

**Errors:** `429` if rate-limited, `401` if token invalid.

#### POST `/api/auth/github-login`

Authenticates an admin using a GitHub authorization code (OAuth redirect flow). Backend exchanges the code for an access token, fetches user profile + verified email. Same account creation/linking logic as Google.

**Request Body:**

```json
{
  "code": "<github-authorization-code>"
}
```

**Response (200):** Same shape as `/google-login`.

**Errors:** `429` if rate-limited, `401` if code exchange fails or no verified email.

#### POST `/api/auth/link-provider`

Links a new OAuth provider (Google or GitHub) to an existing authenticated admin account. Prevents linking if the provider email doesn't match the admin email or if the provider is already linked to another account.

**Request Body (Google):**

```json
{
  "provider": "google",
  "token": "<google-access-token>"
}
```

**Request Body (GitHub):**

```json
{
  "provider": "github",
  "code": "<github-authorization-code>"
}
```

**Response (200):**

```json
{
  "message": "google linked successfully",
  "auth_providers": ["local", "google"]
}
```

#### POST `/api/auth/unlink-provider`

Removes an OAuth provider from the admin's account. Requires that the admin either has a password set or has at least one other provider remaining (cannot leave account with no login method).

**Request Body:**

```json
{
  "provider": "google"
}
```

**Response (200):**

```json
{
  "message": "google unlinked successfully",
  "auth_providers": ["local"]
}
```

#### POST `/api/auth/set-password`

Sets a password for OAuth-only accounts that have no existing password. Enforces the standard password policy. Adds `'local'` to `auth_providers`.

**Request Body:**

```json
{
  "newPassword": "SecurePass@1"
}
```

**Response (200):** `{ "message": "Password set successfully" }`

**Error:** `400` if the account already has a password (use `/change-password` instead).

---

### Cinema Halls Management (`/api/halls`)

All endpoints require **Admin** authentication (verified via `verifyCinemaAdminAccessToken`). Halls are scoped to the admin's organization — superAdmin sees their org's halls, not all platform halls.

| Method | Endpoint | Auth | Description |
| ------ | -------- | ---- | ----------- |
| GET    | `/`      | Admin | Get cinema halls scoped to the admin's organization |
| POST   | `/`      | Admin | Create a new cinema hall |
| PUT    | `/:id`   | Admin | Update an existing cinema hall (must own the hall) |
| DELETE | `/:id`   | Admin | Delete a cinema hall (cascades to screens/shows/bookings) |

#### GET `/api/halls`

Returns halls scoped to the authenticated admin's organization (superAdmin included).

**Response (200):**

```json
{
  "halls": [
    {
      "id": "uuid",
      "admin_id": "uuid",
      "name": "PVR Cinemas",
      "location": "Mall Road, Anna Nagar",
      "district": "Chennai",
      "state": "Tamil Nadu",
      "latitude": 13.0827,
      "longitude": 80.2707,
      "phone": "9876543210",
      "description": "Premium multi-screen theater",
      "is_active": true,
      "created_at": "2026-05-24T10:00:00Z"
    }
  ]
}
```

#### POST `/api/halls`

Creates a new cinema hall for the authenticated admin.

**Request Body:**

```json
{
  "name": "PVR Cinemas",
  "location": "Mall Road, Anna Nagar",
  "district": "Chennai",
  "state": "Tamil Nadu",
  "latitude": 13.0827,
  "longitude": 80.2707,
  "phone": "9876543210",
  "description": "Premium multi-screen theater"
}
```

**Response (201):**

```json
{
  "hall": {
    "id": "uuid",
    "name": "PVR Cinemas",
    "location": "Mall Road, Anna Nagar",
    "district": "Chennai",
    "state": "Tamil Nadu",
    "latitude": 13.0827,
    "longitude": 80.2707,
    "phone": "9876543210",
    "description": "Premium multi-screen theater",
    "is_active": true,
    "created_at": "2026-05-24T10:00:00Z"
  }
}
```

#### PUT `/api/halls/:id`

Updates details of a specific cinema hall. The admin must own the hall.

**Request Body (all fields optional):**

```json
{
  "name": "PVR Cinemas Updated",
  "location": "Mall Road, Anna Nagar",
  "district": "Chennai",
  "state": "Tamil Nadu",
  "latitude": 13.0827,
  "longitude": 80.2707,
  "phone": "9876543210",
  "description": "Premium multi-screen theater",
  "is_active": false
}
```

**Response (200):**

```json
{
  "hall": {
    "id": "uuid",
    "name": "PVR Cinemas Updated",
    "location": "Mall Road, Anna Nagar",
    "district": "Chennai",
    "state": "Tamil Nadu",
    "latitude": 13.0827,
    "longitude": 80.2707,
    "phone": "9876543210",
    "description": "Premium multi-screen theater",
    "is_active": false,
    "created_at": "2026-05-24T10:00:00Z"
  }
}
```

#### DELETE `/api/halls/:id`

Deletes a specific cinema hall. The admin must own the hall. This action cascades and deletes all screens, shows, bookings, and refund records belonging to this hall.

**Response (200):**

```json
{
  "message": "Hall deleted successfully"
}
```

---

### Customer Authentication (`/api/customer`)

| Method | Endpoint            | Auth           | Description                                                      |
| ------ | ------------------- | -------------- | ---------------------------------------------------------------- |
| POST   | `/signup`           | None           | Register customer (enforces password policy, bcrypt cost 12)     |
| POST   | `/login`            | None           | Login (lockout enforced; hint for remaining attempts)            |
| POST   | `/logout`           | None           | Clear auth cookies + revoke session in DB (accepts refresh token via cookie or `req.body.refreshToken`) |
| GET    | `/me`               | Customer Token | Get logged-in customer info                                      |
| PUT    | `/update`           | Customer Token | Update customer profile (name, phone, location)                  |
| POST   | `/refresh`          | Refresh Token  | Refresh access token (revocation-checked against customer_sessions); also returns `accessToken` in the body |
| POST   | `/forgot-password`  | None           | Send password-reset OTP (generic response, no enumeration)       |
| POST   | `/reset-password`   | None           | Verify OTP + set new password (revokes ALL sessions)             |
| POST   | `/change-password`  | Customer Token | Change password while logged in (revokes other sessions)         |
| POST   | `/google-login`     | None           | Login/register via Google OAuth (access token or ID token)       |
| POST   | `/link-provider`    | Customer Token | Link a new OAuth provider to existing account                    |
| POST   | `/unlink-provider`  | Customer Token | Unlink an OAuth provider (requires password or 2+ providers)     |
| POST   | `/set-password`     | Customer Token | Set password for OAuth-only accounts (no current password)       |

#### POST `/api/customer/signup`

**Request Body:**

```json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "password": "password123",
  "phone": "+9876543210",
  "district": "Pune",
  "state": "Maharashtra"
}
```

**Response (201):**

```json
{
  "message": "Customer registered successfully! Please verify your email with OTP.",
  "customer": {
    "id": "uuid",
    "name": "Jane Smith",
    "email": "jane@example.com",
    "phone": "+9876543210",
    "district": "Pune",
    "state": "Maharashtra",
    "is_verified": false,
    "created_at": "2024-01-29T10:00:00Z"
  }
}
```

#### POST `/api/customer/login`

Returns `423` with `code: 'ACCOUNT_LOCKED'` and `lockedUntil` timestamp when account is locked. Before reaching a lock threshold, returns a `hint` field (e.g. `"2 attempts remaining before account is locked"`).

**Request Body:** `{ "email": "jane@example.com", "password": "MyPass@1" }`

**Response (200):** Sets `cusAccessToken` + `cusRefreshToken` httpOnly cookies, and also returns `accessToken` and `refreshToken` in the body (for non-cookie clients such as the mobile app) alongside `message` and `customer`.

#### POST `/api/customer/forgot-password`

Looks up the customer by email. If found, sends a `password_reset` type OTP via email. Always returns the same generic message regardless of whether the email exists (prevents enumeration).

**Request Body:** `{ "email": "jane@example.com" }`

**Response (200):** `{ "message": "If an account with that email exists, a password reset OTP has been sent." }`

#### POST `/api/customer/reset-password`

Verifies the OTP (type `password_reset`), enforces password policy, checks same-password, updates password, revokes ALL customer sessions, sends password-changed email.

**Request Body:** `{ "email": "jane@example.com", "otp": "482019", "newPassword": "NewPass@1" }`

**Error codes:** `OTP_EXPIRED` (400), `OTP_ATTEMPTS_EXCEEDED` (400)

**Response (200):** `{ "message": "Password reset successfully. Please sign in with your new password." }`

#### POST `/api/customer/change-password`

Verifies current password, enforces policy on new password, prevents reuse, updates password, revokes all *other* sessions (current session stays active), sends password-changed email.

**Request Body:** `{ "currentPassword": "OldPass@1", "newPassword": "NewPass@2" }`

**Response (200):** `{ "message": "Password changed successfully. Other devices have been signed out." }`

#### POST `/api/customer/google-login`

Authenticates a customer using a Google OAuth access token (or ID token). If the email matches an existing customer, links Google as a provider and logs in. If no account exists, creates a new customer with `auth_providers: ['google']`, no password, and `is_verified: true`. Rate-limited: 10 attempts per IP per 15 minutes.

**Request Body:** `{ "token": "<google-access-token-or-id-token>" }`

**Response (200):**

```json
{
  "message": "Login successful",
  "customer": { "id": "uuid", "name": "...", "email": "...", "auth_providers": ["google"], "avatar": "https://..." },
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token"
}
```

Sets `cusAccessToken` + `cusRefreshToken` httpOnly cookies as well; `accessToken`/`refreshToken` in the body are for non-cookie clients (mobile app).

#### POST `/api/customer/link-provider`

Links Google OAuth to an existing authenticated customer account. Provider email must match account email.

**Request Body:** `{ "provider": "google", "token": "<google-access-token>" }`

**Response (200):** `{ "message": "google linked successfully", "auth_providers": ["local", "google"] }`

#### POST `/api/customer/unlink-provider`

Removes an OAuth provider from the customer's account. Requires a password or at least one other provider remaining.

**Request Body:** `{ "provider": "google" }`

**Response (200):** `{ "message": "google unlinked successfully", "auth_providers": ["local"] }`

#### POST `/api/customer/set-password`

Sets a password for OAuth-only customer accounts (no existing password). Enforces password policy. Adds `'local'` to `auth_providers`.

**Request Body:** `{ "newPassword": "SecurePass@1" }`

**Response (200):** `{ "message": "Password set successfully" }`

---

### OTP Verification (`/api/otp`)

| Method | Endpoint  | Auth | Description                                                     |
| ------ | --------- | ---- | --------------------------------------------------------------- |
| POST   | `/send`   | None | Send OTP (type: signup \| password_reset); rate-limited 3/10min |
| POST   | `/verify` | None | Verify OTP; max 5 wrong attempts before invalidation            |
| POST   | `/verify` | None | Verify OTP and mark customer verified |

#### POST `/api/otp/send`

Generates a random 6-digit OTP, hashes it with SHA-256, and stores the hash. Sends the plain OTP to the customer via a cinema-branded email. Rate-limited to **3 sends per 10 minutes** per `(email, type)` pair.

**Request Body:**

```json
{
  "email": "jane@example.com",
  "type": "signup"
}
```

`type` is `"signup"` (default) or `"password_reset"`.

**Response (200):**

```json
{
  "message": "OTP sent successfully"
}
```

#### POST `/api/otp/verify`

Hashes the submitted OTP and compares against the stored hash. Increments `otp_attempts` on mismatch; invalidates after **5 wrong attempts**. For `signup` type, marks `customers.is_verified = true`.

**Request Body:**

```json
{
  "email": "jane@example.com",
  "otp": "482019",
  "type": "signup"
}
```

**Response (200):**

```json
{
  "message": "OTP verified successfully. Account activated!"
}
  }
}
```

---

### Movies Management (`/api/movies`)

| Method | Endpoint           | Auth       | Description                 |
| ------ | ------------------ | ---------- | --------------------------- |
| GET    | `/migrate-backdrops` | None       | Run database schema check & TMDB backdrop backfill |
| GET    | `/proxy-image`       | None       | Proxy TMDB images (validates `url` starts with `https://image.tmdb.org/`) |
| POST   | `/add`             | SuperAdmin | Add new movie               |
| PUT    | `/edit/:movieId`   | SuperAdmin | Edit movie details          |
| DELETE | `/delete/:movieId` | SuperAdmin | Delete movie                |
| GET    | `/`                | None       | Get all movies with filters |
| GET    | `/:id`             | None       | Get single movie by ID      |
| PATCH  | `/:movieId/status` | SuperAdmin | Update movie status         |

#### POST `/api/movies/add`

**Request Body:**

```json
{
  "title": "Inception",
  "description": "A mind-bending thriller",
  "poster_url": "https://example.com/poster.jpg",
  "backdrop_path": "https://example.com/backdrop.jpg",
  "trailer_url": "https://youtube.com/watch?v=xyz",
  "duration_mins": 148,
  "genre": ["Action", "Sci-Fi", "Thriller"],
  "language": ["English", "Hindi"],
  "release_date": "2024-02-15",
  "status": "upcoming",
  "tmdb_id": 27205,
  "vote_average": 8.4,
  "vote_count": 35820,
  "cast": [
    { "name": "Leonardo DiCaprio", "character": "Cobb", "profile_path": "/path.jpg", "order": 0 }
  ]
}
```

**Response (201):**

```json
{
  "id": "uuid",
  "title": "Inception",
  "description": "A mind-bending thriller",
  "poster_url": "https://example.com/poster.jpg",
  "backdrop_path": "https://example.com/backdrop.jpg",
  "trailer_url": "https://youtube.com/watch?v=xyz",
  "duration_mins": 148,
  "genre": ["Action", "Sci-Fi", "Thriller"],
  "language": ["English", "Hindi"],
  "release_date": "2024-02-15",
  "status": "upcoming",
  "tmdb_id": 27205,
  "vote_average": "8.40",
  "vote_count": 35820,
  "cast": [
    { "name": "Leonardo DiCaprio", "character": "Cobb", "profile_path": "/path.jpg", "order": 0 }
  ],
  "created_at": "2024-01-29T10:00:00Z"
}
```

> **Note:** `cast` is a PostgreSQL reserved keyword — the column is stored as `"cast"` (double-quoted) in all SQL queries.

#### GET `/api/movies`

**Query Parameters:**

- `page` (number): Page number (default: 1)
- `limit` (number): Items per page (default: 10)
- `genre` (string[]): Filter by genres (e.g., `?genre=Action&genre=Drama`)
- `language` (string[]): Filter by languages
- `status` (string): Filter by status (`upcoming`, `now_showing`, `ended`)
- `release_date` (date): Filter by release date
- `search` (string): Search in title/description

**Response (200):**

```json
{
  "movies": [
    {
      "id": "uuid",
      "title": "Inception",
      "genre": ["Action", "Sci-Fi"],
      "language": ["English", "Hindi"],
      "status": "now_showing",
      "release_date": "2024-02-15"
    }
  ],
  "page": 1,
  "limit": 10,
  "total": 25
}
```

#### GET `/api/movies/proxy-image`

Proxies TMDB poster/backdrop images through the backend to avoid CORS issues on the frontend. Used by `BookingSuccessPage` and `BookingDetailPage` when displaying poster images from `image.tmdb.org`.

**Query Parameters:**

| Parameter | Type   | Required | Description |
|-----------|--------|----------|-------------|
| `url`     | string | Yes      | Full TMDB image URL (must start with `https://image.tmdb.org/`) |

**Response:** Binary image data with the original `Content-Type` header.

**Validation:** Returns `400` if `url` is missing or doesn't start with `https://image.tmdb.org/`.

---

### TMDB Proxy (`/api/tmdb`)

All endpoints require **Admin** (regular Admin or SuperAdmin) authentication. The backend proxies requests to the TMDB API using a server-side bearer token (`TMDB_API_KEY` env var), so the key is never exposed to the browser.

| Method | Endpoint             | Auth       | Description                                  |
| ------ | -------------------- | ---------- | -------------------------------------------- |
| GET    | `/popular`           | Admin      | Popular movies (paginated)                   |
| GET    | `/now-playing`       | Admin      | Now-playing movies (paginated)               |
| GET    | `/in-theatres`       | Admin      | Theatrical releases in the past 30 days      |
| GET    | `/upcoming`          | Admin      | Upcoming movies (paginated)                  |
| GET    | `/top-rated`         | Admin      | Top-rated movies (paginated)                 |
| GET    | `/search`            | Admin      | Search TMDB by title (`?query=…`)            |
| GET    | `/movie/:tmdbId`     | Admin      | Full movie details with videos + cast        |

#### Common Query Parameters (list endpoints)

| Parameter              | Type   | Description                                  |
| ---------------------- | ------ | -------------------------------------------- |
| `page`                 | number | TMDB page number (default: 1)                |
| `with_original_language` | string | ISO 639-1 language code filter (e.g. `ta`, `hi`) |

#### GET `/api/tmdb/movie/:tmdbId`

Fetches a single movie's full details including trailers and cast via TMDB's `append_to_response=videos,credits`.

**Response structure (relevant fields):**

```json
{
  "id": 27205,
  "title": "Inception",
  "overview": "A thief who steals corporate secrets...",
  "poster_path": "/edv5CZvWj09paQCbCcBnLkk8pYn.jpg",
  "runtime": 148,
  "release_date": "2010-07-16",
  "vote_average": 8.4,
  "vote_count": 35820,
  "videos": {
    "results": [
      { "key": "YoHD9XEInc0", "site": "YouTube", "type": "Trailer", "official": true }
    ]
  },
  "credits": {
    "cast": [
      { "name": "Leonardo DiCaprio", "character": "Cobb", "profile_path": "/path.jpg", "order": 0 }
    ]
  }
}
```

**Import mapping in the admin panel:**

| TMDB field                        | Saved as            |
| --------------------------------- | ------------------- |
| `id`                              | `tmdb_id`           |
| `title`                           | `title`             |
| `overview`                        | `description`       |
| `https://image.tmdb.org/t/p/w500` + `poster_path` | `poster_url` |
| `https://image.tmdb.org/t/p/original` + `backdrop_path` | `backdrop_path` |
| First YouTube Trailer key         | `trailer_url`       |
| `runtime`                         | `duration_mins`     |
| `release_date`                    | `release_date`      |
| `vote_average`                    | `vote_average`      |
| `vote_count`                      | `vote_count`        |
| `credits.cast` (top 10)           | `cast` (JSONB)      |

---

### Screens Management (`/api/screens`)

| Method | Endpoint            | Auth        | Description                      |
| ------ | ------------------- | ----------- | -------------------------------- |
| POST   | `/create`           | Admin Token | Create screen with seat layout   |
| GET    | `/`                 | Admin Token | Get all screens for admin's hall |
| PUT    | `/update/:screenId` | Admin Token | Update screen details            |
| DELETE | `/delete/:screenId` | Admin Token | Delete screen                    |

#### POST `/api/screens/create`

**Request Body:**

```json
{
  "name": "Screen 1",
  "total_seats": 100,
  "premium_seats": 20,
  "gold_seats": 40,
  "silver_seats": 40,
  "premium_price": 500,
  "gold_price": 300,
  "silver_price": 200,
  "rows": 10,
  "columns": 10,
  "screen_position": "top",
  "layout": [
    {
      "id": "A1",
      "row": 0,
      "col": 0,
      "type": "premium",
      "label": "A1",
      "rowLabel": "A",
      "isAisle": false,
      "isEmpty": false
    }
  ]
}
```

**Response (201):**

```json
{
  "id": "uuid",
  "cinema_hall_id": "uuid",
  "name": "Screen 1",
  "total_seats": 100,
  "premium_seats": 20,
  "gold_seats": 40,
  "silver_seats": 40,
  "premium_price": 500,
  "gold_price": 300,
  "silver_price": 200,
  "rows": 10,
  "columns": 10,
  "screen_position": "top",
  "layout": [...],
  "created_at": "2024-01-29T10:00:00Z"
}
```

---

### Shows Management (`/api/shows`)

| Method | Endpoint                | Auth                 | Description                                       |
| ------ | ----------------------- | -------------------- | ------------------------------------------------- |
| POST   | `/create`               | Admin + Screen Owner | Create single show                                |
| POST   | `/bulk`                 | Admin + Screen Owner | Create multiple shows                             |
| PUT    | `/edit/:id`             | Admin + Screen Owner | Edit show details                                 |
| DELETE | `/delete/:id`           | Admin                | Delete single show                                |
| DELETE | `/bulk`                 | Admin                | Bulk delete shows by ID array                     |
| GET    | `/date/:date`           | Admin                | Get shows by date (grouped by movie)              |
| GET    | `/booking-count/:id`    | Admin                | Get confirmed booking count + total refund amount for a show (used by cancel dialog) |
| PUT    | `/booking-status/:id`   | Admin                | Open (`open`), revert (`revert`), or restore (`restore`) booking status |
| PUT    | `/cancel/:id`           | Admin                | Cancel show + cancel bookings + create refund records + initiate Razorpay refunds |
| PUT    | `/bulk-cancel`          | Admin                | Bulk cancel shows + bookings + refund records     |
| PUT    | `/bulk-booking-open`    | Admin                | Bulk open booking for scheduled shows             |
| PUT    | `/bulk-restore`         | Admin                | Bulk restore cancelled shows to scheduled         |
| GET    | `/get/:id`              | None                 | Get show details with seat layout                 |
| POST   | `/book/:showId`         | None                 | Book seats for show                               |

#### POST `/api/shows/create`

> **Note:** `show_date` is automatically normalized to `YYYY-MM-DD` format on the server using `dayjs` — any ISO datetime string (e.g. `2026-03-10T00:00:00Z`) is safely stripped to date-only before insertion.

**Request Body:**

```json
{
  "movie_id": "uuid",
  "screen_id": "uuid",
  "show_date": "2024-02-15",
  "start_time": "14:00:00",
  "end_time": "16:30:00",
  "language_version": "English",
  "price_override": {
    "premium": 600,
    "gold": 350,
    "silver": 250
  }
}
```

**Response (201):**

```json
{
  "id": "uuid",
  "movie_id": "uuid",
  "screen_id": "uuid",
  "show_date": "2024-02-15",
  "start_time": "14:00:00",
  "end_time": "16:30:00",
  "status": "scheduled",
  "language_version": "English",
  "price_override": {
    "premium": 600,
    "gold": 350,
    "silver": 250
  },
  "created_at": "2024-01-29T10:00:00Z"
}
```

#### POST `/api/shows/bulk`

**Request Body:**

```json
{
  "movie_id": "uuid",
  "screen_id": "uuid",
  "dates": ["2024-02-15", "2024-02-16", "2024-02-17"],
  "start_time": "14:00:00",
  "end_time": "16:30:00",
  "language_version": "English"
}
```

**Response (201):**

```json
{
  "message": "3 shows created successfully",
  "shows": [...]
}
```

#### GET `/api/shows/date/:date`

**Response (200):**

```json
{
  "date": "2024-02-15",
  "movies": [
    {
      "movie_id": "uuid",
      "title": "Inception",
      "poster_url": "...",
      "shows": [
        {
          "show_id": "uuid",
          "screen_name": "Screen 1",
          "start_time": "14:00:00",
          "end_time": "16:30:00",
          "language_version": "English"
        }
      ]
    }
  ]
}
```

#### PUT `/api/shows/booking-status/:id`

Opens, reverts, or restores booking availability for a show. Admin only.

**Request Body:**

```json
{ "action": "open" }
```

| `action` value | From status | To status | Condition |
|---|---|---|---|
| `"open"` | `scheduled` | `booking_started` | Always allowed |
| `"revert"` | `booking_started` | `scheduled` | Only if zero confirmed bookings exist |
| `"restore"` | `cancelled` | `scheduled` | Always allowed |

**Response (200):**

```json
{ "message": "Booking opened successfully", "status": "booking_started" }
```

Returns `400` if the action is invalid or the show is in the wrong state. For `revert`, also returns `400` if confirmed bookings already exist.

#### GET `/api/shows/booking-count/:id`

Returns confirmed booking count and total refund amount for a show. Used by the admin cancel dialog to warn before proceeding. Requires `verifyCinemaHall`.

**Response (200):**

```json
{ "booking_count": 3, "total_amount": 1305.60 }
```

#### PUT `/api/shows/cancel/:id`

Cancels a show. Admin only. This action (all DB steps in a single atomic transaction):
1. Sets `shows.status = 'cancelled'`
2. Sets `bookings.booking_status = 'cancelled'` for all bookings with `payment_status = 'completed'`
3. Inserts a row into `refunds` per booking (`refund_status = 'initiated'`)

Then outside the transaction, for each booking:
- Calls `razorpay.payments.refund(payment_id, {})` and stores the returned `razorpay_refund_id`
- On failure: updates `refunds.refund_status = 'failed'` and stores `failure_reason`

Returns `400` if the show is already `cancelled` or `show_ended`.

**Response (200):**

```json
{
  "message": "Show cancelled successfully",
  "bookings_cancelled": 3,
  "refunds": [
    { "payment_id": "pay_xxx", "status": "refund_initiated" }
  ]
}
```

#### DELETE `/api/shows/bulk`

Bulk-delete multiple shows. Admin only.

**Request Body:**

```json
{ "ids": ["uuid1", "uuid2"] }
```

**Response (200):** `{ "message": "Shows deleted" }`

#### PUT `/api/shows/bulk-cancel`

Bulk cancel shows. Each show is processed in its own transaction. Skips shows already `cancelled` or `show_ended`. Creates `refunds` records and initiates Razorpay refunds for any paid bookings (`payment_status = 'completed'`).

**Request Body:**

```json
{ "ids": ["uuid1", "uuid2"] }
```

**Response (200):**

```json
{
  "message": "2 of 3 show(s) cancelled",
  "results": [
    { "id": "uuid1", "success": true, "bookings_cancelled": 2 },
    { "id": "uuid2", "success": true, "bookings_cancelled": 0 },
    { "id": "uuid3", "success": false, "error": "Show already ended" }
  ]
}
```

#### PUT `/api/shows/bulk-booking-open`

Bulk open booking for shows. Only affects shows with `status = 'scheduled'`; skips others.

**Request Body:**

```json
{ "ids": ["uuid1", "uuid2"] }
```

**Response (200):**

```json
{
  "message": "Booking opened for 2 of 2 show(s)",
  "results": [{ "id": "uuid1", "success": true }, { "id": "uuid2", "success": true }]
}
```

#### PUT `/api/shows/bulk-restore`

Bulk restore cancelled shows back to `scheduled`. Only affects shows with `status = 'cancelled'`; skips others.

**Request Body:**

```json
{ "ids": ["uuid1", "uuid2"] }
```

**Response (200):**

```json
{
  "message": "2 of 2 show(s) restored to scheduled",
  "results": [{ "id": "uuid1", "success": true }, { "id": "uuid2", "success": true }]
}
```

#### Background Job — `updateShowStatuses`

Runs every 30 seconds via the server's background job. Automatically transitions show statuses based on the current IST time.

| Transition | Condition |
|---|---|
| `booking_started` → `in_progress` | `start_time` has passed AND actual end hasn't |
| `in_progress` → `show_ended` | Actual end timestamp has passed |
| `booking_started` → `show_ended` | End passed without ever entering `in_progress` |
| `scheduled` → `show_ended` | End passed without ever opening for booking |

> **Midnight-crossing shows:** Shows that run past midnight (e.g. 10:30 PM + 3h 49m → 2:19 AM) have `end_time < start_time`. The job detects this and computes the actual end timestamp as `show_date + 1 day + end_time`, preventing premature `show_ended` transitions.
>
> ```sql
> CASE WHEN end_time < start_time
>   THEN (show_date + INTERVAL '1 day')::timestamp + end_time
>   ELSE show_date::timestamp + end_time
> END
> ```

---

### User Movies (`/api/user/movies`)

| Method | Endpoint                 | Auth | Description                             |
| ------ | ------------------------ | ---- | --------------------------------------- |
| GET    | `/`                      | None | Get all movies with filters             |
| GET    | `/:id`                   | None | Get movie by ID                         |
| GET    | `/location/movies`       | None | Get movies by district + state          |
| GET    | `/state/movies`          | None | Get movies by state                     |
| GET    | `/:movieId/showtimes`    | None | Get movie with cinema halls + showtimes for a date |
| GET    | `/location/districts`    | None | Get districts in state                  |
| GET    | `/location/cinema-halls` | None | Get cinema halls in location            |
| GET    | `/location/theatres`     | None | Get cinema halls with movies + shows for a date |

#### GET `/api/user/movies/location/movies`

**Query Parameters:**

- `district` (string): District name
- `state` (string): State name

**Response (200):**

```json
{
  "movies": [
    {
      "id": "uuid",
      "title": "Inception",
      "genre": ["Action", "Sci-Fi"],
      "language": ["English", "Hindi"],
      "poster_url": "...",
      "status": "now_showing",
      "vote_average": "8.40",
      "vote_count": 35820
    }
  ]
}
```

`GET /api/user/movies/state/movies` returns the same shape (movies filtered by `state` only, no `district`).

#### GET `/api/user/movies/:movieId/showtimes`

Returns movie details with cinema halls and showtimes filtered to a specific date. Used by `MovieDetailsPage`.

**Query Parameters:**

- `district` (string, required): District name
- `state` (string, required): State name
- `date` (string, optional): Date in `YYYY-MM-DD` format — defaults to today if omitted

**Response (200):**

```json
{
  "movie": {
    "id": "uuid",
    "title": "Inception",
    "description": "...",
    "poster_url": "...",
    "duration_mins": 148
  },
  "cinema_halls": [
    {
      "cinema_hall_id": "uuid",
      "cinema_hall_name": "Grand Cinema",
      "cinema_hall_location": "Downtown Plaza",
      "district": "Mumbai",
      "state": "Maharashtra",
      "latitude": 19.07609,
      "longitude": 72.877426,
      "shows": [
        {
          "show_id": "uuid",
          "screen_id": "uuid",
          "screen_name": "Screen 1",
          "show_date": "2026-03-08",
          "start_time": "14:00:00",
          "end_time": "16:30:00",
          "language_version": "English",
          "show_status": "scheduled",
          "pricing": { "premium": 200, "gold": 150, "silver": 120 }
        }
      ]
    }
  ]
}
```

#### GET `/api/user/movies/location/theatres`

Returns all cinema halls in a location for a specific date, with their movies and showtimes grouped hierarchically. Used by TheatresPage.

**Query Parameters:**

- `district` (string, required): District name
- `state` (string, required): State name
- `date` (string, optional): Date in `YYYY-MM-DD` format — defaults to today

**Response (200):**

```json
{
  "success": true,
  "count": 1,
  "district": "Mumbai",
  "state": "Maharashtra",
  "date": "2026-03-08",
  "cinema_halls": [
    {
      "hall_id": "uuid",
      "hall_name": "Grand Cinema",
      "location": "Downtown Plaza",
      "district": "Mumbai",
      "state": "Maharashtra",
      "movies": [
        {
          "movie_id": "uuid",
          "title": "Inception",
          "poster_url": "...",
          "duration_mins": 148,
          "genre": ["Sci-Fi", "Thriller"],
          "language": ["English", "Hindi"],
          "shows": [
            {
              "show_id": "uuid",
              "screen_id": "uuid",
              "screen_name": "IMAX Screen",
              "start_time": "11:00:00",
              "end_time": "13:28:00",
              "show_date": "2026-03-08",
              "language_version": "English",
              "pricing": { "premium": 350, "gold": 250, "silver": 180 }
            }
          ]
        }
      ]
    }
  ]
}
```

---

### Booking (`/api/booking`)

| Method | Endpoint                     | Auth     | Description                                    |
| ------ | ---------------------------- | -------- | ---------------------------------------------- |
| POST   | `/hold`                      | Customer | Hold selected seats for 5 minutes              |
| POST   | `/confirm`                   | Customer | Convert held seats to booked (without payment) |
| POST   | `/release`                   | Customer | Release held seats voluntarily                 |
| GET    | `/by-payment/:payment_id`    | Customer | Fetch confirmed booking by Razorpay payment ID |
| GET    | `/my-bookings`               | Customer | List all bookings for the logged-in customer   |
| GET    | `/:booking_id`               | Customer | Fetch a single booking by UUID (detail view)   |
| GET    | `/admin/all`                 | Admin    | List all bookings for admin's cinema hall      |
| GET    | `/admin/verify/:booking_id`  | Admin    | Verify a booking by UUID (QR scan lookup)      |

#### GET `/api/booking/by-payment/:payment_id`

Fetches a confirmed booking with full details using the Razorpay `payment_id`. Used by the success page after payment.

**Auth**: Customer required (ownership enforced — customer can only fetch their own booking)

**Response (200):**

```json
{
  "booking": {
    "id": "booking-uuid",
    "customer_id": "customer-uuid",
    "show_id": "show-uuid",
    "seats": ["0-0", "1-1"],
    "total_amount": "440.00",
    "payment_status": "completed",
    "payment_id": "pay_MlOhsFJKxD8SQz",
    "booking_status": "confirmed",
    "movie_title": "Paranthu Po",
    "show_date": "2026-03-06",
    "start_time": "11:00:00",
    "screen_name": "Screen 1",
    "cinema_hall_name": "Grand Cinema",
    "cinema_hall_location": "Downtown Plaza",
    "cinema_hall_latitude": 19.07609,
    "cinema_hall_longitude": 72.877426,
    "seat_labels": ["A1", "B2"]
  }
}
```

**Notes:**
- `seat_labels` are derived from `screens.layout` (e.g. row `"A"` + column `1` → `"A1"`)
- `screen_name` / `cinema_hall_name` / `cinema_hall_location` / `cinema_hall_latitude` / `cinema_hall_longitude` are joined in from `screens` and `cinema_hall`
- Returns `404` if payment_id not found or belongs to another customer

---

#### GET `/api/booking/my-bookings`

Lists all confirmed bookings for the currently logged-in customer, ordered by show date descending.

**Auth**: Customer required

**Response (200):**

```json
{
  "bookings": [
    {
      "id": "booking-uuid",
      "show_id": "show-uuid",
      "seats": ["0-0", "1-1"],
      "total_amount": "440.00",
      "payment_status": "completed",
      "payment_id": "pay_MlOhsFJKxD8SQz",
      "booking_status": "confirmed",
      "movie_title": "Paranthu Po",
      "show_date": "2026-03-06",
      "start_time": "11:00:00",
      "screen_name": "Screen 1",
      "cinema_hall_name": "Grand Cinema",
      "seat_labels": ["A1", "B2"],
      "refund_status": null,
      "razorpay_refund_id": null,
      "refund_initiated_at": null,
      "refund_settled_at": null
    }
  ]
}
```

> `refund_status`, `razorpay_refund_id`, `refund_initiated_at`, and `refund_settled_at` are populated via a LEFT JOIN to the `refunds` table. They are non-null only when `booking_status = 'cancelled'` and a refund record exists.

---

#### GET `/api/booking/:booking_id`

Fetches a single booking by its UUID for the logged-in customer. Used by `BookingDetailPage` — works on direct URL load and page refresh.

**Auth**: Customer required (ownership enforced — customer can only fetch their own booking)

**Path Param**: `booking_id` — must be a valid UUID v4. Returns `400` if format is invalid.

**Response (200):**

```json
{
  "booking": {
    "id": "booking-uuid",
    "customer_id": "customer-uuid",
    "show_id": "show-uuid",
    "seats": ["0-0", "1-1"],
    "total_amount": "440.00",
    "convenience_fee": "30.00",
    "gst_amount": "5.40",
    "discount_amount": "50.00",
    "payment_status": "completed",
    "payment_id": "pay_MlOhsFJKxD8SQz",
    "booking_status": "confirmed",
    "offer_code": "SAVE50",
    "created_at": "2026-03-06T08:30:00Z",
    "movie_title": "Inception",
    "poster_url": "https://example.com/poster.jpg",
    "duration_mins": 148,
    "genre": ["Action", "Sci-Fi", "Thriller"],
    "language": ["English"],
    "show_date": "2026-03-10",
    "start_time": "14:00:00",
    "screen_name": "Screen 1",
    "cinema_hall_name": "Grand Cinema",
    "seat_labels": ["A1", "B2"],
    "refund_status": null,
    "razorpay_refund_id": null,
    "refund_amount": null,
    "refund_initiated_at": null,
    "refund_settled_at": null,
    "refund_failure_reason": null
  }
}
```

**Notes:**
- `genre` and `language` are `TEXT[]` arrays (PostgreSQL) — serialized as JSON arrays
- `seat_labels` are derived from `screens.layout` JSONB
- `refund_*` fields are non-null only when `booking_status = 'cancelled'` and a refund record exists
- Returns `404` if booking not found or belongs to another customer

---

#### GET `/api/booking/admin/all`

Lists all bookings for shows in the admin's cinema hall. Supports filtering and pagination.

**Auth**: Admin required (`verifyCinemaAdminAccessToken` + `verifyCinemaHall`)

**Query Parameters:**

| Param       | Type   | Default | Description                                                        |
| ----------- | ------ | ------- | ------------------------------------------------------------------ |
| `from_date` | date   | —       | Show date range start (e.g. `2026-03-01`, `YYYY-MM-DD`). `null` = no lower bound |
| `to_date`   | date   | —       | Show date range end (e.g. `2026-03-31`, `YYYY-MM-DD`). `null` = no upper bound |
| `search`    | string | —       | Filter by movie title (partial, case-insensitive)                  |
| `status`    | string | —       | Filter by booking status (`confirmed`, `cancelled`, `completed`)   |
| `screen_id` | uuid   | —       | Filter by screen ID (scoped to admin's cinema hall)                |
| `page`      | number | `1`     | Page number                                                        |
| `limit`     | number | `10`    | Results per page (max 100, controlled by frontend rows-per-page)   |

**Response (200):**

```json
{
  "bookings": [
    {
      "id": "booking-uuid",
      "show_id": "show-uuid",
      "seats": ["0-0", "1-1"],
      "total_amount": "440.00",
      "convenience_fee": "30.00",
      "gst_amount": "5.40",
      "booking_status": "confirmed",
      "movie_title": "Paranthu Po",
      "show_date": "2026-03-06",
      "start_time": "11:00:00",
      "screen_name": "Screen 1",
      "customer_name": "Jane Smith",
      "customer_email": "jane@example.com",
      "seat_labels": ["A1", "B2"]
    }
  ],
  "total": 120,
  "page": 1,
  "stats": {
    "total_revenue": 52800.00,
    "total_convenience_fee": 3600.00,
    "total_gst": 648.00
  }
}
```

> `stats` aggregates are scoped to the same filters as the `bookings` array — they reflect only the filtered result set, not all bookings.

#### GET `/api/booking/admin/verify/:booking_id`

Looks up a booking by its full UUID — used by the admin QR code scanner to verify a customer's ticket at the cinema entrance.

**Auth**: Admin required (`verifyCinemaAdminAccessToken` + `verifyCinemaHall`)

**Path Param**: `booking_id` — must be a valid UUID v4. Returns `400` if format is invalid.

**Security**: Result is scoped to the admin's cinema hall (`sc.cinema_hall_id = cinema_hall_id`). An admin cannot look up bookings from another cinema hall.

**Response (200):**

```json
{
  "booking": {
    "id": "booking-uuid",
    "show_id": "show-uuid",
    "seats": ["0-0", "1-1"],
    "total_amount": "340.00",
    "booking_status": "confirmed",
    "movie_title": "Thaai Kizhavi",
    "show_date": "2026-03-10",
    "start_time": "11:45:00",
    "screen_name": "Screen 1",
    "customer_name": "Jane Smith",
    "customer_email": "jane@example.com",
    "seat_labels": ["E7", "E8"]
  }
}
```

**Error Responses:**
- `400` — Invalid UUID format
- `404` — Booking not found (or belongs to a different cinema hall)

---

### Settings Management (`/api/settings`)

The platform settings are structured into three scopes: Organization level (tenant branding, billing/payment fees, tickets config, security), Hall level (cinema profile, showtimes defaults, booking rules), and User level (UI theme and notification channels).

#### 1. Organization Settings

| Method | Endpoint | Auth | Description |
| ------ | -------- | ---- | ----------- |
| GET    | `/org`   | Admin | Get all organization settings sections |
| PATCH  | `/org`   | Admin + SuperAdmin | Update specific organization settings section |

**Request Body for PATCH `/org`**:
```json
{
  "section": "payment",
  "value": {
    "convenience_fee": { "model": "per_ticket", "amount": 15 },
    "gst_percentage": 18,
    "gst_applies_to": "convenience_fee",
    "state_taxes": []
  }
}
```
*Note: Organization name updates to the "general" section are automatically synchronized directly into the `organizations.name` column (the source of truth).*

#### 2. Hall-level Settings

| Method | Endpoint | Auth | Description |
| ------ | -------- | ---- | ----------- |
| GET    | `/hall/:hallId` | Admin + Active Hall | Get active cinema hall settings sections |
| PATCH  | `/hall/:hallId` | Admin + Active Hall | Update specific cinema hall settings section |

**Request Body for PATCH `/hall/:hallId`**:
```json
{
  "section": "booking",
  "value": {
    "max_seats_per_booking": 10,
    "hold_minutes": 5,
    "cancellation": { "allowed": true, "window_minutes": 120, "penalty_percentage": 10 }
  }
}
```

#### 3. User-level Settings

| Method | Endpoint | Auth | Description |
| ------ | -------- | ---- | ----------- |
| GET    | `/user`  | Admin | Get authenticated admin settings preferences |
| PATCH  | `/user`  | Admin | Update admin user appearance and notification toggles |

#### 4. Backward Compatibility Endpoints

To support existing frontend and customer flow calculations, compatibility shims are provided:

- **GET `/api/settings`** (Public): Resolves the `convenience_fee_per_ticket` and `gst_percentage` from the authenticated user's organization settings `payment` section dynamically.
- **PUT `/api/settings`** (Admin + SuperAdmin): Updates the convenience fee and GST percentage fields in the active organization settings `payment` section.

---

### Onboarding API (`/api/auth/onboarding`)

| Method | Endpoint | Auth | Description |
| ------ | -------- | ---- | ----------- |
| POST   | `/onboarding` | Admin | Transactionally initializes the multi-tenant organization, seeds roles, assigns permissions, configures default settings, and creates the first cinema hall. |

**Request Body**:
```json
{
  "orgName": "Cineplex Entertainment",
  "name": "Grand Cinema Salai",
  "location": "42 Anna Salai, Chennai",
  "district": "Chennai",
  "state": "Tamil Nadu",
  "latitude": 13.0827,
  "longitude": 80.2707,
  "phone": "9876543210",
  "description": "Premium multi-screen theater in Anna Salai"
}
```

**Response (201)**:
```json
{
  "message": "Onboarding completed successfully",
  "orgId": "org-uuid-xxxx",
  "orgName": "Cineplex Entertainment",
  "hall": {
    "id": "hall-uuid-xxxx",
    "name": "Grand Cinema Salai",
    "location": "42 Anna Salai, Chennai",
    "district": "Chennai",
    "state": "Tamil Nadu",
    "is_active": true
  }
}
```
*Note: The onboarding process uses transactions (`BEGIN/COMMIT/ROLLBACK`) to guarantee that organizations, roles, permissions, settings, members, and halls are seeded atomicly without half-created records.*


---

### Ads (`/api/ads`)

| Method | Endpoint         | Auth          | Description                                      |
| ------ | ---------------- | ------------- | ------------------------------------------------ |
| GET    | `/active`        | None (public) | Get currently active ads filtered by `placement` |
| POST   | `/click/:id`     | None (optional customer cookie) | Record a click-through on an ad |
| GET    | `/`              | SuperAdmin    | List all ads with total click count              |
| POST   | `/create`        | SuperAdmin    | Create a new ad                                  |
| PUT    | `/update/:id`    | SuperAdmin    | Update an existing ad                            |
| DELETE | `/delete/:id`    | SuperAdmin    | Delete an ad (cascades click records)            |
| GET    | `/:id/clicks`    | SuperAdmin    | Get click-through details for a specific ad      |

#### GET `/api/ads/active?placement=banner`

Returns ads where `is_active = true` AND `start_date <= CURRENT_DATE <= end_date` for the given placement (`banner` or `side`). No auth required.

**Response (200):**

```json
{
  "ads": [
    {
      "id": "uuid",
      "title": "Summer Sale",
      "image_url": "https://example.com/banner.jpg",
      "click_url": "https://example.com/offer",
      "placement": "banner"
    }
  ]
}
```

#### POST `/api/ads/click/:id`

Records a click-through. If a valid `cusAccessToken` cookie is present, attaches the customer ID; otherwise records anonymously.

**Response (200):**

```json
{ "recorded": true }
```

#### GET `/api/ads/:id/clicks` *(SuperAdmin)*

**Response (200):**

```json
{
  "clicks": [
    {
      "id": "uuid",
      "clicked_at": "2026-03-14T10:30:00Z",
      "customer_name": "Jane Smith",
      "customer_email": "jane@example.com",
      "customer_phone": "+91 98765 43210"
    },
    {
      "id": "uuid",
      "clicked_at": "2026-03-14T11:00:00Z",
      "customer_name": null,
      "customer_email": null,
      "customer_phone": null
    }
  ]
}
```

> `customer_name` / `customer_email` / `customer_phone` are `null` for anonymous (non-logged-in) clicks.

#### Ad Fields

| Field        | Type    | Required | Description                                      |
| ------------ | ------- | -------- | ------------------------------------------------ |
| `title`      | string  | Yes      | Ad display name (admin reference)                |
| `image_url`  | string  | Yes      | URL of the ad image                              |
| `click_url`  | string  | No       | URL to open when the ad is clicked               |
| `placement`  | string  | Yes      | `"banner"` (MoviesPage carousel) or `"side"` (MovieInfoPage sidebar) |
| `start_date` | date    | Yes      | Date from which the ad becomes active            |
| `end_date`   | date    | Yes      | Date after which the ad stops serving            |
| `is_active`  | boolean | No       | Manual on/off toggle (default `true`)            |

---

### Offers (`/api/offers`) — RBAC + creator/org-scoped since `6e0705a` (`controllers/offers.Controller.js:1`, `routes/offers.routes.js:27`)

| Method | Endpoint             | Auth          | Description                                              |
| ------ | -------------------- | ------------- | -------------------------------------------------------- |
| GET    | `/cinema-halls`      | `offers.create` (any admin with permission; `verifyCinemaAdminAccessToken` + `requirePermission`) | List halls the caller may assign: SuperAdmin → all halls, org member → `WHERE org_id = resolveOrgId(req.admin.id)` (`403 No organization found` if no org) (`controllers/offers.Controller.js:110`) |
| GET    | `/`                  | `offers.read` | List offers (paginated, filters: scope/is_active/search, `page` limit 50). SuperAdmin sees all; others `AND created_by = req.admin.id`. Joins `cinema_hall_name` + `created_by_name/email/role` via `LATERAL creator_role` (`Super Admin` for `superAdmin` users) (`controllers/offers.Controller.js:134`) |
| GET    | `/:id`               | `offers.read` | Fetch single offer by ID with `cinema_hall_name` + `created_by_name`; creator ownership enforced for non-SuperAdmin (`403 You can only view offers you created.`) (`controllers/offers.Controller.js:280`) |
| POST   | `/create`            | `offers.create` | Create offer. `scope=global` requires SuperAdmin (`403 Only Super Admin can create global offers.`); `scope=hall` for non-SuperAdmin requires `cinema_hall_id` belonging to `resolveOrgId` org (`403 You can only create offers for your own cinema hall.`) (`controllers/offers.Controller.js:221`) |
| PUT    | `/update/:id`        | `offers.update` | Update offer (same body as create). Ownership + scope/hall checks mirror create (`403 You can only edit offers you created.`) (`controllers/offers.Controller.js:308`) |
| DELETE | `/delete/:id`        | `offers.delete` | Delete offer (`403 You can only delete offers you created.` for non-owners) (`controllers/offers.Controller.js:395`) |
| GET    | `/active`            | Customer      | List active, eligible, non-expired offers for the logged-in user — includes redeemed offers with `is_redeemed: true` (sorted: available first) |
| POST   | `/validate`          | Customer      | Validate an offer code and calculate the discount preview |

#### Offer Fields

| Field                | Type    | Required | Description                                                          |
| -------------------- | ------- | -------- | -------------------------------------------------------------------- |
| `code`               | string  | Yes      | Unique coupon code (stored uppercase)                                |
| `title`              | string  | Yes      | Short display name shown to users                                    |
| `description`        | string  | No       | Longer description shown on the Offers page                          |
| `discount_type`      | string  | Yes      | `"percentage"` or `"fixed"`                                          |
| `discount_value`     | number  | Yes      | Percentage (e.g. `10` for 10%) or flat rupee amount (e.g. `50`)     |
| `max_discount_amount`| number  | No       | Maximum discount cap for percentage offers (e.g. `150` → max ₹150). `null` = no cap |
| `min_booking_amount` | number  | No       | Minimum grand total required for the offer to apply (default `0`)   |
| `is_active`          | boolean | No       | Manual on/off toggle (default `true`)                                |
| `valid_until`        | datetime| Yes      | Offer expires after this timestamp                                   |
| `scope`              | string  | Yes      | `"global"` (all halls) or `"hall"` (specific cinema hall)           |
| `cinema_hall_id`     | uuid    | No       | Required when `scope = "hall"`                                       |
| `user_eligibility`   | string  | Yes      | `"all"` or `"joined_after"`                                         |
| `user_joined_after`  | datetime| No       | Required when `user_eligibility = "joined_after"`. Only customers who registered after this date are eligible |

#### POST `/api/offers/validate`

Validates an offer code server-side and returns the calculated discount amount. **Does not record the redemption** — that happens in `verifyPayment`.

**Request Body:**

```json
{
  "offer_code": "SAVE50",
  "show_id": "uuid",
  "total_amount": 395.4
}
```

**Response (200):**

```json
{
  "offer_id": "uuid",
  "offer_code": "SAVE50",
  "offer_title": "Flat ₹50 Off",
  "discount_amount": 50,
  "final_amount": 345.4
}
```

**Validation checks (in order):**
1. Offer exists and `is_active = true`
2. `valid_until > NOW()`
3. `total_amount >= min_booking_amount`
4. If `scope = "hall"`: show's cinema hall matches offer's `cinema_hall_id`
5. If `user_eligibility = "joined_after"`: customer joined after `user_joined_after`
6. No prior entry in `offer_redemptions` for `(offer_id, customer_id)` (once per user)
7. Discount calculation: fixed → `discount_value`; percentage → `min(total × val/100, max_discount_amount)`

#### Offer Redemption Flow

```mermaid
sequenceDiagram
    participant U as User
    participant FE as OrderSummaryPage
    participant API as /api/offers/validate
    participant PAY as /api/payment/create-order
    participant VER as /api/payment/verify

    U->>FE: Enter coupon code
    FE->>API: POST /validate { offer_code, show_id, total_amount }
    API-->>FE: { discount_amount, final_amount }
    FE->>FE: Show discount in price breakdown
    U->>FE: Click Pay
    FE->>PAY: POST /create-order { show_id, seats, offer_code }
    PAY->>PAY: Re-validate offer server-side
    PAY->>PAY: Calculate final_amount = grandTotal - discount
    PAY-->>FE: Razorpay order with discounted amount
    FE->>VER: POST /verify { razorpay_order_id, ... }
    VER->>VER: Confirm booking + INSERT offer_redemptions
    VER-->>FE: { success: true, booking }
```

> **Security note:** The offer is always re-validated server-side in `createOrder` — the frontend discount preview is never trusted for the final charge.

#### Audit trail for Offers

`POST /create`, `PUT /update/:id`, `DELETE /delete/:id` now call `recordAuditLog(req, {action: 'offers.create'|'offers.update'|'offers.delete', resourceType:'offer', resourceId: id, resourceLabel: code, hallId: cinema_hall_id})` via `utils/auditLog.js:7` (`edec38f`).

---

### Audit Logs (`/api/audit-logs`) — added `edec38f` (`database/migration_phase7_audit_logs.sql:1` / `controllers/auditLogs.Controller.js:1` / `routes/auditLogs.routes.js:1` / `utils/auditLog.js:1` / `server.js:34`)

Business-action audit trail (who did what to which resource), stored in `audit_logs` (`docs/db_setup.sql:276`, idempotent, also `database/migration_phase7_audit_logs.sql:1`). Distinct from `admin_security_logs` which only covers auth/login events — `actor_name`/`actor_role_key` are denormalized snapshots so rows stay legible after rename/removal.

| Method | Endpoint | Auth | Description |
| ------ | -------- | ---- | ----------- |
| GET    | `/`      | `audit.view` (`verifyCinemaAdminAccessToken` + `requirePermission`) | List paginated audit events for the caller's `org_id` with filters `adminId`, `resourceType`, `action`, `hallId`, `from_date`, `to_date`, `page`/`limit` (default `20`, max `100`), joined `hall_name` via `cinema_hall` |

**Org scoping:** `orgId = req.query.orgId || await resolveOrgId(req.admin.id)` (`controllers/auditLogs.Controller.js:9`). A platform-only `superAdmin` with no org membership must pass `?orgId=` explicitly (else `400 orgId query parameter is required`); org members get `404 Organization not found` if none.

**Response (200):**
```json
{
  "logs": [{ "id": "uuid", "action": "shows.create", "resource_type": "show", "resource_id": "uuid", "resource_label": "2026-08-23 14:00", "admin_id": "uuid", "actor_name": "Alice", "actor_role_key": "owner", "hall_id": "uuid", "hall_name": "PVR", "metadata": {"fields":["name"]}, "ip_address": "1.2.3.4", "created_at": "2026-08-23T13:00:00Z" }],
  "total": 42,
  "page": 1,
  "limit": 20
}
```

**Indexes:** `idx_audit_logs_org_created ON (org_id, created_at DESC)`, `idx_audit_logs_admin ON (admin_id)`, `idx_audit_logs_resource ON (org_id, resource_type, resource_id)`, `idx_audit_logs_hall ON (hall_id)`, `idx_audit_logs_action ON (org_id, action)`.

**`recordAuditLog` utility (`utils/auditLog.js:7`, `edec38f`):**
```js
recordAuditLog(req, {action, resourceType, resourceId=null, resourceLabel=null, hallId=null, metadata={}})
```
Fire-and-forget: never throws (logs its own failure via `logger.error`), resolves `orgId` via `req.orgId || admin.orgId || await resolveOrgId(admin.id)`, skips if no `admin.id`/`orgId`, inserts `(org_id, admin_id, actor_name, actor_role_key, action, resource_type, resource_id, resource_label, hall_id, metadata, ip_address, user_agent)` with `req.ip` and `user-agent` header. Wrapped around all mutations in `edec38f`: `halls.create/update/delete` (`halls.Controller.js:142`), `offers.create/update/delete`, `refunds.settle` (`refund.Controller.js:159`), `roles.create/update/delete/clone` (`roles.Controller.js:161`), `screens.create/update/delete` (`screens.Controller.js:67`), `settings.org.update` (`settings.Controller.js:139`) + `settings.hall.update:216`, `shows.create/bulk/update/delete/bulk/cancel/booking_status/bulk/restore/bulk` (`shows.Controller.js:35`), `team.member.invite/create/update/remove/assign_halls/remove_hall` (`team.Controller.js:62`).

**`server.js:34`** mounts `auditLogsRoutes` at `/api/audit-logs`.

---

### Notifications (`/api/notifications`) — added `7658007` (`migrations/migration_notifications.sql:1` / `services/notification/*` / `routes/notifications.routes.js:1` / `middleware/identifyRecipient.js:1` / `controllers/notifications.Controller.js:1` / `mail/emailTemplate.js:1` / `mail/emails.js:236` / `server.js:35`)

Unified in-app + email notification center backed by `notifications`/`notification_dispatch_log`/`device_tokens`/`customer_settings` (`docs/db_setup.sql` — same migration as `migrations/migration_notifications.sql:1`, idempotent). Events: `booking_confirmed`, `booking_cancelled`, `refund_initiated`, `refund_settled`, `show_cancelled`, `show_reminder`, `daily_report`, `security_alert` — title/body via `buildNotificationContent(event,data)` (`services/notification/templates.js:5`).

| Method | Endpoint | Auth | Description |
| ------ | -------- | ---- | ----------- |
| POST   | `/dispatch` | QStash `Upstash-Signature` (`express.raw`) | Webhook target for `@upstash/qstash` (`qstashClient.js:6`, `QSTASH_TOKEN/URL/SIGNING_KEYS`, local `qstash-cli dev`, `API_BASE_URL`); re-fetches `notifications` + recipient `customers`/`cinema_admin_user` fresh, `sendEmailForNotification` (`channels/email.js:4`), marks `notification_dispatch_log` `sent`/`failed` (retry via QStash `retries:3`) |
| GET    | `/`      | `identifyRecipient` (customer `cusAccessToken`/`Bearer` or admin `accessToken`, `localhost` dual-cookie via `Origin===ADMIN_FRONTEND_URL`) | `listNotifications` (`controllers/notifications.Controller.js:7`): `page`/`limit` 1-100 default 20, `WHERE customer_id|admin_id`, `ORDER BY created_at DESC` → `{notifications:[{id,event,title,body,data,booking_id,show_id,refund_id,read_at,created_at}]}`, `page`, `limit` |
| GET    | `/unread-count` | `identifyRecipient` | `getUnreadCount` (`:32`): `COUNT(*) WHERE … read_at IS NULL` → `{count}` |
| PATCH  | `/:id/read` | `identifyRecipient` | `markAsRead` (`:47`): `UPDATE … SET read_at=now() WHERE id AND recipient AND read_at IS NULL` → `{updated:bool}` |
| PATCH  | `/read-all` | `identifyRecipient` | `markAllRead` (`:66`): `UPDATE … WHERE recipient AND read_at IS NULL` → `{updated:count}` |
| GET    | `/preferences` | `identifyRecipient` | `getPreferences` (`:81`): reads `customer_settings`/`user_settings` `section='notifications'`, merges with `DEFAULT_EVENT_PREFERENCES` (`defaultPreferences.js:6`, `show_reminder push:true`) → `{preferences:{event:{email,sms,whatsapp,push}}}` |
| PATCH  | `/preferences` | `identifyRecipient` | `updatePreferences` (`:102`): body `{patch:{event:{email,…}}}`, `INSERT … ON CONFLICT (idCol,section) DO UPDATE` in `customer_settings`/`user_settings` → merged preferences |

**Dispatch pipeline (`services/notification/index.js:19` `notify(event,recipient,data)`, `scheduleShowReminder`, `cancelShowReminder`):** called *after* triggering transaction `COMMIT` (so notify failure never 500s): `insertInAppNotification` (`channels/inApp.js:13` — `INSERT INTO notifications (org_id,customer_id,admin_id,event,title,body,data,booking_id,show_id,refund_id) VALUES … RETURNING *` with `buildNotificationContent`), `resolveEnabledChannels` (`preferences.js:12`: intersects org `organization_settings` `notifications` master switches + recipient per-event `customer_settings`/`user_settings` with `DEFAULT_EVENT_PREFERENCES` defaults), per-channel `INSERT notification_dispatch_log … queued` + `publishDispatch` (`qstashClient.js:30` `publishJSON {url: API_BASE_URL/api/notifications/dispatch, body:{notificationId,event,recipientType,recipientId,channel}, notBefore?, retries:3}` → stored `qstash_message_id`). `show_reminder` scheduled at `showDateTime -60m` (`notBefore` epoch), skipped if in past; cancellation queries `d.queued` reminders for `booking_id` and `cancelScheduledMessage` (`qstashClient.messages.delete`) → `skipped`.

**Server (`server.js:35`):** adds `RAW_BODY_PATHS=['/api/payment/webhook','/api/notifications/dispatch']` to skip `express.json`/`urlencoded` for both webhooks (raw `Buffer` for `Upstash-Signature`/`HMAC`).

**Email channels (`mail/emails.js:236`, `mail/emailTemplate.js:1`):** `sendBookingConfirmationEmail` (`BOOKING_CONFIRMATION_TEMPLATE`), `sendRefundInitiatedEmail`, `sendRefundSettledEmail`, `sendShowCancelledEmail`, `sendShowReminderEmail` — all dark `CineMax` HTML (`#0f0f14`/`#16161e`, `rgba(244,63,94,0.15)` badge) via `transporter.sendMail` (`MAIL_ID`).

**DB (`migrations/migration_notifications.sql:1`):** `notifications` (`customer_id`/`admin_id` `CHECK one_recipient`, indexes `customer`, `admin`, `unread WHERE read_at IS NULL`), `notification_dispatch_log` (`channel CHECK email|push|in_app|sms|whatsapp`, `status queued|sent|delivered|failed|skipped`, indexes `notification`, `qstash_message_id`, `status`), `device_tokens` (`token UNIQUE`, `platform web|android|ios`, one-recipient CHECK), `customer_settings` (`customer_id,section UNIQUE`). Note: `user_settings` already existed for admin prefs.

---

### Customers (`/api/customers`)

| Method | Endpoint | Auth       | Description                              |
| ------ | -------- | ---------- | ---------------------------------------- |
| GET    | `/`      | SuperAdmin | List all customers with search + stats   |
| GET    | `/:id`   | SuperAdmin | Get customer details with bookings + sessions |

#### GET `/api/customers` *(SuperAdmin)*

Returns a paginated list of all registered platform customers. Supports search across name, email, and phone.

**Query Parameters:**

| Param    | Type   | Default | Description                                                      |
| -------- | ------ | ------- | ---------------------------------------------------------------- |
| `search` | string | —       | Filter by name, email, or phone                                  |
| `page`   | number | `1`     | Page number                                                      |
| `limit`  | number | `10`    | Results per page (max 100, controlled by frontend rows-per-page) |

**Response (200):**

```json
{
  "customers": [
    {
      "id": "uuid",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "9876543210",
      "district": "Chennai",
      "state": "Tamil Nadu",
      "is_verified": true,
      "created_at": "2025-01-15T10:30:00Z",
      "avatar": "https://lh3.googleusercontent.com/...",
      "auth_providers": ["local", "google"],
      "booking_count": 5
    }
  ],
  "total": 120,
  "stats": {
    "total": 120,
    "verified": 98
  }
}
```

`booking_count` is the number of confirmed (paid) bookings for each customer. `stats` always reflects the full unfiltered totals. `avatar` is `null` if no OAuth profile picture. `auth_providers` is an array of login methods (e.g. `["local"]`, `["google", "github"]`).

---

#### GET `/api/customers/:id` *(SuperAdmin)*

Returns detailed information for a single customer including recent bookings and active sessions. Used by the admin panel's CustomerDetailSheet.

**Path Parameter:** `:id` — the customer's UUID

**Response (200):**

```json
{
  "customer": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "9876543210",
    "district": "Chennai",
    "state": "Tamil Nadu",
    "is_verified": true,
    "failed_login_attempts": 0,
    "account_locked_until": null,
    "last_login_at": "2026-06-01T10:00:00Z",
    "password_changed_at": "2026-05-20T08:00:00Z",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2026-06-01T10:00:00Z",
    "auth_providers": ["local", "google"],
    "avatar": "https://lh3.googleusercontent.com/...",
    "has_password": true
  },
  "recentBookings": [
    {
      "id": "uuid",
      "booking_status": "confirmed",
      "payment_status": "completed",
      "total_amount": "350.00",
      "created_at": "2026-06-01T14:30:00Z"
    }
  ],
  "activeSessions": [
    {
      "id": "uuid",
      "ip_address": "103.27.12.45",
      "user_agent": "Mozilla/5.0 ...",
      "is_revoked": false,
      "last_used_at": "2026-06-01T16:00:00Z",
      "created_at": "2026-06-01T10:00:00Z"
    }
  ]
}
```

- `recentBookings`: last 10 bookings ordered by `created_at DESC`
- `activeSessions`: last 10 non-revoked sessions ordered by `last_used_at DESC`
- `has_password`: boolean indicating whether the customer has a password set (OAuth-only accounts may not)

**Response (404):** `{ "error": "Customer not found." }`

---

### Cinema Hall Admins (`/api/auth/admins`)

| Method | Endpoint   | Auth       | Description                                         |
| ------ | ---------- | ---------- | --------------------------------------------------- |
| GET    | `/admins`  | SuperAdmin | List all cinema hall admins with their hall details |

#### GET `/api/auth/admins` *(SuperAdmin)*

Returns a paginated list of all registered cinema hall admins (filters `role = 'admin'` only). Each admin's halls are aggregated into a `halls` JSON array — no duplicate rows. Supports search by admin name, email, or hall name.

**Query Parameters:**

| Param    | Type   | Default | Description                                                      |
| -------- | ------ | ------- | ---------------------------------------------------------------- |
| `search` | string | —       | Filter by name, email, or hall name                              |
| `page`   | number | `1`     | Page number                                                      |
| `limit`  | number | `10`    | Results per page (max 100, controlled by frontend rows-per-page) |

**Response (200):**

```json
{
  "admins": [
    {
      "id": "uuid",
      "name": "Ravi Kumar",
      "email": "ravi@example.com",
      "phone": "9876543210",
      "role": "admin",
      "email_verified": true,
      "email_verified_at": "2025-02-01T09:00:00Z",
      "last_login_at": "2026-06-01T10:00:00Z",
      "created_at": "2025-02-01T08:00:00Z",
      "auth_providers": ["local", "google"],
      "avatar": "https://lh3.googleusercontent.com/...",
      "halls": [
        { "id": "uuid", "name": "Ravi Cinemas", "location": "Tirunelveli", "district": "Tirunelveli", "state": "Tamil Nadu" },
        { "id": "uuid", "name": "Ravi IMAX", "location": "Madurai", "district": "Madurai", "state": "Tamil Nadu" }
      ]
    }
  ],
  "total": 12
}
```

`halls` is an empty array `[]` if the admin has not yet created any cinema hall. `avatar` is `null` if no OAuth profile picture. `auth_providers` lists all linked login methods.

---

#### GET `/api/auth/admins/:id/logs` *(SuperAdmin)*

Returns the admin's profile (with `halls` array) and `admin_security_logs` entries, ordered by `created_at DESC` (last 30).

**Path Parameter:** `:id` — the admin's UUID

**Response (200):**

```json
{
  "admin": {
    "id": "uuid",
    "name": "Ravi Kumar",
    "email": "ravi@example.com",
    "role": "admin",
    "email_verified": true,
    "email_verified_at": "2025-02-01T09:00:00Z",
    "failed_login_attempts": 0,
    "account_locked_until": null,
    "password_changed_at": "2026-05-20T08:00:00Z",
    "last_login_at": "2026-06-01T10:00:00Z",
    "created_at": "2025-02-01T08:00:00Z",
    "auth_providers": ["local", "google"],
    "avatar": "https://lh3.googleusercontent.com/...",
    "halls": [
      { "id": "uuid", "name": "Ravi Cinemas", "location": "Tirunelveli", "district": "Tirunelveli", "state": "Tamil Nadu" }
    ]
  },
  "logs": [
    {
      "action": "LOGIN_SUCCESS",
      "ip_address": "103.27.12.45",
      "user_agent": "Mozilla/5.0 ...",
      "metadata": {},
      "created_at": "2026-05-31T10:00:00Z"
    },
    {
      "action": "LOGIN_FAILED",
      "ip_address": "103.27.12.45",
      "user_agent": "Mozilla/5.0 ...",
      "metadata": { "reason": "invalid_password" },
      "created_at": "2026-05-31T09:58:00Z"
    }
  ]
}
```

**Possible `action` values:** `LOGIN_SUCCESS`, `LOGIN_FAILED`, `LOGOUT`, `LOGOUT_ALL`, `EMAIL_VERIFIED`, `PASSWORD_RESET`, `PASSWORD_CHANGED`, `ACCOUNT_LOCKED`, `OAUTH_LOGIN`, `OAUTH_SIGNUP`, `PROVIDER_LINKED`, `PROVIDER_UNLINKED`, `PASSWORD_SET`

**Response (404):** `{ "error": "Admin not found." }`

---

### Dashboard (`/api/dashboard`)

| Method | Endpoint  | Auth                   | Description                          |
| ------ | --------- | ---------------------- | ------------------------------------ |
| GET    | `/stats`  | Admin + Cinema Hall    | All dashboard metrics in one call    |

#### GET `/api/dashboard/stats` *(Admin + Cinema Hall)*

Returns everything the admin dashboard needs in a single request. All DB queries run in parallel via `Promise.all`. Scoped to `req.my_cinema_hall.id` (set by `verifyCinemaHall` middleware).

**Response (200):**

```json
{
  "today": {
    "bookings": 24,
    "revenue": 12400.00,
    "convenience_fee": 480.00,
    "gst": 480.00
  },
  "allTime": {
    "bookings": 1204,
    "revenue": 620000.00
  },
  "customers": 980,
  "activeOffers": 3,
  "screens": 3,
  "revenueTrend": [
    { "date": "2026-03-14", "revenue": 8200.00, "bookings_count": 18 },
    { "date": "2026-03-15", "revenue": 11500.00, "bookings_count": 24 }
  ],
  "recentBookings": [
    {
      "id": "uuid",
      "total_amount": "385.00",
      "booking_status": "confirmed",
      "created_at": "2026-03-20T14:32:00Z",
      "movie_title": "Superman",
      "customer_name": "Duraimurugan Don H",
      "seat_labels": ["C3", "C4"]
    }
  ],
  "todayShows": [
    {
      "id": "uuid",
      "start_time": "10:00:00",
      "status": "open",
      "movie_title": "KGF Chapter 2",
      "screen_name": "Screen 1",
      "total_seats": 120,
      "booked_seats": 45
    }
  ]
}
```

**Data sources:**

| Field | Query |
|-------|-------|
| `today` | `SUM(total_amount / convenience_fee / gst_amount)` + `COUNT(*)` filtered by `show_date = CURRENT_DATE` |
| `allTime` | Same aggregation without date filter |
| `customers` | `COUNT(*) FROM customers` (platform-wide) |
| `activeOffers` | `COUNT(*) FROM offers WHERE (cinema_hall_id = ? OR scope = 'global') AND is_active AND valid_until >= NOW()` |
| `screens` | `COUNT(*) FROM screens WHERE cinema_hall_id = ?` |
| `revenueTrend` | `generate_series(CURRENT_DATE - 6 days, CURRENT_DATE)` LEFT JOINed with bookings |
| `recentBookings` | Last 5 bookings with customer + movie + seat labels |
| `todayShows` | Shows with `show_date = CURRENT_DATE`, seat counts from `show_booked_seats` |

---

## Middleware

### Authentication Middleware

```mermaid
flowchart TD
    A[Request] --> B{Has Cookie?}
    B -->|No| C[401 Unauthorized]
    B -->|Yes| D[Verify JWT]
    D -->|Invalid| C
    D -->|Valid| E{Check Role}
    E -->|SuperAdmin Required| F{Is SuperAdmin?}
    E -->|Admin Required| G{Is Admin?}
    E -->|Customer Required| H{Is Customer?}
    F -->|No| I[403 Forbidden]
    F -->|Yes| J[Attach user to req]
    G -->|No| I
    G -->|Yes| J
    H -->|No| I
    H -->|Yes| J
    J --> K[Next Middleware]
```

### Middleware Functions

| Middleware                      | Purpose                       | Used In          |
| ------------------------------- | ----------------------------- | ---------------- |
| `verifyCinemaAdminAccessToken`  | Verify admin access token     | Admin routes     |
| `verifyCinemaAdminRefreshToken` | Verify admin refresh token    | Token refresh    |
| `verifySuperAdmin`              | Verify SuperAdmin role        | Movie CRUD, Ads, Offers, Customers, Admins list |
| `verifyCinemaHall`              | Verify admin owns cinema hall | Shows management |
| `verifyScreenOwnership`         | Verify admin owns screen      | Show creation    |
| `verifyCustomer`                | Verify customer access token (cookie `cusAccessToken`, falls back to `Authorization: Bearer <token>`) | Customer routes  |
| `verifyCustomerRefreshToken`    | Verify customer refresh token (cookie `cusRefreshToken`, falls back to `req.body.refreshToken` or `Authorization: Bearer <token>`) | Token refresh    |

---

## Request/Response Flow

```mermaid
sequenceDiagram
    participant Client
    participant CORS
    participant Auth
    participant Controller
    participant DB
    participant Response

    Client->>CORS: HTTP Request
    CORS->>CORS: Check origin
    CORS->>Auth: Pass if allowed
    Auth->>Auth: Verify JWT token
    Auth->>Controller: req.admin/req.customer
    Controller->>DB: Query/Mutation
    DB-->>Controller: Result
    Controller->>Response: Format JSON
    Response-->>Client: HTTP Response
```

---

## Error Handling

### Global Error Handler

All unhandled errors are caught by two layers:

1. **Sentry** — `Sentry.setupExpressErrorHandler(app)` is registered after all routes and before other error middleware. It captures every unhandled Express error and forwards it to the Sentry dashboard.
2. **Winston logger** — The custom error handler logs the error with structured metadata.

```javascript
// Sentry must come first — after all routes, before other error middleware
Sentry.setupExpressErrorHandler(app);

app.use((err, req, res, next) => {
  logger.error('Global Error', { message: err.message, stack: err.stack });
  res.status(500).json({ error: 'Something went wrong!' });
});
```

### Common Error Responses

| Status | Error                 | Description                   |
| ------ | --------------------- | ----------------------------- |
| 400    | Bad Request           | Missing/invalid fields        |
| 401    | Unauthorized          | Invalid/missing token         |
| 403    | Forbidden             | Insufficient permissions      |
| 404    | Not Found             | Resource doesn't exist        |
| 409    | Conflict              | Show overlap, duplicate email |
| 500    | Internal Server Error | Database/server error         |

---

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:pass@host/db

# JWT
JWT_SECRET=your-secret-key

# Server
PORT=5000
NODE_ENV=production

# Email (for OTP)
EMAIL_SERVICE=gmail
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password

# Sentry (optional — falls back to hardcoded DSN in instrument.js if not set)
SENTRY_DSN=https://<key>@o<org>.ingest.us.sentry.io/<project>

# Vercel Cron protection
CRON_SECRET=your-cron-secret

# Razorpay
RAZORPAY_KEY_ID=rzp_live_xxx
RAZORPAY_KEY_SECRET=your-razorpay-secret
RAZORPAY_WEBHOOK_SECRET=your-webhook-secret

# TMDB
TMDB_API_KEY=your-tmdb-bearer-token
```

---

## Monitoring & Logging

### Sentry (Error Tracking)

The backend uses [`@sentry/node`](https://docs.sentry.io/platforms/javascript/guides/express/) for error tracking and performance monitoring.

**Initialisation strategy (ESM + Vercel):**

Because this is an ESM project, static `import` statements are hoisted before any code runs — so a top-level `import "./instrument.js"` alone is not enough. Sentry's module hooks must be registered _before_ Express is resolved, using Node's `--import` flag.

| File | Role |
|---|---|
| `instrument.js` | Calls `Sentry.init()` — DSN, environment, `tracesSampleRate` |
| `server.js` | `import "./instrument.js"` (ensures file is included in Vercel's bundle via nft tracing) + `Sentry.setupExpressErrorHandler(app)` after all routes |
| `nodemon.json` | `execArgs: ["--import=@sentry/node/preload"]` — registers hooks before Express in local dev |
| `package.json` `start` | `node --import=@sentry/node/preload server.js` |

> **Why not `NODE_OPTIONS` in `vercel.json`?**  
> `@vercel/node` uses file tracing (`nft`) to bundle only imported files. `NODE_OPTIONS` is an env var — `nft` cannot trace it, so `@sentry/node/preload` would not be included in the deployment bundle and the function would crash at startup.

**Verifying Sentry is working:**

```
GET /debug-sentry
```

This route intentionally throws an error. An event named _"Sentry test error from cinema-hall-api"_ should appear in your Sentry dashboard within ~30 seconds. Remove this route after confirming.

---

### Winston (Structured Logging)

All `console.log` / `console.error` / `console.warn` calls across the entire codebase (19 files — all controllers, middleware, `db.js`, `mail/emails.js`) have been replaced with structured Winston logger calls.

**Logger config** (`utils/logger.js`):

| Environment | Format | Transport |
|---|---|---|
| Production (`NODE_ENV=production`) | `winston.format.json()` | Console only (Vercel captures stdout in Function Logs) |
| Development | Colorized + timestamp printf | Console only |

**Log levels used:**

| Level | When |
|---|---|
| `logger.info` | Successful operations, startup, every HTTP request/response, webhook events, background job results |
| `logger.warn` | Transient DB errors in background jobs (`ENOTFOUND`, `ECONNRESET`), unhandled webhook events |
| `logger.error` | All caught exceptions in controllers, middleware, and background jobs |
| `logger.debug` | Dev-only diagnostic values (e.g. show date normalization, customer ID) |

**Request logging middleware** (registered in `server.js` after `cookieParser`):

Every HTTP request is logged on response finish with method, URL, status code, and duration:

```json
{ "level": "info", "message": "GET /api/movies", "method": "GET", "url": "/api/movies", "status": 200, "duration": "23ms", "timestamp": "2026-04-05T16:00:00.000Z" }
```

**Viewing logs on Vercel:**  
Vercel dashboard → Project → **Functions** tab → select a function invocation → logs appear as structured JSON in the _Function Logs_ panel.

---

## Local Development Database

### Setup (April 2026)

For development, the project runs against a local **PostgreSQL 18** instance instead of Neon. The one-shot setup script at `docs/db_setup.sql` creates the full schema from scratch and is idempotent (safe to re-run).

**Connection string (`.env`):**
```
DATABASE_URL=postgresql://postgres:<password>@localhost:5432/cinema_hall_db
```

**SSL handling (`db.js`):**
```js
ssl: process.env.DATABASE_URL?.includes('localhost') ? false : { rejectUnauthorized: false }
```
SSL is disabled automatically for local connections and kept on for Neon.

### Running the Setup Script

```bash
# via psql
psql -U postgres -d cinema_hall_db -f docs/db_setup.sql

# or paste into pgAdmin Query Tool / Neon SQL Editor
```

> The script covers all tables, indexes, triggers, and the `settings` seed rows. It uses `CREATE TABLE IF NOT EXISTS` and `ADD COLUMN IF NOT EXISTS` everywhere — safe to run against an existing DB to apply missing columns.

### Schema Notes vs. Original `psql.sql`

| Issue in `psql.sql` | Fixed in `db_setup.sql` |
|---------------------|------------------------|
| `show_booked_seats` references `customers(id)` before `customers` is defined | Tables created in correct FK order |
| `cinema_admin_user` has no `role` column | `role VARCHAR(20) DEFAULT 'admin' CHECK (role IN ('admin','superAdmin'))` included |
| `otp_verifications.email` has no UNIQUE constraint | `UNIQUE` added — required for `ON CONFLICT (email)` upsert in `otp.Controller.js` |
| Multiple overlapping migration files | All changes consolidated into single idempotent script |

### Creating a SuperAdmin

```bash
# 1. Generate bcrypt hash
node -e "import('bcrypt').then(b => b.default.hash('YourPassword', 10).then(console.log))"

# 2. Insert in pgAdmin / psql
INSERT INTO cinema_admin_user (email, password, name, phone, role)
VALUES ('superadmin@cinemahall.com', '<hash>', 'Super Admin', '9999999999', 'superAdmin');
```

---

## Deployment

### Vercel Configuration

The API is configured for Vercel serverless deployment via `vercel.json`:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "server.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "server.js"
    }
  ],
  "crons": [
    {
      "path": "/api/cron/jobs",
      "schedule": "*/1 * * * *"
    }
  ]
}
```

**Why crons are required:**  
Vercel runs Express as **serverless functions** — there is no long-lived process. Any `setInterval` in `server.js` is killed when the function instance freezes between requests. The `setInterval` blocks are therefore guarded with `NODE_ENV !== 'production'` (local only). In production, Vercel Cron takes over and calls `GET /api/cron/jobs` every minute.

### CORS Configuration

Allowed origins:

- `http://localhost:5173` (Admin dev)
- `http://localhost:5174` (User dev)
- `http://localhost:5175` (Alternative)
- `https://cinema-hall-admin.vercel.app` (Production)

---

## Database Triggers & Functions

### Show Overlap Prevention

```sql
CREATE OR REPLACE FUNCTION prevent_overlapping_shows()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM shows
    WHERE screen_id = NEW.screen_id
      AND show_date = NEW.show_date
      AND (NEW.start_time, NEW.end_time) OVERLAPS (start_time, end_time)
      AND (id IS DISTINCT FROM NEW.id)
  ) THEN
    RAISE EXCEPTION 'Show overlaps with an existing show on the same screen.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prevent_overlap
BEFORE INSERT OR UPDATE ON shows
FOR EACH ROW
EXECUTE FUNCTION prevent_overlapping_shows();
```

### Show Status Lifecycle

Shows follow a controlled lifecycle. Admin-triggered transitions are manual; time-based transitions are automatic.

```
scheduled → booking_started → in_progress → show_ended
                ↘                  ↘
              (revert)           cancelled (with refunds)
```

| Transition | Trigger | Condition |
|---|---|---|
| `scheduled` → `booking_started` | Admin (PUT `/booking-status/:id` `open`) | Manual |
| `booking_started` → `scheduled` | Admin (PUT `/booking-status/:id` `revert`) | No confirmed bookings |
| `booking_started` → `in_progress` | Auto (background job) | `show_date = today AND start_time <= now < end_time` |
| `in_progress` → `show_ended` | Auto (background job) | `show_date < today` OR `end_time <= now` |
| `booking_started` → `show_ended` | Auto (background job) | Missed in_progress window; end_time passed |
| `scheduled` → `show_ended` | Auto (background job) | Never opened for booking; end_time passed |
| Any → `cancelled` | Admin (PUT `/cancel/:id`) | Not already `cancelled` or `show_ended` |

### Show Status Auto-Update (Background Job)

Show statuses transition automatically via three mechanisms:

**Middleware (Fallback)** — Called asynchronously on every request to the `/api/shows` route to compensate for any missed cron jobs in production:

```javascript
// server.js
app.use('/api/shows', (req, res, next) => {
  updateShowStatuses();
  next();
}, showsRoutes);
```

**Local development** — `setInterval` in `server.js` (only runs when `NODE_ENV !== 'production'`):

```javascript
// Runs every 30s (local only)
setInterval(async () => { await cleanupExpiredHolds(); }, 30000);

// Runs every 60s (local only)
setInterval(async () => { await updateShowStatuses(); }, 60000);
```

**Production (Vercel)** — Vercel Cron triggers `GET /api/cron/jobs` every minute:

```javascript
// server.js — cron route
app.get('/api/cron/jobs', async (req, res) => {
  // Protected by CRON_SECRET env var
  if (process.env.NODE_ENV === 'production' &&
      req.headers['authorization'] !== `Bearer ${process.env.CRON_SECRET}`) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  await cleanupExpiredHolds();
  await updateShowStatuses();
  res.status(200).json({ ok: true, time: new Date().toISOString() });
});
```

Vercel automatically injects `Authorization: Bearer <CRON_SECRET>` on cron invocations. Add `CRON_SECRET` as an environment variable in the Vercel project dashboard.

Times are compared in **IST (`Asia/Kolkata`)** since show times are stored in local time.

**Transient error handling:**  
Both `cleanupExpiredHolds` and `updateShowStatuses` silently skip their tick on transient DB connectivity errors (`ENOTFOUND`, `ECONNRESET`, `ETIMEDOUT`, `ECONNREFUSED`) and log a short warning instead of a full stack trace. Real unexpected errors still log the full error.

### Auto-Update Timestamp

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_customers_updated_at
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
```

---

## API Testing

### Sample cURL Commands

**Admin Login:**

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@cinema.com","password":"password123"}' \
  --cookie-jar cookies.txt
```

**Get Movies:**

```bash
curl http://localhost:5000/api/movies?status=now_showing&genre=Action
```

**Create Show:**

```bash
curl -X POST http://localhost:5000/api/shows/create \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "movie_id":"uuid",
    "screen_id":"uuid",
    "show_date":"2024-02-15",
    "start_time":"14:00:00",
    "end_time":"16:30:00"
  }'
```

---

## Performance Considerations

- **Connection Pooling**: PostgreSQL connection pool managed by `pg`
- **Indexing**: Primary keys (UUID), foreign keys, and unique constraints
- **Query Optimization**: JOIN queries for related data (admin + hall, shows + movies)
- **Pagination**: Implemented for all admin list endpoints (bookings, refunds, payment orders, customers, hall admins) and movies listing; `page` + `limit` query params (limit capped at 100, default 10, controlled by frontend rows-per-page selector)
- **JSONB**: Efficient storage for flexible data (layouts, price overrides)---

## 💳 Payment Integration (Razorpay)

The application integrates with Razorpay for secure online payments. The payment flow follows industry best practices with order creation, signature verification, and webhook handling.

### Payment Flow

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant Backend
    participant Razorpay
    participant Database

    User->>Frontend: Select seats & click "Pay"
    Frontend->>Backend: POST /api/booking/hold (seats)
    Backend->>Database: Hold seats for 5 minutes
    Database-->>Backend: Seats held
    Backend-->>Frontend: Hold confirmation

    Frontend->>Backend: POST /api/payment/create-order
    Backend->>Database: Verify seats still held
    Backend->>Razorpay: Create Order (amount, receipt)
    Razorpay-->>Backend: Order ID + Key
    Backend->>Database: Store order in payment_orders table
    Backend-->>Frontend: Order details

    Frontend->>Razorpay: Open checkout modal
    User->>Razorpay: Enter payment details
    Razorpay-->>Frontend: Payment success (order_id, payment_id, signature)

    Frontend->>Backend: POST /api/payment/verify (signature)
    Backend->>Backend: Verify Razorpay signature
    Backend->>Database: BEGIN TRANSACTION
    Backend->>Database: Update seats to BOOKED
    Backend->>Database: Create booking record
    Backend->>Database: Update payment_orders status
    Backend->>Database: COMMIT
    Backend-->>Frontend: Payment verified ✅
    Frontend->>User: Show success page

    Note over Razorpay,Backend: Webhook (Backup)
    Razorpay->>Backend: POST /api/payment/webhook (payment.captured)
    Backend->>Backend: Verify webhook signature
    Backend->>Database: Confirm booking (if not already done)
```

### Database Tables

#### payment_orders

Tracks Razorpay orders before payment completion.

```sql
CREATE TABLE payment_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id VARCHAR(255) UNIQUE NOT NULL,      -- Razorpay order ID
  show_id UUID NOT NULL REFERENCES shows(id),
  customer_id UUID NOT NULL REFERENCES customers(id),
  seats JSONB NOT NULL,                        -- ["A1", "A2"]
  amount DECIMAL(10, 2) NOT NULL,
  convenience_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
  gst_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
  status VARCHAR(20) DEFAULT 'created',        -- created, paid, failed, expired
  payment_id VARCHAR(255),                     -- Filled after payment
  payment_signature VARCHAR(500),
  offer_code VARCHAR(50),
  discount_amount NUMERIC(10, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### bookings

Final confirmed bookings after successful payment.

```sql
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES customers(id),
  show_id UUID NOT NULL REFERENCES shows(id),
  seats TEXT[] NOT NULL,                      -- seat IDs e.g. {"0-0", "1-1"}
  total_amount DECIMAL(10, 2) NOT NULL,       -- seat subtotal + convenience + GST - discount
  convenience_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
  gst_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
  payment_status VARCHAR(20) DEFAULT 'pending',
  payment_id VARCHAR(255) UNIQUE,                    -- Razorpay payment ID (idempotency key)
  booking_status VARCHAR(20) DEFAULT 'confirmed',
  offer_code VARCHAR(50),
  discount_amount NUMERIC(10, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### webhook_events

Deduplication table for Razorpay webhooks. Prevents multiple processing of the same event delivery.

```sql
CREATE TABLE webhook_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id VARCHAR(255) UNIQUE NOT NULL,      -- X-Razorpay-Event-Id
  event_type VARCHAR(50) NOT NULL,            -- e.g. payment.captured
  payload_hash VARCHAR(64) NOT NULL,          -- SHA-256 of raw body
  processed_at TIMESTAMPTZ DEFAULT now()
);
```

---

## 🔒 Idempotency & Race Condition Prevention

The booking and payment flow is hardened against double-payments, network retries, and concurrent processing.

### 1. Database-Level Protections
- **Booking Idempotency**: `bookings.payment_id` has a `UNIQUE` constraint. This is the final backstop against duplicate insertions during race conditions.
- **Seat Serialization**: `SELECT FOR UPDATE` is used inside transactions during webhook processing to lock the `payment_orders` row, ensuring only one delivery processes a specific order at a time.
- **Atomic Operations**: Releasing seats on failure is performed in a single atomic transaction using `DELETE FROM show_booked_seats WHERE ...` joined with the locked order data.

### 2. API-Level Protections
- **Order Deduplication**: `createOrder` checks for an existing `'created'` order for the same customer and show within the last 10 minutes before creating a new one in Razorpay.
- **Webhook Deduplication**: All incoming webhook events are logged in `webhook_events`. Subsequent deliveries of the same `X-Razorpay-Event-Id` are ignored using `ON CONFLICT DO NOTHING`.
- **Verify Idempotency**: `verifyPayment` returns the existing booking immediately if the order status is already `'paid'`, and uses `ON CONFLICT (payment_id) DO NOTHING` for parallel races.

### 3. Frontend Hardening
- **In-flight Guards**: `useRazorpayPayment.js` uses a `useRef` guard to synchronously prevent multiple clicks from initiating multiple payment flows, which React state cannot reliably block.

### 4. Webhook Reliability
- **Raw Body Preservations**: The webhook route uses `express.raw()` and the global JSON parser is bypassed for this path. This ensures the raw request bytes are preserved exactly for HMAC signature verification, preventing intermittent failures caused by re-serialization.


### API Endpoints

#### GET `/api/payment/admin/orders` *(Admin)*

Lists all Razorpay payment orders for shows in the admin's cinema hall. Supports filtering and pagination.

**Auth**: Admin required (`verifyCinemaAdminAccessToken` + `verifyCinemaHall`)

**Query Parameters:**

| Param       | Type   | Default | Description                                                           |
| ----------- | ------ | ------- | --------------------------------------------------------------------- |
| `from_date` | date   | —       | Show date range start (`YYYY-MM-DD`). Filters on `shows.show_date >=` |
| `to_date`   | date   | —       | Show date range end (`YYYY-MM-DD`). Filters on `shows.show_date <=`   |
| `status`    | string | —       | Filter by order status (`created`, `paid`, `failed`, `expired`)       |
| `customer`  | string | —       | Search by customer name or email (partial, case-insensitive)          |
| `movie`     | string | —       | Search by movie title (partial, case-insensitive)                     |
| `page`      | number | `1`     | Page number                                                           |
| `limit`     | number | `10`    | Results per page (max 100, controlled by frontend rows-per-page)      |

**Response (200):**

```json
{
  "orders": [
    {
      "id": "uuid",
      "order_id": "order_MlOhPxFJdD8SQy",
      "show_id": "uuid",
      "customer_id": "uuid",
      "seats": ["A1", "A2"],
      "amount": "440.00",
      "convenience_fee": "30.00",
      "gst_amount": "5.40",
      "status": "paid",
      "payment_id": "pay_MlOhsFJKxD8SQz",
      "offer_code": null,
      "discount_amount": "0.00",
      "created_at": "2026-03-06T08:30:00Z",
      "customer_name": "Jane Smith",
      "customer_email": "jane@example.com",
      "movie_title": "Paranthu Po",
      "show_date": "2026-03-06",
      "start_time": "11:00:00",
      "screen_name": "Screen 1"
    }
  ],
  "total": 85
}
```

---

#### 1. Create Payment Order

**POST** `/api/payment/create-order`

Creates a Razorpay order before initiating payment. **Amount is calculated server-side** — the frontend does not send an amount.

**Auth**: Customer required

**Request Body**:

```json
{
  "show_id": "550e8400-e29b-41d4-a716-446655440000",
  "seats": ["seatId1", "seatId2", "seatId3"]
}
```

**Server-Side Amount Calculation**:

1. Fetches `shows.price_override` and `screens.layout` (seats + pricing) from DB
2. Resolves per-seat price (price_override takes priority over layout.pricing)
3. Fetches `convenience_fee_per_ticket` and `gst_percentage` from `settings` table
4. Calculates:
   - `seatTotal = sum of per-seat prices`
   - `convenienceTotal = numSeats × convenience_fee_per_ticket`
   - `gstAmount = convenienceTotal × (gst_percentage / 100)`
   - `grandTotal = seatTotal + convenienceTotal + gstAmount`
5. Creates Razorpay order with `Math.round(grandTotal * 100)` paise
6. Stores `convenience_fee` and `gst_amount` in `payment_orders` for later retrieval during booking confirmation

**Response** (200 OK):

```json
{
  "order_id": "order_MlOhPxFJdD8SQy",
  "amount": 45270,
  "currency": "INR",
  "key_id": "rzp_test_XXXXXXXXXXXXX"
}
```

**Error Responses**:

| Status | Cause |
|--------|-------|
| `400` | Seats no longer held / hold expired / offer invalid |
| `502` | Razorpay gateway error (HTTP error from Razorpay API or network failure) |
| `500` | Unexpected server error |

> **Razorpay SDK error handling:** The `razorpay.orders.create()` call is wrapped in its own try-catch separate from the outer handler. The Razorpay SDK v2 has a known issue where network-level failures (no HTTP response — e.g. timeout, DNS failure) cause its internal `normalizeError` function to throw a `TypeError` instead of a structured error. The inner catch handles both shapes:
> - **HTTP errors** from Razorpay: `{ statusCode, error: { description, code } }`
> - **Network failures**: plain `Error` / `TypeError` (no `statusCode`)
>
> Both cases return `502` to the client with a generic message. The server logs include `statusCode` (if available) and the description/message for debugging.

**Validations**:

- Seats must still be held by requesting customer
- Hold must not be expired (< 5 minutes old)

#### 2. Verify Payment

**POST** `/api/payment/verify`

Verifies Razorpay payment signature and confirms booking.

**Auth**: Customer required

**Request Body**:

```json
{
  "razorpay_order_id": "order_MlOhPxFJdD8SQy",
  "razorpay_payment_id": "pay_MlOhsFJKxD8SQz",
  "razorpay_signature": "abc123...xyz"
}
```

**Response** (200 OK):

```json
{
  "success": true,
  "message": "Payment verified and booking confirmed!",
  "booking": {
    "id": "booking-uuid",
    "show_id": "show-uuid",
    "customer_id": "customer-uuid",
    "seats": ["A1", "A2", "A3"],
    "total_amount": "450.00",
    "payment_status": "completed",
    "payment_id": "pay_MlOhsFJKxD8SQz",
    "booking_status": "confirmed",
    "created_at": "2026-01-29T15:30:00Z"
  }
}
```

**Process** (Atomic Transaction):

1. Verify Razorpay signature using HMAC-SHA256
2. BEGIN TRANSACTION
3. Update `show_booked_seats`: status='BOOKED', clear hold
4. Insert into `bookings` table
5. Update `payment_orders`: status='paid'
6. COMMIT

#### 3. Webhook Handler

**POST** `/api/payment/webhook`

Receives webhook events from Razorpay (backup confirmation).

**Auth**: Webhook signature verification

**Events Handled**:

- `payment.captured` — Payment successful; confirms booking
- `payment.failed` — Payment failed; release seats
- `order.paid` — Order fully paid (backup confirmation)
- `refund.processed` — Razorpay has settled the refund; sets `refunds.refund_status = 'settled'` and `settled_at = NOW()`
- `refund.failed` — Razorpay refund failed; sets `refunds.refund_status = 'failed'` and stores `failure_reason`

**Signature Verification**:

```javascript
const expectedSignature = crypto
  .createHmac("sha256", RAZORPAY_WEBHOOK_SECRET)
  .update(JSON.stringify(req.body))
  .digest("hex");

if (expectedSignature !== req.headers["x-razorpay-signature"]) {
  return res.status(400).json({ error: "Invalid signature" });
}
```

### Environment Variables

Add to `.env`:

```bash
# Razorpay Test Mode Keys (Get from: https://dashboard.razorpay.com/app/keys)
RAZORPAY_KEY_ID=rzp_test_XXXXXXXXXXXXX
RAZORPAY_KEY_SECRET=your_secret_key_here
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret_here
```

**How to Get Keys**:

1. Sign up at [Razorpay Dashboard](https://dashboard.razorpay.com)
2. Navigate to Settings → API Keys
3. Generate Test Mode keys
4. For webhooks: Settings → Webhooks → Add Webhook URL
5. Copy the webhook secret

### Frontend Integration

**1. Load Razorpay Script** (`index.html`):

```html
<script src="https://checkout.razorpay.com/v1/checkout.js"></script>
```

**2. Initialize Payment** (React hook):

```javascript
const initiatePayment = async ({ show_id, seats, amount, customer }) => {
  // Step 1: Create order
  const orderRes = await fetch("/api/payment/create-order", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    credentials: "include",
    body: JSON.stringify({ show_id, seats, amount }),
  });
  const order = await orderRes.json();

  // Step 2: Open Razorpay checkout
  const options = {
    key: order.key_id,
    amount: order.amount,
    currency: order.currency,
    order_id: order.order_id,
    name: "CineMax",
    description: "Movie Ticket Booking",
    prefill: {
      name: customer.name,
      email: customer.email,
      contact: customer.phone,
    },
    handler: async (response) => {
      // Step 3: Verify payment
      const verifyRes = await fetch("/api/payment/verify", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          razorpay_order_id: response.razorpay_order_id,
          razorpay_payment_id: response.razorpay_payment_id,
          razorpay_signature: response.razorpay_signature,
        }),
      });

      if (verifyRes.ok) {
        const data = await verifyRes.json();
        // Navigate to success page with payment_id as query param
        navigate(`/booking/success?payment_id=${data.booking.payment_id}`);
      }
    },
  };

  const razorpay = new window.Razorpay(options);
  razorpay.open();
};
```

### Security Features

✅ **Implemented**:

- **Signature Verification**: All payments verified using HMAC-SHA256
- **Webhook Security**: Signature verification for webhook events
- **Hold Timeout**: Seats auto-release after 5 minutes
- **Atomic Transactions**: Database ACID compliance
- **Receipt ID Validation**: Max 40 chars, format: `TKT-{timestamp}-{customer}`
- **HTTPS Only**: Razorpay requires TLS 1.2+
- **Server-Side Amount Calculation**: `createOrder` ignores any frontend-provided amount — recalculates from DB seat prices + settings, preventing price tampering

⚠️ **Important**:

- Never expose `RAZORPAY_KEY_SECRET` in frontend code
- Always use Test Mode keys during development
- Set up IP whitelisting for webhook endpoints in production
- Implement idempotency to prevent duplicate bookings
- Log all payment attempts for audit trails

### Test Payment Details

For testing in Test Mode:

**Test Cards**:

```
Card:  4111 1111 1111 1111
CVV:   123
Expiry: Any future date (e.g., 12/25)
Name:   Test User
```

**Test UPI**: `success@razorpay`

**Test Wallets**: All wallets work in test mode

### Error Handling

| Error                  | Cause                | Solution                           |
| ---------------------- | -------------------- | ---------------------------------- |
| Invalid signature      | Wrong webhook secret | Check `RAZORPAY_WEBHOOK_SECRET`    |
| Order not found        | Order ID mismatch    | Verify order creation succeeded    |
| Seats no longer held   | Hold expired         | Refresh and select seats again     |
| Receipt too long       | Receipt > 40 chars   | Fixed: `TKT-{time}-{customer}`     |
| payment_orders missing | Migration not run    | Run `migration_payment_tables.sql` |
| convenience_fee missing | Migration not run   | Run `migration_fee_columns.sql`    |
| settings missing       | Migration not run    | Run `migration_settings.sql`       |
| Duplicate booking      | Race condition       | Use database unique constraints    |

### Migration

Run these SQL migrations in order:

```bash
psql -U postgres -d cinema_hall -f migration_payment_tables.sql
psql -U postgres -d cinema_hall -f migration_fee_columns.sql
```

`migration_fee_columns.sql` adds `convenience_fee` and `gst_amount` columns to both `payment_orders` and `bookings`. Existing rows default to `0`.

`migration_refunds.sql` creates the `refunds` table and its indexes. Must be run before deploying the show cancellation refund feature.

---

## 💸 Refunds API

Tracks per-booking refund lifecycle for cancelled shows. All endpoints require `verifyCinemaHall` middleware.

### `refunds` Table

```sql
CREATE TABLE refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  payment_id VARCHAR(255) NOT NULL,       -- Razorpay payment_id (pay_xxx)
  razorpay_refund_id VARCHAR(255),        -- Razorpay refund ID (rfnd_xxx), set after API call
  amount DECIMAL(10, 2) NOT NULL,
  refund_status VARCHAR(30) NOT NULL DEFAULT 'initiated'
    CHECK (refund_status IN ('initiated', 'settled', 'failed')),
  initiated_at TIMESTAMPTZ DEFAULT NOW(),
  settled_at TIMESTAMPTZ,
  failure_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**`refund_status` lifecycle:**

| Status | Set when |
|--------|----------|
| `initiated` | Row inserted inside `cancelShow` transaction |
| `settled` | Razorpay fires `refund.processed` webhook OR admin manually settles |
| `failed` | Razorpay API call threw an error OR `refund.failed` webhook |

### Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/refunds` | Admin | List all refunds (filterable by `status`, paginated; limit via `?limit=`) |
| GET | `/api/refunds/booking/:booking_id` | Admin | Get refund record for a specific booking |
| POST | `/api/refunds/:refund_id/settle` | Admin | Manually mark refund as settled |

#### GET `/api/refunds`

**Query params:** `status` (`initiated` | `settled` | `failed` | `all`), `from_date` (`YYYY-MM-DD`, filters on `initiated_at >=`), `to_date` (`YYYY-MM-DD`, filters on `initiated_at <=`), `page` (default 1), `limit` (default 10, max 100)

**Response (200):**

```json
{
  "refunds": [
    {
      "refund_id": "uuid",
      "booking_id": "uuid",
      "payment_id": "pay_xxx",
      "razorpay_refund_id": "rfnd_xxx",
      "amount": "1088.50",
      "refund_status": "initiated",
      "initiated_at": "2026-04-03T10:15:00Z",
      "settled_at": null,
      "failure_reason": null,
      "movie_title": "Dhurandhar The Revenge",
      "show_date": "2026-04-03",
      "start_time": "14:30:00",
      "screen_name": "Imax Screen 2",
      "customer_name": "Duraimurugan Don H",
      "customer_email": "durai@gmail.com",
      "seat_labels": ["D12", "D13", "D14", "D15", "D16"]
    }
  ],
  "total": 5
}
```

#### POST `/api/refunds/:refund_id/settle`

Manually marks a refund as `settled`. Use when the Razorpay `refund.processed` webhook was missed (e.g. ngrok was down in development, server was restarting).

Returns `400` if already settled.

**Response (200):** `{ "message": "Refund marked as settled" }`

### Monitoring & Logs

**Backend Logs**:

```bash
✅ Create order success: order_MlOhPxFJdD8SQy
✅ Payment verified: pay_MlOhsFJKxD8SQz
📥 Webhook received: payment.captured
✅ Webhook: Order order_MlOhPxFJdD8SQy confirmed
```

**Razorpay Dashboard**:

- View all orders and payments
- Track settlement status
- Monitor webhook delivery
- Download transaction reports

### Future Enhancements

- ~~🔄 Automatic refunds for cancelled bookings~~ ✅ Implemented (Refunds system with `refunds` table + Razorpay webhook settlement)
- 📧 Email receipts after successful payment
- 📱 QR code generation for ticket verification
- 💰 Partial payments and split payments
- ~~🎫 Discount codes and promotional offers~~ ✅ Implemented (Offers system)
- 📊 Revenue analytics dashboard

---

## Security Best Practices

✅ **Implemented:**

- Password hashing with bcrypt
- JWT tokens in HttpOnly cookies
- CORS with whitelist
- SQL injection prevention (parameterized queries)
- Role-based access control
- Token expiration and refresh mechanism

⚠️ **Recommendations:**

- Add rate limiting (e.g., express-rate-limit)
- Implement request validation (e.g., Joi, Zod)
- Add API logging (e.g., Winston, Morgan)
- Set up monitoring (e.g., Sentry)
- Add input sanitization
- Implement CSRF protection for state-changing operations

---

**Last Updated**: May 31, 2026 — Admin Auth Security Upgrade: Complete auth system overhaul with email verification, forgot/reset password, change password, brute-force lockout (5→15min, 10→60min, 15→24hr), server-side session revocation via `admin_sessions` table (refresh tokens stored as SHA-256 hashes), password policy enforcement (8+ chars, uppercase, lowercase, digit, special char), full security audit log (`admin_security_logs`), 7 new auth routes, 4 new DB tables, `nodemailer` dependency added. Environment variables `ADMIN_FRONTEND_URL=http://localhost:5174` and `USER_FRONTEND_URL=http://localhost:5173` added.

**May 31, 2026 (Bug fixes)** — Three post-migration fixes:
1. **Migration data fix** (`migration_auth_security.sql`): Added `UPDATE cinema_admin_user SET email_verified = TRUE, email_verified_at = now() WHERE email_verified = FALSE` immediately after the `ALTER TABLE` block so that any pre-existing admin rows (created before the migration was run) are automatically marked as verified on a fresh install — preventing those accounts from being locked out.
2. **Transaction safety** (`auth.Controller.js`): Fixed broken `pool.query('BEGIN')` / `pool.query('COMMIT')` patterns in `verifyAdminEmail`, `resetPassword`, and `changePassword`. With `pg.Pool`, each `pool.query()` can grab a different connection, meaning BEGIN/COMMIT ran on different connections than the intermediate queries (no atomicity). All three now use `pool.connect()` to check out a single client and run all queries on that client before calling `client.release()`.

**June 5, 2026 (Bug fix — `validatePassword` return type mismatch)** — `validatePassword` in `utils/passwordPolicy.js` returns `string | null` (error message if invalid, `null` if valid). However, `auth.Controller.js` was calling it and treating the result as `{ valid, message }`, causing a `TypeError: Cannot read properties of null (reading 'valid')` whenever a valid password was submitted. Fixed all three call sites in `auth.Controller.js` — `registerCinemaAdmin` (line 54), `resetPassword` (line 483), and `changePassword` (line 556) — to use the correct `const passwordError = validatePassword(...); if (passwordError) { ... }` pattern, consistent with how `customerAuth.Controller.js` already used it.
