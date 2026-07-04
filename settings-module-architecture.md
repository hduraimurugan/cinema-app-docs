# Settings Module Architecture — Cinema Management Platform

**Status:** Phase 1 (MVP) Complete · **Grounded in:** cinema-hall-api (PostgreSQL/Express), cinema-hall-admin (React 19/shadcn/ui) · **Decisions:** PostgreSQL, React Context, Organization layer introduced, `organizations.name` as source of truth for org name

---

## 0. Current-State Baseline (what we're extending)

| Concern | Phase 0 (Pre-MVP) | Phase 1 (MVP) Delivered |
|---|---|---|---|
| Settings storage | `settings` key/value table, 2 keys (`convenience_fee_per_ticket`, `gst_percentage`) | `organization_settings`, `hall_settings`, `user_settings` JSONB tables per scope; legacy table kept for backward compat |
| RBAC | `cinema_admin_user.role` ∈ `{'admin','superAdmin'}` + `verifySuperAdmin` only | Unchanged (Phase 2) |
| Multi-hall | `cinema_hall.admin_id` FK (1 admin : N halls), `X-Hall-Id` header + `requireActiveHall` | `organizations` table added with `owner_id` FK; `resolveOrgId` auto-creates org for admin; hall settings scoped by `hall_id` |
| Audit | `admin_security_logs` (auth events only) + `logSecurityEvent()` | Unchanged (Phase 4) |
| Frontend | `SettingsPage.jsx` — single Card, 2 fields, in-page `isSuperAdmin` gate | `SettingsLayout` with 5 section pages (General, Cinema Profile, Showtimes, Booking, Payment) + nested routing; dirty-dot tracking in sidebar; loading/error states |
| State | `AuthContext`, `HallContext`, `ThemeContext` (React Context, plain `fetch`) | `SettingsProvider` added — org/hall/user cache, dirty tracking, optimistic update, save/reset |
| Security | Account lockout (hardcoded thresholds), password policy (hardcoded), session revocation | Unchanged (Phase 3) |

---

## 1. Information Architecture

Settings are split into **three scopes** (matching the existing `offers.scope` precedent):

| Scope | Owner | Applies to | Example |
|---|---|---|---|
| **Organization** (`org`) | Super Admin / Owner | All branches in the org | Currency, timezone, branding, payment keys |
| **Hall** (`hall`) | Admin / Manager | One cinema branch | Showtime buffers, booking limits, F&B menu |
| **User** (`user`) | The individual | One admin user | Notification preferences, dashboard layout, theme override |

### Categories & Subcategories

| # | Category | Scope | Purpose |
|---|---|---|---|
| 1 | **General Settings** | org | Platform identity: org name, default timezone, currency, date/number format, default language. Single source of truth so every branch formats consistently. |
| 2 | **Cinema Profile** | hall | Per-branch identity: name, location, district, state, lat/long, phone, description, operating hours. Extends existing `cinema_hall` columns + `PATCH /api/auth/hall`. |
| 3 | **Showtimes Settings** | hall | Operational defaults: default show buffer (mins between shows), overlap-prevention toggle, auto-status-transition timing (currently cron-driven, hardcoded IST), default language version. Avoids per-show manual config. |
| 4 | **Booking Settings** | hall | Seat-hold duration (currently hardcoded 5 min), max seats per booking (currently 1–10 in UI, no DB rule), advance-booking window (days ahead), booking-open lead time. Directly affects `show_booked_seats.hold_expires_at` + cron. |
| 5 | **Ticket Settings** | org | Ticket/QR/PDF config: booking ID prefix, ticket template, QR error-correction level, PDF footer text, "printed by" attribution. Branding-consistent across branches. |
| 6 | **Payment Settings** | org | Razorpay key/secret (encrypted), webhook secret, convenience-fee model (flat/tiered/per-ticket), GST %, accepted payment methods, refund auto-trigger rules. Generalizes the existing 2-key `settings` table. |
| 7 | **Offers & Promotions** | org/hall | Default offer scope, max redemptions per customer, default validity window, coupon auto-generation rules. Extends existing `offers` table config without changing its schema. |
| 8 | **Notification Settings** | org/user | Provider config (SMTP/SMS/WhatsApp/push) at org level; per-user channel toggles + per-event preferences. Three-tier hierarchy: org → role → user. |
| 9 | **Security & Login** | org | Password policy (min length, complexity — currently hardcoded in `passwordPolicy.js`), lockout thresholds (currently hardcoded 5/10/15), session timeout, MFA enforcement, IP allowlists. Makes existing hardcoded policies DB-driven and per-org tunable. |
| 10 | **Team Management** | org | Invite team members, assign roles, assign hall scope, revoke access. The operational UI for RBAC. Currently absent — `getAllAdmins` is read-only SuperAdmin view. |
| 11 | **Roles & Permissions** | org | Define custom roles, edit permission matrix, scope permissions to resources/halls. The configuration UI for RBAC. |
| 12 | **Theme & Branding** | org | Logo, banner, primary/accent colors (extends oklch tokens), font, dark/light default, white-label toggle. Per-org theming for SaaS readiness. |
| 13 | **Analytics Preferences** | user | Dashboard widget selection, KPI ordering, report schedule, date-range defaults. Per-user personalization. |
| 14 | **Integrations** | org | API keys + status for Razorpay, TMDB, Cloudinary, email provider, SMS provider, MCP server. Centralized credential management (currently scattered across `.env`). |
| 15 | **Audit Logs** | org | Security logs (existing `admin_security_logs`), settings-change history, user-activity logs. View + export + retention config. |
| 16 | **Advanced Settings** | org | Feature flags, experimental toggles, API key generation, webhook endpoints, data export, danger zone (delete org/hall). Power-user controls. |

---

## 2. Frontend Architecture

### 2.1 Route Structure

Keep `/settings` as the entry (already wired in `AppSidebar.jsx` `systemItems`). Use **nested routes** with a shared `<SettingsLayout>` that renders the section sidebar + `<Outlet/>`. This scales better than tabs when sections grow (tabs get cramped past 6–7 items).

```
/settings                         → redirect to /settings/general           ✅ Phase 1
/settings/general                 → GeneralSettingsPage                     ✅ Phase 1
/settings/cinema-profile          → CinemaProfilePage        (hall-scoped)  ✅ Phase 1
/settings/showtimes               → ShowtimesSettingsPage    (hall-scoped)  ✅ Phase 1
/settings/booking                 → BookingSettingsPage      (hall-scoped)  ✅ Phase 1
/settings/payment                 → PaymentSettingsPage                     ✅ Phase 1
/settings/tickets                 → TicketSettingsPage                      ❌ Phase 2+
/settings/offers                  → OffersSettingsPage                      ❌ Phase 2+
/settings/notifications           → NotificationSettingsPage                ❌ Phase 3+
/settings/security                → SecuritySettingsPage                    ❌ Phase 3+
/settings/team                    → TeamManagementPage       (permission-gated) ❌ Phase 2
/settings/roles                   → RolesPermissionsPage     (permission-gated) ❌ Phase 2
/settings/branding                → ThemeBrandingPage                       ❌ Phase 4
/settings/analytics               → AnalyticsPrefsPage                      ❌ Phase 3+
/settings/integrations            → IntegrationsPage                        ❌ Phase 4
/settings/audit-logs              → AuditLogsPage                           ❌ Phase 4
/settings/advanced                → AdvancedSettingsPage                    ❌ Phase 4
```

`/settings` stays in `HallGuard.EXEMPT_PATHS` (already is). Hall-scoped sections read `useHall().activeHall` and use `hallFetch`; org-scoped sections use plain `fetch`. Team/Roles pages use permission-gating driven by **permissions**, not just `isSuperAdmin`.

**Layout pattern (Phase 1):** The `<SettingsLayout>` renders a 64-unit-wide sticky sidebar with grouped nav items ("Organization" / "Cinema Branch") and a floating save bar at the bottom-right of the content area. The sidebar is `sticky top-0 h-[calc(100vh-4rem)]` — it stays fixed while the page scrolls. No nested scroll containers: the parent `<CinemaLayout>` provides the single page-level scroll container, avoiding double scrollbars.

### 2.2 Sidebar Structure

Extend `systemItems` in `AppSidebar.jsx` into a collapsible **Settings group**:

```
System
└─ Settings (expandable)
   ├─ General
   ├─ Cinema Profile
   ├─ Showtimes
   ├─ Booking
   ├─ Tickets
   ├─ Payment
   ├─ Offers & Coupons
   ├─ Notifications
   ├─ Security & Login
   ├─ Team           🔒 (permission: team.manage)
   ├─ Roles          🔒 (permission: roles.manage)
   ├─ Theme & Branding
   ├─ Analytics
   ├─ Integrations
   ├─ Audit Logs
   └─ Advanced
```

Filter via `item.permission` against a new `usePermissions()` hook (see §2.4). Items with no matching permission are omitted — same pattern as existing `item.roles` filtering.

