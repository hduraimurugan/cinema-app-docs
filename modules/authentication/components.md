# Authentication - Components

## Admin App Component Hierarchy

```
App
 └── AuthContext.Provider
      └── PermissionContext.Provider
           └── HallContext.Provider
                └── Routes
                     ├── AuthPage (view="login" | "register" | "forgot-password" | "verify-email" | "reset-password")
                     │    ├── LeftPanel (static brand/features display)
                     │    └── AnimatePresence (framer-motion slide transitions)
                     │         └── LoginForm | RegisterForm | ForgotPasswordForm | VerifyEmailForm | ResetPasswordForm
                     │
                     ├── AdminProtectedRoute (guards: auth + superadmin + permission + org)
                     │    └── HallGuard (guards: has halls)
                     │         └── App Layout
                     │              ├── Sidebar
                     │              ├── HallSwitcher
                     │              └── Page Content
                     │
                     └── GitHubCallback (handles OAuth redirect)
```

### Component Catalog

| Component | File | Props | State | Parent | Children |
|-----------|------|-------|-------|--------|----------|
| `AuthPage` | `pages/Auth/AuthPage.jsx` | `view` | prevView, direction | Routes | LeftPanel, AnimatePresence → forms |
| `LoginForm` | `pages/Auth/LoginForm.jsx` | none | email, password, showPassword, loading, error, oauthLoading | AuthPage | shadcn form components |
| `RegisterForm` | `pages/Auth/RegisterForm.jsx` | none | name, email, phone, password, confirmPassword | AuthPage | shadcn form components |
| `ForgotPasswordForm` | `pages/Auth/ForgotPasswordForm.jsx` | none | email, submitted | AuthPage | shadcn form components |
| `ResetPasswordForm` | `pages/Auth/ResetPasswordForm.jsx` | none | token, password, confirm | AuthPage | shadcn form components |
| `VerifyEmailForm` | `pages/Auth/VerifyEmailForm.jsx` | none | token, verified, error | AuthPage | shadcn form components |
| `GitHubCallback` | `pages/Auth/GitHubCallback.jsx` | none | code (from URL) | Routes | Loading spinner |
| `ProtectedRoute` | `routes/ProtectedRoutes.jsx` | children | user, loading (from context) | Route | children |
| `AdminProtectedRoute` | `routes/AdminProtectedRoutes.jsx` | children, permission?, requireSuperAdmin? | user, loading, isSuperAdmin, can | Route | children |
| `HallGuard` | `routes/HallGuard.jsx` | children | halls, hallsLoading | Route | children |

### Contexts Used

| Context | File | Provides To | Key Values |
|---------|------|-----------|------------|
| `AuthContext` | `context/AuthContext.jsx` | All admin components | user, cinemaHall, isLoggedIn, isSuperAdmin, login, logout, register, googleLogin, githubLogin, changePassword, logoutAllDevices, refreshUser |
| `PermissionContext` | `context/PermissionContext.jsx` | All admin components | can(permission), permissions, roleKey |
| `HallContext` | `context/HallContext.jsx` | All admin components | halls, currentHall, setCurrentHall, hallsLoading |
| `CustomerAuthContext` | `context/CustomerAuthContext.jsx` (user app) | All user components | customer, isLoggedIn, district, state, login, logout, signup, googleLogin, fetchLocationDetails |

---

## User App Component Hierarchy

```
App
 └── CustomerAuthContext.Provider
      └── Routes
           ├── LoginModal (dialog overlay)
           │    ├── Tabs (Login | Signup)
           │    │    ├── LoginForm
           │    │    └── SignupForm → OTP Verification
           │    ├── Google OAuth Button
           │    └── Account Locked Banner
           │
           └── ProtectedRoute (customer guard)
                └── User Layout
                     ├── TopNavbar (shows login state, profile link)
                     ├── LocationModal
                     └── Page Content
```

### Component Catalog (User App)

| Component | File | Props | State | Parent |
|-----------|------|-------|-------|--------|
| `LoginModal` | `components/LoginModal.jsx` | open, onOpenChange | loginData, signupData, activeTab, otpSent, otpTimer, loading, error, lockedUntil | Layout/App |
| `PasswordPolicyChecklist` | `components/LoginModal.jsx` (inline) | password | - | LoginModal (signup tab) |
| `ProtectedRoute` | `routes/ProtectedRoutes.jsx` | children | customer, loading | Route |
