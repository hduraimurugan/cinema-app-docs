# Notifications & OTP - API

## OTP Endpoints

### POST `/api/otp/send`
- **Description**: Generate and send a 6-digit OTP to the customer's email
- **Auth**: Public (no middleware)
- **Body**:
  ```json
  {
    "email": "customer@example.com",
    "type": "signup"
  }
  ```
- **Type options**: `"signup"` | `"password_reset"`
- **Success (200) — signup**:
  ```json
  { "message": "OTP sent successfully" }
  ```
- **Success (200) — password_reset** (even if email unknown — prevents enumeration):
  ```json
  { "message": "If an account with that email exists, an OTP has been sent." }
  ```
- **Errors**:
  | Status | Code | Condition |
  |--------|------|-----------|
  | 400 | - | Missing email |
  | 400 | - | Invalid OTP type |
  | 404 | - | Customer not found (signup type only) |
  | 429 | - | Rate limit exceeded (3 per 10 min per email+type) |
  | 500 | - | Server error or email send failure |

### POST `/api/otp/verify`
- **Description**: Verify an OTP submitted by the customer
- **Auth**: Public (no middleware)
- **Body**:
  ```json
  {
    "email": "customer@example.com",
    "otp": "483920",
    "type": "signup"
  }
  ```
- **Success (200) — signup**:
  ```json
  { "message": "OTP verified successfully. Account activated!" }
  ```
- **Success (200) — password_reset**:
  ```json
  { "message": "OTP verified successfully." }
  ```
- **Errors**:
  | Status | Code | Condition |
  |--------|------|-----------|
  | 400 | - | Missing email or OTP |
  | 400 | - | OTP already used (`is_verified = true`) |
  | 400 | `OTP_EXPIRED` | OTP has expired (past `expires_at`) |
  | 400 | `OTP_ATTEMPTS_EXCEEDED` | Max wrong attempts (5) reached |
  | 400 | - | Invalid OTP (with remaining attempts count) |
  | 404 | - | No OTP record found for (email, type) |
  | 500 | - | Server error |
- **Error body examples**:
  ```json
  { "code": "OTP_EXPIRED", "error": "OTP has expired. Please request a new one." }
  ```
  ```json
  { "code": "OTP_ATTEMPTS_EXCEEDED", "error": "Too many incorrect attempts. Please request a new OTP." }
  ```
  ```json
  { "error": "Invalid OTP. 3 attempts remaining." }
  ```