### 2.3 Tab Structure (within section pages)

Each section page uses the existing `Tabs` primitive (pattern from `MovieManagement.jsx`) for sub-sections where needed. Example — Payment Settings:

```
Payment Settings
├─ Tab: Fees & Taxes      (convenience fee model, GST %, state tax)
├─ Tab: Razorpay          (key/secret, webhook secret, test mode)
├─ Tab: Refund Rules      (auto-refund window, partial refund, penalty %)
└─ Tab: Payment Methods   (UPI, cards, netbanking toggles)
```

ProfilePage-style stacked `<section>` + `<Separator/>` is the alternative for simple sections (General, Cinema Profile).

### 2.4 Permission-Based Visibility

New `PermissionContext` exposing:

```js
const { can } = usePermissions();
// can('settings.payment.update') → boolean
// can('settings.team.manage')    → boolean
```

Driven by the RBAC system (§4). The backend embeds a `permissionsVersion` in the JWT payload. Full permissions are loaded from `/api/auth/me` response. UI uses `can()` to:
- Filter sidebar items
- Gate section routes (redirect to `/unauthorized`)
- Toggle edit vs read-only within a page (replacing the current `isSuperAdmin` check)

### 2.5 React Component Hierarchy & Folder Structure

```
src/
├── pages/settings/
│   ├── SettingsLayout.jsx              ✅ # sticky sidebar (grouped nav) + <Outlet/> + floating save bar
│   ├── GeneralSettingsPage.jsx         ✅
│   ├── CinemaProfilePage.jsx           ✅
│   ├── ShowtimesSettingsPage.jsx       ✅
│   ├── BookingSettingsPage.jsx         ✅
│   ├── TicketSettingsPage.jsx          ❌ Phase 2+
│   ├── PaymentSettingsPage.jsx         ✅
│   ├── OffersSettingsPage.jsx          ❌ Phase 2+
│   ├── NotificationSettingsPage.jsx    ❌ Phase 3+
│   ├── SecuritySettingsPage.jsx        ❌ Phase 3+
│   ├── TeamManagementPage.jsx          ❌ Phase 2
│   ├── RolesPermissionsPage.jsx        ❌ Phase 2
│   ├── ThemeBrandingPage.jsx           ❌ Phase 4
│   ├── AnalyticsPrefsPage.jsx          ❌ Phase 3+
│   ├── IntegrationsPage.jsx            ❌ Phase 4
│   ├── AuditLogsPage.jsx               ❌ Phase 4
│   └── AdvancedSettingsPage.jsx        ❌ Phase 4
├── components/settings/
│   ├── SettingsSidebar.jsx              ❌ Phase 2 (sidebar inline in SettingsLayout)
│   ├── SettingsForm.jsx                 ❌ Phase 2+
│   ├── SettingsField.jsx                ❌ Phase 2+
│   ├── UnsavedChangesBanner.jsx         ❌ Phase 2+
│   ├── SettingsSearch.jsx               ❌ Phase 4
│   ├── DiffViewer.jsx                   ❌ Phase 4
│   ├── sections/                        ❌ Phase 2+
│   │   ├── FeesTaxesTab.jsx
│   │   ├── RazorpayTab.jsx
│   │   ├── RefundRulesTab.jsx
│   │   ├── TeamInviteDialog.jsx
│   │   ├── RoleEditorDialog.jsx
│   │   ├── PermissionMatrixTable.jsx
│   │   ├── BrandingUploader.jsx
│   │   └── ...
├── components/settings/
│   ├── SettingsPageHeader.jsx          ✅ # icon + title + description + scope badge (org/hall/user)
│   ├── SettingsCard.jsx                ✅ # card with icon header, border-b separator, shadow hover
├── context/
│   ├── SettingsContext.jsx              ✅ # settings cache + dirty tracking + optimistic update + save/reset
│   └── PermissionContext.jsx            ❌ Phase 2
├── hooks/settings/
│   ├── useSettings.js                   ❌ (logic inlined in SettingsContext)
│   ├── useSettingsMutation.js           ❌ (inlined in SettingsContext)
│   ├── useUnsavedChanges.js             ❌ Phase 2+
│   ├── useSettingsPermission.js         ❌ Phase 2
│   └── useSettingsVersion.js            ❌ Phase 4
├── services/settings/
│   ├── settingsService.js               ✅ # getOrg/Hall/User, updateOrg/Hall/User (6 methods)
│   ├── teamService.js                   ❌ Phase 2
│   ├── rolesService.js                  ❌ Phase 2
│   ├── auditService.js                  ❌ Phase 4
│   ├── integrationService.js            ❌ Phase 4
│   └── brandingService.js               ❌ Phase 4
└── lib/settings/
    ├── settingsSchema.js                ❌ Phase 2+
    ├── settingsDefaults.js              ✅ # default JSONB per scope/section (ORG_DEFAULTS, HALL_DEFAULTS, USER_DEFAULTS)
    ├── settingsRegistry.js              ❌ Phase 2+
    └── settingsMigrations.js            ❌ Phase 4
```

### 2.6 State Structure — `SettingsContext`

Mirrors the `HallContext` pattern. No Zustand.

```js
// SettingsContext state shape (Phase 1 implementation)
{
  // Cache — keyed by scope
  orgSettings:  { data: { [section]: value }, loading: bool, error: string | null },
  hallSettings: { [hallId]: { data: { [section]: value }, loading: bool, error: string | null } },
  userSettings: { data: { [section]: value }, loading: bool, error: string | null },

  // Dirty tracking (individual keys and aggregate)
  dirty: { ["org:general"]: true, ... },
  saving: { ["org:general"]: true, ... },

  // Actions
  getSection(scope, section),              // read cached section value
  updateSection(scope, section, patch),    // optimistic update (immediate)
  saveSection(scope, section),             // persist via API, clear dirty
  resetSection(scope, section),            // reload snapshot from API
  isSectionDirty(scope, section),          // single-section dirty check
  isSaving(scope, section),               // per-section saving status
}
```

**Cache strategy:** `SettingsProvider` prefetches org + user settings on mount (after `AuthProvider` resolves). Hall settings load lazily on hall switch via `useEffect` on `activeHall?.id`. Once loaded, hall settings are not re-fetched (tracked via `loadedHallIds` set).

**Dirty tracking (Phase 1):** Each section has its own dirty flag tracked via a module-level `dirtyMap` object. `updateSection` sets the flag and triggers `setDirty()`. `SettingsLayout` shows an `"unsaved"` `<Badge>` (amber-outline) next to section nav items that have unsaved edits — replaces the earlier red-dot design for better visibility. A separate "Unsaved changes" status badge appears in the floating save bar. No `beforeunload` guard yet (Phase 2+).

**Optimistic updates (Phase 1):** `updateSection` mutates context state immediately by spreading the patch into the section's current data. On API error from `saveSection`, the error propagates but no automatic rollback — user refreshes or resets manually.

**Settings versioning:** Not implemented in Phase 1. Deferred to Phase 4.

### 2.7 API Integration Structure

`services/settings/settingsService.js` (replaces the 2-method `settingsAPI` in `api.js`). Implemented in Phase 1:

```js
const API = `${import.meta.env.VITE_API_BASE_URL}/api/settings`;
const headers = { 'Content-Type': 'application/json' };

export const settingsService = {
  getOrgSettings:  ()        => fetch(`${API}/org`, { credentials:'include' }).then(unwrap),
  getHallSettings: (hallId)  => hallFetch(`${API}/hall/${hallId}`, { credentials:'include' }).then(unwrap),
  getUserSettings: ()        => fetch(`${API}/user`, { credentials:'include' }).then(unwrap),

  updateOrgSettings:  (section, patch) => fetch(`${API}/org`,  { method:'PATCH', credentials:'include', headers, body: JSON.stringify({ section, patch }) }).then(unwrap),
  updateHallSettings: (hallId, section, patch) => hallFetch(`${API}/hall/${hallId}`, { method:'PATCH', headers, body: JSON.stringify({ section, patch }) }).then(unwrap),
  updateUserSettings: (section, patch) => fetch(`${API}/user`, { method:'PATCH', credentials:'include', headers, body: JSON.stringify({ section, patch }) }).then(unwrap),
};
```

Conventions preserved: plain `fetch`, `credentials: 'include'`, `throw await response.json()` on error, `hallFetch` for hall-scoped calls.

**Lazy loading:** Not yet implemented in Phase 1 — all settings pages are eagerly loaded. Deferred to Phase 2+ when more pages are added. The `SettingsLayout` shows a `<Loader/>` fallback for loading state within each page.

### 2.8 Visual Design & Layout (Phase 1)

#### 2.8.1 Sticky Sidebar Pattern

The settings sidebar is `sticky top-0 h-[calc(100vh-4rem)]` — it stays in view while the main content scrolls. No nested overflow containers (the parent `<CinemaLayout>` provides the single scrollable area), preventing double scrollbars.

