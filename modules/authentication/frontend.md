# Authentication - Frontend

## Admin App (`cinema-hall-admin`)

### Pages

#### `AuthPage.jsx`
- **Path**: `src/pages/Auth/AuthPage.jsx`
- **Purpose**: Container page for all admin authentication flows (login, register, forgot password, verify email, reset password)
- **Dependencies**: framer-motion (slide transitions), lucide-react (icons)
- **State**: Tracks current `view` ('login' | 'forgot-password' | 'register' | 'verify-email' | 'reset-password'), animates between views with spring transitions
- **Data Flow**: Reads view from parent, renders corresponding form component

#### `LoginForm.jsx`
- **Path**: `src/pages/Auth/LoginForm.jsx`
- **Purpose**: Admin login with email/password, Google OAuth, and GitHub OAuth
- **State**: email, password, showPassword, loading, error, oauthLoading
- **API Usage**: `authAPI.login()`, `authAPI.googleLogin()`, `authAPI.githubLogin()`
- **Data Flow**: Calls `useAuth().login()` context method, handles ACCOUNT_LOCKED, EMAIL_NOT_VERIFIED errors
- **Password visibility toggle** (`3e043c5d`): `showPassword` state flips the input between `type="text"` and `type="password"`; a trailing `Eye`/`EyeOff` button (`pr-11`, `tabIndex={-1}`) toggles it

#### `RegisterForm.jsx`
- **Path**: `src/pages/Auth/RegisterForm.jsx`
- **Purpose**: New admin registration form
- **State**: name, email, phone, password, confirmPassword
- **API Usage**: `authAPI.register()`
- **Data Flow**: Validates password policy client-side, calls context register, redirects to verify email

#### `ForgotPasswordForm.jsx`
- **Path**: `src/pages/Auth/ForgotPasswordForm.jsx`
- **Purpose**: Request password reset email
- **API Usage**: `authAPI.forgotPassword()`
- **Data Flow**: Sends email, shows success message

#### `ResetPasswordForm.jsx`
- **Path**: `src/pages/Auth/ResetPasswordForm.jsx`
- **Purpose**: Set new password using token from email link
- **API Usage**: `authAPI.resetPassword()`
- **Data Flow**: Reads token from URL query params, validates new password, submits reset

#### `VerifyEmailForm.jsx`
- **Path**: `src/pages/Auth/VerifyEmailForm.jsx`
- **Purpose**: Verify admin email using token from email link
- **API Usage**: `authAPI.verifyEmail()`, `authAPI.resendVerification()`
- **Data Flow**: Reads token from URL, verifies, redirects to login

#### `GitHubCallback.jsx`
- **Path**: `src/pages/Auth/GitHubCallback.jsx`
- **Purpose**: Handles GitHub OAuth redirect callback, extracts code from URL
- **API Usage**: `authAPI.githubLogin()`
- **Data Flow**: Reads `code` param, exchanges for session

### Context

#### `AuthContext.jsx`
- **Path**: `src/context/AuthContext.jsx`
- **Purpose**: Global auth state for admin app
- **State**: `user`, `cinemaHall`, `loading`
- **Methods**: `login()`, `logout()`, `register()`, `updateHall()`, `changePassword()`, `logoutAllDevices()`, `googleLogin()`, `githubLogin()`, `refreshUser()`
- **Properties**: `isLoggedIn`, `isSuperAdmin`, `emailVerified`
- **API Usage**: `authAPI.getMe()`, `authAPI.refresh()`
- **Data Flow**: On mount, tries `getMe()` → on failure, tries `refresh()` → retries `getMe()`

### Routes/Guards

#### `ProtectedRoutes.jsx`
- **Path**: `src/routes/ProtectedRoutes.jsx`
- **Purpose**: Requires authenticated user, optionally verified email
- **Data Flow**: If `!user` → redirect to `/login`, if `!email_verified` → redirect to `/verify-email`

#### `AdminProtectedRoutes.jsx`
- **Path**: `src/routes/AdminProtectedRoutes.jsx`
- **Purpose**: Requires auth + optionally super admin + optionally permission check
- **Props**: `permission`, `requireSuperAdmin`
- **Data Flow**: If `!user` → login. If `requireSuperAdmin && !isSuperAdmin` → unauthorized. If `!user.orgId` → onboarding. If `permission && !can(permission)` → unauthorized.

#### `HallGuard.jsx`
- **Path**: `src/routes/HallGuard.jsx`
- **Purpose**: Requires at least one cinema hall to access routes
- **Data Flow**: If staff role → pass. If no halls → redirect to `/onboarding`

### Services

#### `api.js` (authAPI section)
- **Path**: `src/services/api.js`
- **Purpose**: HTTP client for admin auth endpoints
- **Methods**: `register`, `login`, `logout`, `getMe`, `refresh`, `updateHall`, `completeOnboarding`, `verifyEmail`, `resendVerification`, `forgotPassword`, `resetPassword`, `changePassword`, `logoutAllDevices`, `getSecurityInfo`, `googleLogin`, `githubLogin`, `linkProvider`, `unlinkProvider`, `setPassword`
- **Base URL**: `VITE_API_BASE_URL` env var (default: `http://localhost:5000`)

---

## User App (`cinema-hall-users`)

### Components

#### `LoginModal.jsx`
- **Path**: `src/components/LoginModal.jsx`
- **Purpose**: Modal dialog for customer login and signup (tab-based)
- **State**: Login form fields, signup form fields, OTP state, error/loading, account lockout display
- **Hooks**: `useGoogleLogin()`, `useCustomerAuth()`
- **Dependencies**: shadcn/ui Dialog, Tabs, InputOTP, sonner toast
- **Data Flow**: Login → `useCustomerAuth().login()` → handles ACCOUNT_LOCKED, unverified accounts → sends OTP for unverified accounts. Signup → validates fields → calls `useCustomerAuth().signup()` → sends OTP → verifies OTP via `customerAuthAPI.verifyOtp()`

### Context

#### `CustomerAuthContext.jsx`
- **Path**: `src/context/CustomerAuthContext.jsx`
- **Purpose**: Global auth state + location detection for customers
- **State**: `customer`, `loading`, `district`, `state`, `locationLoading`
- **Methods**: `login()`, `logout()`, `signup()`, `update()`, `changePassword()`, `googleLogin()`, `refreshCustomer()`, `fetchLocationDetails()`, `updateProfileWithLocation()`, `setLocationManually()`
- **Properties**: `isLoggedIn`
- **API Usage**: `customerAuthAPI.getMe()`, `customerAuthAPI.refresh()`
- **Extra**: Geolocation detection on mount using BigDataCloud reverse geocode API, caches in localStorage for 24h

### Services

#### `api.js` (customerAuthAPI section)
- **Path**: `src/services/api.js`
- **Purpose**: HTTP client for customer auth endpoints
- **Methods**: `signup`, `login`, `logout`, `update`, `getMe`, `refresh`, `sendOtp`, `verifyOtp`, `forgotPassword`, `resetPassword`, `changePassword`, `googleLogin`, `linkProvider`, `unlinkProvider`, `setPassword`

### Routes/Guards

#### `ProtectedRoutes.jsx`
- **Path**: `src/routes/ProtectedRoutes.jsx`
- **Purpose**: Requires authenticated customer
- **Data Flow**: If `!customer` → redirect to `/`