Sidebar structure:
```
Settings (icon + header)
├── Organization group
│   ├── General        (Settings icon)
│   └── Payment        (CreditCard icon)
├── Cinema Branch group
│   ├── Cinema Profile (Building2 icon)
│   ├── Showtimes      (Calendar icon)
│   └── Booking        (Ticket icon)
└── Info box (tip about per-section saving)
```

Nav items show:
- **Active state:** `bg-primary/10` background + primary color text + `shadow-[inset_2px_0_0_0]` left accent bar
- **Dirty state:** `"unsaved"` `<Badge variant="outline">` with amber-500 border/tint
- **Hover:** `bg-muted/60` background

#### 2.8.2 Floating Save Bar

A sticky save bar floats at the bottom-right of the content area:
```
┌─────────────────────────────────────┐
│  [Unsaved changes]  [💾 Save Changes] │
└─────────────────────────────────────┘
```
- Positioned via `sticky bottom-0 pointer-events-none` on the wrapper, `pointer-events-auto` on the inner bar
- Glassmorphism: `bg-card/95 backdrop-blur-md`, `border border-border/60`, `shadow-2xl shadow-black/20`, `ring-1 ring-white/5`
- Shows `"Unsaved changes"` `<Badge>` (amber) when the current section has edits
- Button disabled state when no changes or while saving
- The content area has `pb-28` spacing so content doesn't visually overlap the bar

#### 2.8.3 Section Page Header (`SettingsPageHeader`)

Reusable component at the top of every section page:
```
┌──────────────────────────────────────────────┐
│  [🔧 icon]  General Settings     [ORGANIZATION] │
│             Platform identity, timezone...    │
└──────────────────────────────────────────────┘
```
- 48px icon in a gradient circle (`bg-gradient-to-br from-primary/20 to-primary/5`)
- Title as `<h1 className="text-2xl font-bold">`
- Scope badge with color coding:
  - `org` → primary/red tint
  - `hall` → emerald/green tint
  - `user` → violet/purple tint
- Description: max-w-2xl for readability

#### 2.8.4 Settings Form Card (`SettingsCard`)

Reusable card wrapper for form sections:
```
┌──────────────────────────────────────────────┐
│  [🕐 icon]  Scheduling Defaults              │
│             Controls how new shows...        │
├──────────────────────────────────────────────┤
│  Field 1  │  Field 2                          │
│  Field 3                                     │
│  ┌─────────────────────────────────────────┐  │
│  │  Switch label                 [toggle]   │  │
│  └─────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```
- `bg-card/80 backdrop-blur-sm` glassmorphism
- `hover:shadow-md transition-shadow duration-300` for elevation feedback
- Header: icon in a 32px rounded square, title, description
- `border-b border-border/40` separating header from content
- Content: `p-6` internal spacing
- Switch toggles in rounded-xl `bg-muted/30 p-4` highlight containers

#### 2.8.5 Form Field Conventions

- Labels: `text-sm font-medium`
- Inputs: `h-11` for comfortable tap targets
- Helper text: `text-xs text-muted-foreground` below input
- Grid: `grid grid-cols-1 sm:grid-cols-2 gap-5` for side-by-side fields
- Icons: inline lucide icons next to labels (e.g., `<Globe className="h-4 w-4 text-muted-foreground" />`)
- Loading state: `<Loader />` centered
- Error state: `<Alert variant="destructive">`

#### 2.8.6 Payment Preview

The GST preview card uses a gradient background:
```
┌──────────────────────────────────────────────┐
│  [🧮]  PER-TICKET PREVIEW                    │
│  Convenience Fee            ₹15.00          │
│  GST (18%)                  ₹2.70           │
│  ──────────────────────────────────────────── │
│  Total per ticket           ₹17.70           │
└──────────────────────────────────────────────┘
```
- `bg-gradient-to-br from-primary/10 to-primary/5` with `border border-primary/20`
- `shadow-lg shadow-primary/5` for subtle glow
- The non-super-admin view shows a lock icon + read-only stat cards instead

---

## 3. Backend Architecture

### 3.1 Architectural Layering

The existing codebase has controllers querying `pool` directly (no service/repo layer). For the Settings Module, a **service + repository layer** was initially proposed. In Phase 1 (MVP), the controller queries the DB directly via `db.query()` and `db.connect()` with transactions — the service/repo layer is deferred to Phase 2 when RBAC and audit logging are added:

```
routes/settings.routes.js          → HTTP layer (validation, auth middleware)
controllers/settings.Controller.js → orchestration, response shaping, DB access
services/settings.service.js       → ❌ Deferred to Phase 2
repositories/settings.repo.js      → ❌ Deferred to Phase 2
```

### 3.2 New PostgreSQL Tables

All follow existing conventions: `UUID DEFAULT gen_random_uuid()`, `TIMESTAMPTZ DEFAULT now()`, `JSONB` for flexible config, `REFERENCES … ON DELETE CASCADE`.

#### `organizations` (new tenant layer — deployed via `migration_phase1_settings.sql`)
```sql
CREATE TABLE organizations (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name             TEXT NOT NULL,
  slug             TEXT UNIQUE NOT NULL,
  owner_id         UUID REFERENCES cinema_admin_user(id) ON DELETE SET NULL,
  default_timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata',
  default_currency TEXT NOT NULL DEFAULT 'INR',
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  plan             TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free','pro','enterprise')),
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);
```

> **Note:** Migration script also handles backward compat: auto-creates an org for existing admins on first settings access via `resolveOrgId()` in the controller. Org slug is auto-generated as `{name-slug}-{adminId:8}` and deduplicated via `ON CONFLICT (slug) DO UPDATE`.

#### `organization_members` (replaces direct admin→hall ownership for team members)
```sql
CREATE TABLE organization_members (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id    UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  admin_id  UUID NOT NULL REFERENCES cinema_admin_user(id) ON DELETE CASCADE,
  role_id   UUID NOT NULL REFERENCES roles(id),
  status    VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('invited','active','suspended','removed')),
  invited_by UUID REFERENCES cinema_admin_user(id),
  invited_at TIMESTAMPTZ,
  joined_at  TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (org_id, admin_id)
);
CREATE INDEX idx_org_members_org   ON organization_members(org_id);
CREATE INDEX idx_org_members_admin ON organization_members(admin_id);
```

#### `hall_assignments` (many-to-many: org members ↔ halls within an org)
```sql
CREATE TABLE hall_assignments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_member_id   UUID NOT NULL REFERENCES organization_members(id) ON DELETE CASCADE,
  hall_id         UUID NOT NULL REFERENCES cinema_hall(id) ON DELETE CASCADE,
  scope           VARCHAR(20) NOT NULL DEFAULT 'full' CHECK (scope IN ('full','read_only','limited')),
  assigned_by     UUID REFERENCES cinema_admin_user(id),
  created_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE (org_member_id, hall_id)
);
```

> **Backward compat:** `cinema_hall.admin_id` FK stays (the org owner is the hall creator). `hall_assignments` adds *additional* assigned members via `organization_members`. `requireActiveHall` is extended to check `hall_assignments` OR `cinema_hall.admin_id`.

#### `roles` (RBAC roles per org; seeded system roles have `is_system=TRUE`)
```sql
CREATE TABLE roles (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id              UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  key                 VARCHAR(50) NOT NULL,
  label               VARCHAR(100) NOT NULL,
  description         TEXT,
  is_system           BOOLEAN NOT NULL DEFAULT FALSE,
  permissions_version INTEGER NOT NULL DEFAULT 1,
  created_at          TIMESTAMPTZ DEFAULT now(),
  updated_at          TIMESTAMPTZ DEFAULT now(),
  UNIQUE (org_id, key)
);
```

#### `permissions` (catalog of all permission strings)
```sql
CREATE TABLE permissions (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key       VARCHAR(100) UNIQUE NOT NULL,
  label     VARCHAR(200) NOT NULL,
  resource  VARCHAR(50) NOT NULL
);
```

#### `role_permissions` (many-to-many)
```sql
CREATE TABLE role_permissions (
  role_id       UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);
```

#### `organization_settings` (org-level config, typed JSONB per section)
```sql
CREATE TABLE organization_settings (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id         UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  section        TEXT NOT NULL,
  value          JSONB NOT NULL DEFAULT '{}',
  schema_version INT NOT NULL DEFAULT 1,
  updated_by     UUID REFERENCES cinema_admin_user(id),
  updated_at     TIMESTAMPTZ DEFAULT now(),
  UNIQUE (org_id, section)
);
CREATE INDEX idx_org_settings_org_section ON organization_settings(org_id, section);
```

#### `hall_settings` (per-branch config)
```sql
CREATE TABLE hall_settings (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hall_id        UUID NOT NULL REFERENCES cinema_hall(id) ON DELETE CASCADE,
  section        TEXT NOT NULL,
  value          JSONB NOT NULL DEFAULT '{}',
  schema_version INT NOT NULL DEFAULT 1,
  updated_by     UUID REFERENCES cinema_admin_user(id),
  updated_at     TIMESTAMPTZ DEFAULT now(),
  UNIQUE (hall_id, section)
);
CREATE INDEX idx_hall_settings_hall_section ON hall_settings(hall_id, section);
```

#### `user_settings` (per-admin preferences)
```sql
CREATE TABLE user_settings (
  id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES cinema_admin_user(id) ON DELETE CASCADE,
  section TEXT NOT NULL,
  value   JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (admin_id, section)
);
CREATE INDEX idx_user_settings_admin ON user_settings(admin_id);
```

#### `settings_audit_logs` (before/after snapshots)
```sql
CREATE TABLE settings_audit_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id     UUID REFERENCES organizations(id) ON DELETE SET NULL,
  hall_id    UUID REFERENCES cinema_hall(id) ON DELETE SET NULL,
  admin_id   UUID REFERENCES cinema_admin_user(id) ON DELETE SET NULL,
  scope      TEXT NOT NULL CHECK (scope IN ('org','hall','user')),
  section    TEXT NOT NULL,
  action     TEXT NOT NULL CHECK (action IN ('create','update','delete','reset')),
  before     JSONB,
  after      JSONB,
  diff       JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_settings_audit_org_time   ON settings_audit_logs(org_id, created_at DESC);
CREATE INDEX idx_settings_audit_hall_time  ON settings_audit_logs(hall_id, created_at DESC);
CREATE INDEX idx_settings_audit_admin_time ON settings_audit_logs(admin_id, created_at DESC);
CREATE INDEX idx_settings_audit_section    ON settings_audit_logs(section);
```

#### `feature_flags` (toggle features per org/hall)
```sql
CREATE TABLE feature_flags (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id     UUID REFERENCES organizations(id) ON DELETE CASCADE,
  hall_id    UUID REFERENCES cinema_hall(id) ON DELETE CASCADE,
  flag_key   TEXT NOT NULL,
  enabled    BOOLEAN NOT NULL DEFAULT FALSE,
  config     JSONB DEFAULT '{}',
  updated_by UUID REFERENCES cinema_admin_user(id),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (COALESCE(org_id,'00000000-0000-0000-0000-000000000000'), COALESCE(hall_id,'00000000-0000-0000-0000-000000000000'), flag_key)
);
```

#### `admin_mfa` (MFA secrets)
```sql
CREATE TABLE admin_mfa (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id     UUID NOT NULL REFERENCES cinema_admin_user(id) ON DELETE CASCADE,
  method       TEXT NOT NULL CHECK (method IN ('totp','backup_codes')),
  secret       TEXT,
  backup_codes JSONB,
  enabled_at   TIMESTAMPTZ DEFAULT now(),
  last_used_at TIMESTAMPTZ,
  UNIQUE (admin_id, method)
);
```

#### `admin_devices` (device tracking)
```sql
CREATE TABLE admin_devices (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id           UUID NOT NULL REFERENCES cinema_admin_user(id) ON DELETE CASCADE,
  device_fingerprint TEXT NOT NULL,
  device_name        TEXT,
  ip_address         TEXT,
  first_seen         TIMESTAMPTZ DEFAULT now(),
  last_seen          TIMESTAMPTZ DEFAULT now(),
  is_trusted         BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE (admin_id, device_fingerprint)
);
CREATE INDEX idx_admin_devices_admin ON admin_devices(admin_id);
```

#### `admin_password_history` (password reuse prevention)
```sql
CREATE TABLE admin_password_history (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id   UUID NOT NULL REFERENCES cinema_admin_user(id) ON DELETE CASCADE,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_pass_history_admin ON admin_password_history(admin_id);
```

### 3.3 Backward Compat for Legacy `settings` Table

The existing `settings` key/value table is kept. A migration copies the two keys into `organization_settings`:

```sql
-- Migration: migrate existing settings to org_settings
INSERT INTO organization_settings (org_id, section, value, updated_at)
SELECT o.id, 'payment',
  jsonb_build_object(
    'convenience_fee', jsonb_build_object('model', 'per_ticket', 'amount', COALESCE((SELECT value::numeric FROM settings WHERE key='convenience_fee_per_ticket'), 15)),
    'gst', jsonb_build_object('percentage', COALESCE((SELECT value::numeric FROM settings WHERE key='gst_percentage'), 18))
  ),
  now()
FROM organizations o;
```

The old `GET /api/settings` public endpoint remains for `cinema-hall-users` and `ShowPage.jsx` — it reads from the new `org_settings.payment` JSONB to keep the same response shape.

### 3.4 Validation Rules

- **Server-side:** `zod` schemas per section in `services/settings.schemas.js` (zod is already a dependency via `@hookform/resolvers`). Controller validates before service call.
- **DB-side:** `CHECK` constraints on enums (scope, action, status, plan). JSONB validated by zod at write time. Unique constraints prevent duplicate section rows.
- **Client-side:** mirrored zod schemas in `lib/settings/settingsSchema.js` for instant feedback.

### 3.5 API Routes

Mounted at `/api/settings` in `server.js`:

| Method | Path | Middleware (Phase 1) | Purpose |
|---|---|---|---|---|
| `GET` | `/api/settings/org` | `verifyCinemaAdminAccessToken` + `verifySuperAdmin` | Get all org settings sections + org name from `organizations.name` |
| `PATCH` | `/api/settings/org` | `verifyCinemaAdminAccessToken` + `verifySuperAdmin` | Update one section `{ section, patch }`; `org_name` in patch also updates `organizations.name` |
| `GET` | `/api/settings/hall/:hallId` | `verifyCinemaAdminAccessToken` + `requireActiveHall` | Get hall settings sections |
| `PATCH` | `/api/settings/hall/:hallId` | `verifyCinemaAdminAccessToken` + `requireActiveHall` | Update hall section |
| `GET` | `/api/settings/user` | `verifyCinemaAdminAccessToken` | Get own user settings |
| `PATCH` | `/api/settings/user` | `verifyCinemaAdminAccessToken` | Update own user settings |
| `GET` | `/api/settings` | public | **Backward compat** — reads from `org_settings.payment` JSONB, returns `{ convenience_fee_per_ticket, gst_percentage }` |
| `PUT` | `/api/settings` | `verifyCinemaAdminAccessToken` + `verifySuperAdmin` | **Backward compat** — delegates to `updateOrgSettings` with `section='payment'` |

> **Note:** `requirePermission` middleware not yet implemented — Phase 2. Phase 1 uses existing `verifySuperAdmin` for org-scoped endpoints. Hall/user endpoints rely on `requireActiveHall` and token auth.

### 3.6 Controllers / Services / Repositories Layout

```
cinema-hall-api/
├── routes/settings.routes.js              ✅ Phase 1 — 7 routes (GET/PATCH org/hall/user + legacy GET/PUT)
├── controllers/settings.Controller.js     ✅ Phase 1 — 7 handlers, DB queries inline, zod validation pending
├── services/
│   ├── settings.service.js                ❌ Phase 2
│   ├── settings.schemas.js                ❌ Phase 2
│   ├── team.service.js                    ❌ Phase 2
│   ├── roles.service.js                   ❌ Phase 2
│   ├── audit.service.js                   ❌ Phase 4
│   └── featureFlags.service.js            ❌ Phase 4
├── repositories/
│   ├── settings.repo.js                   ❌ Phase 2
│   ├── roles.repo.js                      ❌ Phase 2
│   ├── team.repo.js                       ❌ Phase 2
│   ├── audit.repo.js                      ❌ Phase 4
│   └── featureFlags.repo.js               ❌ Phase 4
└── middleware/
    ├── verifyCinemaAdmin.js               ✅ (existing — unchanged)
    └── requirePermission.js               ❌ Phase 2
```

#### `requirePermission` Middleware

```js
// middleware/requirePermission.js
export const requirePermission = (perm) => async (req, res, next) => {
  req.admin.permissions = await loadAdminPermissions(req.admin.id); // cached LRU
  if (!req.admin.permissions.has(perm)) {
    return res.status(403).json({ error: `Missing permission: ${perm}` });
  }
  next();
};
```

Permissions are cached in-memory (LRU, TTL 5 min, keyed by `adminId:permissionsVersion`). On role change, `permissionsVersion` is bumped, invalidating the cache.

---

## 4. Team Management System (RBAC)

### 4.1 Roles

Seven system roles. System roles (`is_system=TRUE`) are seeded and immutable; org admins can clone them or create custom roles.

| Role key | Label | Scope | Seeded permissions (summary) |
|---|---|---|---|
| `owner` | Owner | org | Everything + `team.manage`, `roles.manage`, `billing.manage`, `org.delete` |
| `admin` | Admin | org/hall | Everything except `org.delete`, `roles.manage`, `billing.manage` |
| `manager` | Manager | hall | `shows.*`, `movies.read/update`, `screens.*`, `bookings.*`, `refunds.*`, `offers.*`, `reports.view`, `settings.hall.update` |
| `finance` | Finance | org/hall | `bookings.read`, `payment.read`, `refunds.*`, `reports.view`, `analytics.view`, `settings.payment.read` |
| `marketing` | Marketing | org/hall | `offers.*`, `ads.*`, `movies.read`, `customers.read`, `analytics.view` |
| `ticket_operator` | Ticket Operator | hall | `shows.read`, `bookings.read/verify`, `verify-ticket.*`, `customers.read` |
| `auditor` | Auditor | org | Read-only across everything: `*.read`, `audit.view`, no writes |

### 4.2 Permission Catalog

Permissions use `resource.action` format, seeded into the `permissions` table:

```
movies.create | movies.read | movies.update | movies.delete
shows.create  | shows.read  | shows.update  | shows.delete  | shows.cancel
screens.create | screens.read | screens.update | screens.delete
bookings.read | bookings.verify | bookings.cancel
refunds.create | refunds.read | refunds.settle
offers.create | offers.read | offers.update | offers.delete | offers.manage
ads.create | ads.read | ads.update | ads.delete
customers.read | customers.manage
payment.read | payment.manage
settings.org.read | settings.org.update
settings.hall.read | settings.hall.update
settings.user.read | settings.user.update
settings.advanced.manage
team.manage | team.invite | team.revoke
roles.manage | roles.read
audit.view
analytics.view | analytics.manage
integrations.manage
branding.manage
feature_flags.manage
billing.manage
org.delete
```

### 4.3 Permission Resolution

```
organization_members.role_id → roles → role_permissions → permissions (permission set)
                                          +
hall_assignments.scope → global restriction (full / read_only / limited)
                                          =
Effective permissions for this admin + hall context
```

- `team.service.loadAdminPermissions(adminId)` returns a `Set<permissionKey>`.
- For hall-scoped actions, `requireActiveHall` already enforces hall ownership; `requirePermission` additionally checks the permission key.
- `hall_assignments.scope='read_only'` strips all `*.update/*.create/*.delete` permissions for that hall context.

### 4.4 JWT Extension

The JWT payload (currently `{id, email, name, role}`) is extended to `{id, email, name, orgId, roleKey, permissionsVersion}`. Full permissions are **not** embedded in the JWT. Instead, `requirePermission` loads from DB with an in-memory LRU cache (TTL 5 min). On role change, bump `permissionsVersion` to invalidate cache.

### 4.5 Team Invite Flow

1. Admin fills `TeamInviteDialog.jsx` — email, role, hall assignments.
2. `POST /api/auth/invite` — creates `organization_members` with `status='invited'`, generates invite token (SHA-256 hashed, same pattern as `admin_verification_tokens`), sends invite email via existing `mail/emails.js`.
3. Recipient clicks link → `GET /api/auth/accept-invite?token=…` → validates token → sets `status='active'`, sets `password` if new user (redirect to set-password page), `joined_at = now()`.
4. Invite expires after `org_settings.security.invite_expiry_hours` (default 72).

---

## 5. Security Architecture

### 5.1 MFA Support (TOTP + Backup Codes)

- **TOTP** (RFC 6238): `admin_mfa` row with `method='totp'`, secret encrypted via `crypto.createCipheriv` using `MFA_ENCRYPTION_KEY` env var. Enrollment flow: generate secret → show QR (`otplib`) → user verifies 6-digit code → enable. Verify on login (after password) if `org_settings.security.mfa_required=true`.
- **Backup codes:** 10 single-use codes, SHA-256 hashed (same `hashToken.js` pattern), stored in `admin_mfa.backup_codes` JSONB. Regenerate invalidates old set.
- **Recovery:** Super Admin / Owner can reset MFA for a member (audited as `MFA_RESET` in `admin_security_logs`).

### 5.2 Device Tracking

`admin_devices` table. On login, compute `device_fingerprint = sha256(UA + screen + timezone + platform)`. If new device → mark untrusted, send "New device login" email (extends `mail/emails.js`). If `org_settings.security.require_trusted_devices=true`, untrusted logins require MFA even when MFA isn't globally required. "Trusted" toggle in Security Settings + `/api/auth/security` response.

### 5.3 Session Management

Existing `admin_sessions` extended with:
- `GET /api/auth/sessions` — list active sessions with device info (joins `admin_devices`).
- `DELETE /api/auth/sessions/:id` — revoke a specific session (extends existing `logoutAllDevices` to per-session).
- Session timeout: `org_settings.security.session_timeout_minutes` (default 30) — cron job revokes idle sessions beyond timeout.

### 5.4 Login History

No new table — reconstructed from `admin_security_logs` (`action='LOGIN_SUCCESS'`) with `ip_address`, `user_agent`, `created_at`. `GET /api/auth/security` already returns `recentLogs` (last 20). Extended to a dedicated `GET /api/auth/login-history` with pagination + filters.

### 5.5 Password Policies (DB-driven)

Move `passwordPolicy.js` constants into `org_settings.security.password_policy` JSONB:

```json
{
  "min_length": 8,
  "require_upper": true,
  "require_lower": true,
  "require_digit": true,
  "require_special": true,
  "prevent_reuse_count": 5,
  "expiry_days": null
}
```

`validatePassword()` reads from cached org settings instead of hardcoded constants. `prevent_reuse_count` checks `admin_password_history` (last N bcrypt hashes, reject reuse).

### 5.6 Account Lock Policies (DB-driven)

Move `LOCKOUT_THRESHOLDS` from `auth.Controller.js` into `org_settings.security.lockout_policy`:

```json
{
  "thresholds": [
    { "attempts": 5, "minutes": 15 },
    { "attempts": 10, "minutes": 60 },
    { "attempts": 15, "minutes": 1440 }
  ]
}
```

`getLockDuration()` reads from org settings. Per-org tuning without code changes.

### 5.7 Suspicious Login Detection

New detection in `auth.Controller.js` login flow:
- **New country/IP range** → flag, require MFA, email alert.
- **Impossible travel** (login from IP A then IP B in < feasible travel time) → force re-auth.
- **Velocity check** (5+ failed attempts from different IPs in 10 min) → temp IP block via in-memory set (extends `oauthRateLimit.js` pattern).

Uses a lightweight `admin_login_geo` cache table (or in-memory LRU) — IP → country via a local GeoIP lookup (`geoip-lite` or MaxMind). All flagged events logged as `SUSPICIOUS_LOGIN` in `admin_security_logs`.

### 5.8 Audit Logging Strategy

Two audit streams:
1. **`admin_security_logs`** (existing) — auth events. Reuse `logSecurityEvent()`. Add new actions: `MFA_ENABLED`, `MFA_DISABLED`, `MFA_RESET`, `SUSPICIOUS_LOGIN`, `DEVICE_TRUSTED`, `DEVICE_REVOKED`, `SESSION_REVOKED`.
2. **`settings_audit_logs`** (new) — settings changes with before/after JSONB + computed diff. Written by `audit.service.js` inside the same transaction as the settings update.

---

## 6. Cinema-Specific Settings

All stored in `hall_settings` (per-branch) or `organization_settings` (org-wide) as typed JSONB. Schemas validated by zod.

### 6.1 Movies
```json
// hall_settings.movies
{
  "default_status": "upcoming",
  "auto_fetch_tmdb": true,
  "default_genre_filter": [],
  "status_lifecycle": ["upcoming","now_showing","ended"]
}
```
No new tables — configures existing `movies` table behavior.

### 6.2 Showtimes
```json
// hall_settings.showtimes
{
  "default_buffer_minutes": 15,
  "prevent_overlap": true,
  "default_language_version": "Original",
  "auto_status_transitions": true,
  "timezone": "Asia/Kolkata",
  "advance_booking_days": 7,
  "booking_open_offset_minutes": 0
}
```
Affects existing `shows` table + the cron `updateShowStatuses`.

### 6.3 Seats & Screens
```json
// hall_settings.seating
{
  "default_tiers": ["premium","gold","silver"],
  "default_aisle_after_columns": 8,
  "max_seats_per_booking": 10,
  "seat_hold_minutes": 5
}
```
`seat_hold_minutes` feeds `hold_expires_at` computation (currently hardcoded 5 min). `max_seats_per_booking` adds a DB-level check missing today.

### 6.4 Pricing & Dynamic Pricing
```json
// hall_settings.pricing
{
  "tiers": [
    { "key": "premium", "label": "Premium", "default_price": 250 },
    { "key": "gold",    "label": "Gold",    "default_price": 180 },
    { "key": "silver",  "label": "Silver",  "default_price": 120 }
  ]
}
// hall_settings.dynamic_pricing   (feature-flagged)
{
  "enabled": false,
  "rules": [
    { "type": "peak_hours", "days": [5,6], "from": "18:00", "to": "23:00", "multiplier": 1.2 },
    { "type": "demand",     "threshold_occupancy": 0.8, "multiplier": 1.1 }
  ]
}
```
Dynamic pricing applied at show-price computation time via `computeShowPrice()`. Stored on `shows.price_override` JSONB when a rule fires.

### 6.5 Taxes & Convenience Fee
```json
// organization_settings.payment
{
  "convenience_fee": { "model": "per_ticket", "amount": 15 },
  "gst_percentage": 18,
  "gst_applies_to": "convenience_fee",
  "state_taxes": [{ "state": "KA", "rate": 0, "label": "SGST" }]
}
```
Generalizes the existing 2 keys. Backward-compat: `GET /api/settings` reads `convenience_fee.amount` + `gst_percentage`.

### 6.6 Booking Limits & Cancellation
```json
// hall_settings.booking
{
  "max_seats_per_booking": 10,
  "advance_booking_days": 7,
  "hold_minutes": 5,
  "cancellation": {
    "allowed": true,
    "window_minutes": 120,
    "penalty_percentage": 10
  }
}
```
Cancellation is a **new capability** (today only admin show-cancel triggers refunds). Adds customer-initiated cancellation with a configurable window + penalty.

### 6.7 Refund Policies
```json
// organization_settings.payment.refund_policy
{
  "auto_refund": true,
  "auto_refund_window_minutes": 120,
  "partial_refund_allowed": true,
  "manual_settle_only_after_hours": 24
}
```
Extends existing `refunds` table behavior. `auto_refund` triggers Razorpay refund automatically on cancellation within the window.

### 6.8 Food & Beverage (feature-flagged, new tables)
```sql
CREATE TABLE fnb_categories (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hall_id    UUID NOT NULL REFERENCES cinema_hall(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  sort_order INT DEFAULT 0,
  is_active  BOOLEAN DEFAULT TRUE
);

CREATE TABLE fnb_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES fnb_categories(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  description TEXT,
  price       NUMERIC(10,2) NOT NULL,
  image_url   TEXT,
  is_available BOOLEAN DEFAULT TRUE,
  sort_order  INT DEFAULT 0
);

CREATE TABLE fnb_orders (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
  hall_id    UUID NOT NULL REFERENCES cinema_hall(id) ON DELETE CASCADE,
  items      JSONB NOT NULL,          -- [{item_id, qty, price}]
  total      NUMERIC(10,2) NOT NULL,
  status     TEXT DEFAULT 'pending' CHECK (status IN ('pending','preparing','ready','delivered','cancelled')),
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 6.9 Offers & Coupons
No schema change to existing `offers`/`offer_redemptions` tables. Settings configure defaults:
```json
// organization_settings.offers
{
  "default_scope": "global",
  "default_max_redemptions_per_customer": 1,
  "default_validity_days": 30,
  "auto_generate_codes": false,
  "code_prefix": "CINE"
}
```

### 6.10 Membership Programs (feature-flagged, new tables)
```sql
CREATE TABLE membership_tiers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  benefits    JSONB NOT NULL,          -- {discount_pct, free_fnb, priority_booking}
  annual_fee  NUMERIC(10,2) DEFAULT 0,
  sort_order  INT DEFAULT 0
);

CREATE TABLE customer_memberships (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  tier_id     UUID NOT NULL REFERENCES membership_tiers(id) ON DELETE CASCADE,
  started_at  TIMESTAMPTZ DEFAULT now(),
  expires_at  TIMESTAMPTZ,
  status      TEXT DEFAULT 'active' CHECK (status IN ('active','expired','cancelled'))
);
```

---

## 7. Theme & Branding

### 7.1 Light / Dark Mode (exists)

`ThemeContext.jsx` already toggles `.dark` class + persists to localStorage. Keep as-is. Extend to allow **org-configured default** (`org_settings.branding.default_theme`).

### 7.2 Custom Branding (stored in `organization_settings.branding`)
```json
{
  "logo_url": "https://res.cloudinary.com/...",
  "logo_dark_url": "...",
  "banner_url": "...",
  "primary_color": "#E50914",
  "accent_color": "#FFD700",
  "font_family": "JetBrains Mono Variable",
  "app_name": "Cinemax",
  "default_theme": "dark",
  "white_label": false
}
```

### 7.3 Theme Colors → oklch Tokens

On login, `GET /api/auth/me` returns `orgSettings.branding`. A new `applyBranding()` utility injects CSS custom properties (`--primary`, `--accent`) into `:root`, overriding the defaults in `index.css`. Uses the same oklch pattern:

```js
// lib/branding/applyBranding.js
export function applyBranding(branding) {
  const root = document.documentElement;
  if (branding.primary_color) root.style.setProperty('--primary', hexToOklch(branding.primary_color));
  if (branding.accent_color)  root.style.setProperty('--accent',  hexToOklch(branding.accent_color));
  if (branding.font_family)   root.style.setProperty('--font-sans', branding.font_family);
}
```

### 7.4 White-Label Support (SaaS-ready)

Each organization has its own branding. When `plan='enterprise'` + `white_label=true` in `org_settings.branding`:
- Custom `app_name` replaces "Cinemax" in sidebar/title.
- Logo replaces default.
- Custom domain support (future — requires reverse-proxy/dns config).
- Hide "Powered by" footer.

`BrandingUploader.jsx` uses existing Cloudinary integration (`services/cloudinary.js`).

---

## 8. Notifications

### 8.1 Channels

| Channel | Provider | Status |
|---|---|---|
| Email | Nodemailer (`mail/emails.js`) | **Exists** |
| SMS | Twilio / SNS (new `sms/sms.service.js`) | New |
| WhatsApp | WhatsApp Business API (new `whatsapp/whatsapp.service.js`) | New |
| Push | Firebase Cloud Messaging (new `push/push.service.js`) | New |

### 8.2 Provider Config (org-level, stored in `organization_settings.notifications`)
```json
{
  "email":   { "provider": "smtp", "from": "no-reply@cinemax.com", "enabled": true },
  "sms":     { "provider": "twilio", "from": "+91...", "enabled": false, "account_sid_encrypted": "..." },
  "whatsapp":{ "provider": "gupshup", "template_namespace": "...", "enabled": false },
  "push":    { "provider": "fcm", "server_key_encrypted": "...", "enabled": false }
}
```

API keys encrypted at rest (AES-256-GCM with `SETTINGS_ENCRYPTION_KEY`).

### 8.3 Notification Preference Hierarchy (org → role → user)

```
1. organization_settings.notifications       (global defaults + provider config)
2. role_notification_overrides               (per-role defaults)
3. user_settings.notifications               (per-user toggles — overrides role)
```

`notification.service.resolvePreference(adminId, event)` merges the three layers: user wins over role, role wins over org.

Events: `booking_confirmed`, `booking_cancelled`, `refund_initiated`, `refund_settled`, `show_cancelled`, `low_occupancy_alert`, `daily_report`, `security_alert`.

New table for role overrides:
```sql
CREATE TABLE role_notification_overrides (
  role_id  UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  event    TEXT NOT NULL,
  channels JSONB NOT NULL DEFAULT '{}',  -- {"email":true,"sms":false,"whatsapp":false,"push":true}
  PRIMARY KEY (role_id, event)
);
```

---

## 9. Audit & Compliance

### 9.1 Audit Log Schema

Two streams (see §5.8):
- **`admin_security_logs`** (existing) — auth/security events. Schema unchanged, new actions added.
- **`settings_audit_logs`** (new §3.2) — settings changes with before/after.

### 9.2 Change Tracking & Before/After Snapshots

`audit.service.js` computes diff inside the settings update transaction:

```js
async function recordSettingsChange({ scope, section, before, after, req }) {
  const diff = computeDiff(before, after); // {field: [oldVal, newVal]}
  await auditRepo.insert({
    org_id: req.orgId, hall_id: req.currentHallId, admin_id: req.admin.id,
    scope, section, action: 'update',
    before, after, diff,
    ip_address: req.ip, user_agent: req.headers['user-agent'],
  });
}
```

### 9.3 User Activity Logs

Aggregate view joining `admin_security_logs` + `settings_audit_logs` + `admin_sessions.last_used_at`. `GET /api/settings/audit-logs?admin_id=…&scope=…&section=…&from=…&to=…` with pagination.

### 9.4 Settings History (Versioning)

Each `*_settings` row has `schema_version`. For point-in-time history, `settings_audit_logs.before/after` JSONB snapshots provide full history. A `GET /api/settings/audit-logs?section=payment&history=true` returns the chronology. No separate version table needed — audit logs ARE the version history.

### 9.5 Retention Strategy

| Data | Hot (queryable) | Cold (archived) | Purge |
|---|---|---|---|
| `admin_security_logs` | 90 days | 1 year (partitioned by month) | 7 years (regulatory), then auto-delete |
| `settings_audit_logs` | 90 days | 1 year | 3 years, then export + delete |
| `admin_sessions` | Active + 30 days | — | Auto-purge revoked > 30 days (cron job) |
| `admin_devices` | Active | — | Purge unseen > 1 year |

Implemented via PostgreSQL **table partitioning** by `created_at` month (for `admin_security_logs`, `settings_audit_logs`) + a weekly cron that detaches old partitions and moves to an archive schema. Configurable in `org_settings.advanced.retention`.

---

## 10. Implementation Roadmap

### Phase 1 — MVP ✅ COMPLETE

**Goal:** Replace the 2-key settings table with categorized, scoped settings without breaking existing consumers (`cinema-hall-users`, `ShowPage.jsx`).

| Layer | Tasks | Status |
|---|---|---|
| **Database** | `organizations`, `organization_settings`, `hall_settings`, `user_settings` tables + `migration_phase1_settings.sql`. Migrate existing 2 keys into `org_settings.payment`. Backward-compat query for legacy `GET /api/settings`. Auto-create org for existing admins on first settings access. | ✅ Deployed |
| **Backend** | `settings.routes.js` (7 routes: GET/PATCH org/hall/user + legacy GET/PUT). `settings.Controller.js` — 6 new endpoint handlers + backward compat shim. `resolveOrgId` helper auto-creates org. Transaction-based save with BEGIN/COMMIT/ROLLBACK. Section filter validation. No service/repo layer yet — controller queries DB directly. `verifySuperAdmin` used for org endpoints (temporary — replaced in Phase 2). | ✅ Deployed |
| **Frontend** | `SettingsContext` (org/hall/user cache, dirty tracking, optimistic update, save/reset). `SettingsLayout` (sticky sidebar with grouped nav + `"unsaved"` `<Badge>` + floating save bar). `SettingsPageHeader` (icon + title + scope badge). `SettingsCard` (card with icon header + shadow hover). 5 redesigned section pages: General, Cinema Profile, Showtimes, Booking, Payment (each with loading spinner + error alert + max-w-3xl content width + inline lucide icons + glassmorphism cards). `settingsService.js` (6 API methods). `settingsDefaults.js`. `App.jsx` nested routes under `/settings`. `main.jsx` — added `SettingsProvider`. Removed old `SettingsPage.jsx`. | ✅ Deployed |
| **Leanings vs Design** | | |
| | No service/repo layer (direct DB queries in controller) | Deferred to Phase 2 |
| | No zod server-side validation (basic type checks in controller) | Deferred to Phase 2 |
| | No unsaved-changes `beforeunload` banner (dirty tracking via sidebar badges + floating save bar status) | Deferred to Phase 2+ |
| | No `useSettingsPermission`/`PermissionContext` — `isSuperAdmin` gate remains | Deferred to Phase 2 |
| | No audit logging on writes | Deferred to Phase 4 |
| | No lazy-load (`React.lazy`) — pages eager-loaded | Deferred to Phase 2+ |
| | **UI enhancements (beyond original design):** | |
| | Sticky sidebar with grouped nav (Organization / Cinema Branch) | ✅ Phase 1 |
| | `SettingsPageHeader` + `SettingsCard` shared components | ✅ Phase 1 |
| | Floating save bar with glassmorphism + unsaved badge | ✅ Phase 1 |
| | Scope badges (org/hall/user) with color coding per page | ✅ Phase 1 |
| | Inline lucide icons next to form labels | ✅ Phase 1 |
| | Glassmorphism cards (`bg-card/80 backdrop-blur-sm`) with hover elevation | ✅ Phase 1 |
| | Double-scrollbar fix (no nested overflow containers) | ✅ Phase 1 |
| | Non-super-admin payment view (read-only stat cards) | ✅ Phase 1 |

### Phase 2 — Team Management & RBAC

**Goal:** Introduce teams, roles, permissions, and Team Management UI.

| Layer | Tasks | Status |
|---|---|---|
| **Database** | `organization_members`, `hall_assignments`, `roles`, `permissions`, `role_permissions` tables (`organizations` already deployed in Phase 1). Seed system roles + permission catalog. Back-fill existing admins as org members. | ❌ |
| **Backend** | `requirePermission` middleware (replaces `verifySuperAdmin` incrementally). `settings.service.js` + `settings.repo.js` (extract DB queries from controller). Zod schemas per section. `team.service.js`, `roles.service.js`, `team.repo.js`, `roles.repo.js`. Invite flow (email token). JWT extension (`orgId`, `roleKey`, `permissionsVersion`). Permission cache (LRU). Team + Roles API routes. | ❌ |
| **Frontend** | `PermissionContext` + `usePermissions()`. `TeamManagementPage` (invite dialog, member list, role assign, revoke). `RolesPermissionsPage` (role list, permission matrix editor). Sidebar permission filtering. Migrate `isSuperAdmin` checks to `can()`. `UnsavedChangesBanner` + `beforeunload` guard. `useSettingsPermission` hook. | ❌ |
| **Testing** | RBAC unit tests (permission resolution, scope cascade), invite flow E2E, role CRUD tests. | ❌ |

### Phase 3 — Advanced Security

**Goal:** MFA, device tracking, DB-driven policies, suspicious-login detection.

| Layer | Tasks | Effort |
|---|---|---|
| **Database** | `admin_mfa`, `admin_devices`, `admin_password_history` tables. Move password policy + lockout thresholds to `org_settings.security`. | 2 days |
| **Backend** | TOTP enrollment + verify (`otplib`). Backup codes. MFA-enforced login flow. Device fingerprinting + trust. Session listing + per-session revoke. Suspicious-login detection (GeoIP + impossible travel + velocity). `admin_password_history` reuse check. New security-log actions. | 6 days |
| **Frontend** | `SecuritySettingsPage` (MFA setup, password policy config, lockout config, session list, device list, trusted-device toggle). MFA challenge page in auth flow. | 4 days |
| **Testing** | MFA E2E, lockout policy tests, device-tracking tests, suspicious-login simulation. | 2 days |

### Phase 4 — Enterprise Features

**Goal:** Branding/white-label, integrations UI, audit/compliance, F&B, dynamic pricing, memberships, notifications expansion.

| Layer | Tasks | Effort |
|---|---|---|
| **Database** | `settings_audit_logs` (partitioned), `feature_flags`, `fnb_categories/items/orders`, `membership_tiers/customer_memberships`, `role_notification_overrides`. Partition existing `admin_security_logs`. | 4 days |
| **Backend** | `audit.service.js` (before/after + diff). Audit API + export (CSV/XLSX). SMS/WhatsApp/Push providers. Notification preference resolver (org→role→user). Dynamic pricing engine. F&B CRUD + order flow. Membership CRUD. Feature-flag service. Branding asset upload. Integration config CRUD (encrypted credentials). Retention cron. | 10 days |
| **Frontend** | `ThemeBrandingPage` (uploader, color pickers, live preview, white-label toggle). `IntegrationsPage` (Razorpay/TMDB/Cloudinary/SMS/WhatsApp/Push status + config). `AuditLogsPage` (filterable table + diff viewer + export). `AdvancedSettingsPage` (feature flags, API keys, danger zone). `NotificationSettingsPage` (channel config + per-event matrix). F&B management page. Dynamic pricing rule editor. Membership tiers page. | 8 days |
| **Testing** | Audit diff correctness, notification preference cascade, dynamic pricing math, F&B order flow, membership edge cases. | 3 days |

### Overall Estimate

| Phase | Estimated | Actual / Remaining |
|---|---|---|
| Phase 1 (MVP) | ~12.5 days | ✅ **COMPLETE** |
| Phase 2 (Team Management) | ~15 days | ⏳ Pending |
| Phase 3 (Advanced Security) | ~14 days | ❌ Pending |
| Phase 4 (Enterprise) | ~25 days | ❌ Pending |

**Total remaining: ~54 development-days**

---

## Key Design Decisions & Trade-offs

1. **PostgreSQL over MongoDB** — consistency with existing 22-table schema, pg Pool, JSONB for flexible config (same pattern as `offers.scope`), no cross-DB joins. Settings JSONB sections can evolve schema without DDL migrations.

2. **React Context over Zustand** — matches `AuthContext`/`HallContext`/`ThemeContext` patterns; settings are low-frequency, read-heavy, mostly loaded page-level — Context is sufficient without adding a state management dependency.

3. **Organization layer introduced** — `organizations` + `organization_members` + `hall_assignments` future-proofs for multi-branch teams without breaking existing `cinema_hall.admin_id` FK. Existing admins are back-filled as org owners. The MCP server's RLS model (`cinemax_reader` + `app.current_hall_ids`) can be adapted to use `org_id` as a partition key.

4. **Service/Repository layer for Settings only** — existing controllers query `pool` directly; we introduce the layered pattern for this complex module without forcing a full rewrite of existing controllers.

5. **`requirePermission` replaces `verifySuperAdmin` incrementally** — `verifySuperAdmin` stays during Phase 1; Phase 2 migrates routes to fine-grained `requirePermission(perm)`. Super Admin role gets `roles.manage` + `team.manage` instead of a binary bypass.

6. **Settings as typed JSONB per section** — not a column-per-setting approach. JSONB allows schema evolution without migrations; zod validates structure; `schema_version` handles client migrations. Same pattern as `offers` JSONB columns.

7. **Audit logs double as version history** — no separate version table; `settings_audit_logs.before/after` provides full point-in-time recovery for every settings change.

8. **Backward compat for `GET /api/settings`** — `cinema-hall-users` (booking flow) and `ShowPage.jsx` (revenue preview) keep reading `{ convenience_fee_per_ticket, gst_percentage }` from the new `org_settings.payment` JSONB via a thin compatibility shim. Legacy `PUT /api/settings` delegates to `updateOrgSettings` with `section='payment'`.

9. **`organizations.name` as source of truth for org name** — The organization name is a **core property of the org, not a "setting"**. On read, `GET /api/settings/org` always provides `org_name` from `organizations.name` (overwriting any stale value in `organization_settings.general`). On write (`PATCH /api/settings/org` with `section='general'`), `org_name` is synced to `organizations.name` via an atomic `UPDATE` inside the same transaction, then **stripped from the settings JSONB** before persistence. This prevents dual-source drift: `organization_settings` never stores `org_name`. The auto-fill logic in `getOrgSettings` creates `settings.general` if it doesn't exist, ensuring the org name is always visible in the General Settings form even before the first save.

---

## Appendix A: File Manifest

### Phase 1 Files (built)

#### Frontend — new files (10 files)

| Path | Purpose | Status |
|---|---|---|
| `src/pages/settings/SettingsLayout.jsx` | Sticky sidebar (grouped nav: Organization / Cinema Branch) + `<Outlet/>` + floating save bar with glassmorphism + `"unsaved"` Badge | ✅ |
| `src/pages/settings/GeneralSettingsPage.jsx` | Org name, timezone, currency, language — use `SettingsPageHeader` + `SettingsCard` | ✅ |
| `src/pages/settings/CinemaProfilePage.jsx` | Cinema name, address, phone, hours, description — inline lucide icons, grid layout | ✅ |
| `src/pages/settings/ShowtimesSettingsPage.jsx` | Buffer minutes, overlap toggle, advance booking — switch in highlighted container | ✅ |
| `src/pages/settings/BookingSettingsPage.jsx` | Hold duration, max seats, cancellation rules — conditional cancellation fields | ✅ |
| `src/pages/settings/PaymentSettingsPage.jsx` | Fee model, amount, GST + gradient preview — side-by-side layout, read-only stat cards for non-admin | ✅ |
| `src/components/settings/SettingsPageHeader.jsx` | Shared header: 48px icon + title + description + scope badge (org/hall/user color-coded) | ✅ |
| `src/components/settings/SettingsCard.jsx` | Shared form card: icon header + border-b separator + glassmorphism + shadow hover | ✅ |
| `src/lib/settings/settingsDefaults.js` | Default JSONB values per scope/section | ✅ |
| `src/services/settings/settingsService.js` | API methods — getOrg/Hall/User, updateOrg/Hall/User | ✅ |

#### Frontend — modified files (8 files)

| Path | Change |
|---|---|
| `src/context/SettingsContext.jsx` | **New file** — settings cache + dirty tracking + optimistic update + save/reset |
| `src/main.jsx` | Added `SettingsProvider` after `HallProvider` |
| `src/App.jsx` | Nested routes under `/settings` (general, cinema-profile, showtimes, booking, payment) |
| `src/pages/settings/GeneralSettingsPage.jsx` | Rewritten: uses `SettingsPageHeader` + `SettingsCard` + inline `Globe`/`Coins`/`Languages` icons + `h-11` inputs + `max-w-3xl` centered layout |
| `src/pages/settings/CinemaProfilePage.jsx` | Rewritten: inline `MapPin`/`Phone`/`Clock`/`FileText` icons + conditional "select a hall" empty state |
| `src/pages/settings/ShowtimesSettingsPage.jsx` | Rewritten: `Timer`/`Languages`/`ShieldCheck`/`CalendarDays` icons + switch in `rounded-xl bg-muted/30 p-4` container |
| `src/pages/settings/BookingSettingsPage.jsx` | Rewritten: `Timer`/`Users`/`CalendarDays`/`Ban`/`Percent` icons + conditional cancellation fields |
| `src/pages/settings/PaymentSettingsPage.jsx` | Rewritten: `Receipt`/`Percent`/`Calculator` icons + side-by-side cards + gradient preview card + read-only stat cards for non-admin |

#### Frontend — deleted files (1 file)

| Path | Reason |
|---|---|
| `src/pages/SettingsPage.jsx` | Replaced by SettingsLayout + section pages |

#### Backend — new files (2 files)

| Path | Purpose |
|---|---|
| `routes/settings.routes.js` | 7 routes: GET/PATCH org, GET/PATCH hall/:hallId, GET/PATCH user, legacy GET/PUT /api/settings |
| `controllers/settings.Controller.js` | 7 handlers + resolveOrgId helper + backward compat shim |

#### Database — migration (1 file)

| Migration | Tables |
|---|---|
| `migration_phase1_settings.sql` | organizations, organization_settings, hall_settings, user_settings + seed defaults + migrate legacy settings |

### Future files (deferred)

#### Frontend — planned (~25 files)

| Path | Phase |
|---|---|
| `src/pages/settings/TicketSettingsPage.jsx` | Phase 2+ |
| `src/pages/settings/OffersSettingsPage.jsx` | Phase 2+ |
| `src/pages/settings/NotificationSettingsPage.jsx` | Phase 3+ |
| `src/pages/settings/SecuritySettingsPage.jsx` | Phase 3+ |
| `src/pages/settings/TeamManagementPage.jsx` | Phase 2 |
| `src/pages/settings/RolesPermissionsPage.jsx` | Phase 2 |
| `src/pages/settings/ThemeBrandingPage.jsx` | Phase 4 |
| `src/pages/settings/AnalyticsPrefsPage.jsx` | Phase 3+ |
| `src/pages/settings/IntegrationsPage.jsx` | Phase 4 |
| `src/pages/settings/AuditLogsPage.jsx` | Phase 4 |
| `src/pages/settings/AdvancedSettingsPage.jsx` | Phase 4 |
| `src/components/settings/SettingsSidebar.jsx` | Phase 2 (inline in SettingsLayout for now) |
| `src/components/settings/SettingsForm.jsx` | Phase 2+ |
| `src/components/settings/SettingsField.jsx` | Phase 2+ |
| `src/components/settings/UnsavedChangesBanner.jsx` | Phase 2+ |
| `src/components/settings/SettingsSearch.jsx` | Phase 4 |
| `src/components/settings/DiffViewer.jsx` | Phase 4 |
| `src/components/settings/sections/*.jsx` | Phase 2+ |
| `src/context/PermissionContext.jsx` | Phase 2 |
| `src/hooks/settings/useSettings.js` | Phase 2+ |
| `src/hooks/settings/useSettingsMutation.js` | Phase 2+ |
| `src/hooks/settings/useUnsavedChanges.js` | Phase 2+ |
| `src/hooks/settings/useSettingsPermission.js` | Phase 2 |
| `src/hooks/settings/useSettingsVersion.js` | Phase 4 |
| `src/services/settings/teamService.js` | Phase 2 |
| `src/services/settings/rolesService.js` | Phase 2 |
| `src/services/settings/auditService.js` | Phase 4 |
| `src/services/settings/integrationService.js` | Phase 4 |
| `src/services/settings/brandingService.js` | Phase 4 |
| `src/lib/settings/settingsSchema.js` | Phase 2+ |
| `src/lib/settings/settingsRegistry.js` | Phase 2+ |
| `src/lib/settings/settingsMigrations.js` | Phase 4 |

#### Backend — planned (~15 files)

| Path | Phase |
|---|---|
| `services/settings.service.js` | Phase 2 |
| `services/settings.schemas.js` | Phase 2 |
| `services/team.service.js` | Phase 2 |
| `services/roles.service.js` | Phase 2 |
| `services/audit.service.js` | Phase 4 |
| `services/featureFlags.service.js` | Phase 4 |
| `repositories/settings.repo.js` | Phase 2 |
| `repositories/roles.repo.js` | Phase 2 |
| `repositories/team.repo.js` | Phase 2 |
| `repositories/audit.repo.js` | Phase 4 |
| `repositories/featureFlags.repo.js` | Phase 4 |
| `middleware/requirePermission.js` | Phase 2 |

#### SQL — planned (~6 files)

| Migration | Tables | Phase |
|---|---|---|
| `002_roles_permissions.sql` | roles, permissions, role_permissions | Phase 2 |
| `003_hall_assignments.sql` | hall_assignments | Phase 2 |
| `007_settings_audit.sql` | settings_audit_logs | Phase 4 |
| `008_feature_flags.sql` | feature_flags | Phase 4 |
| `009_admin_security.sql` | admin_mfa, admin_devices, admin_password_history | Phase 3 |
| `010_notification_overrides.sql` | role_notification_overrides | Phase 4 |
| `011_memberships.sql` | membership_tiers, customer_memberships | Phase 4 |
| `012_fnb.sql` | fnb_categories, fnb_items, fnb_orders | Phase 4 |


