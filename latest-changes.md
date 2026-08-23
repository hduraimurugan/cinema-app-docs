# Latest Changes

Updated: 2026-08-23

This page records the latest committed behavior across the three applications.

## Admin App

- Admin page access is driven by `src/config/pagePermissions.js` and shared by navigation, route guards, settings navigation, and the role editor.
- Settings sections hide when the active admin lacks the corresponding read permission. `/settings` redirects to the first accessible section, skipping disabled sections (`f7952e5`).
- Role cards expose member and permission counts. The Owner role is read-only in the UI and API.
- Permission editing supports page actions, extra actions, advanced permissions, reset, dirty state, and save callbacks.
- Admin requests attach `X-Org-Id` and `X-Hall-Id` from the active context.
- A stale permission token is refreshed once and the original request is replayed; refreshed permissions update navigation.
- Hall-dependent pages wait for hall context before their first request. Staff still bypass onboarding after hall loading completes.
- Settings navigation is a sticky horizontal tab bar (`SettingsTabBar` in `src/pages/settings/SettingsLayout.jsx:140`, `f7952e5`), replacing the previous 64-unit sticky sidebar. Tabs are grouped with vertical dividers, overflow as a hidden-scrollbar strip, and underline the active tab via `layoutId="settings-tab-underline"` with a spring transition. Dirty sections show a single amber dot (`isSectionDirty`) without the previous `Badge` hover expansion.
- Sections `cinema-profile`, `showtimes`, `booking` are temporarily disabled (`DISABLED_PATHS` set in `src/pages/settings/SettingsLayout.jsx:12`, `f7952e5`): they render as `Soon` badges, are `aria-disabled`, excluded from `SettingsIndexRedirect`, and do not show dirty state.
- Offers admin UI is now permission-aware (`a79e555`): `OfferFormPage.jsx:15` defaults non-SuperAdmin scope to `hall`, hides the Global option and shows "Only Super Admin can create offers valid across all halls." helper. `OffersManagement.jsx:17` shows a new **Created By** column (avatar initials + email + role pill `Super Admin`/`owner`/`admin` with amber/violet/sky tints) and gates edit/delete buttons to `isSuperAdmin || offer.created_by === user.id`. Export now includes `Creator Email` / `Creator Role` columns.
- Sidebar active state now uses path-prefix matching (`cd66dd9` in `src/components/AppSidebar.jsx:40`): `isActive` is `url === "/" ? location.pathname === "/" : location.pathname.startsWith(url)` so nav items like **Offers** (`/offers`) stay highlighted on nested routes `/offers/new` and `/offers/:id/edit` (previously `location.pathname === url` exact match only).

## API

### Organization Onboarding Hardening

- `POST /api/auth/onboarding` now rejects platform `staff` accounts with `403` before any organization or hall is created.
- An authenticated admin who is already an active member of an organization owned by someone else cannot create a second organization.
- An existing organization owner may safely retry onboarding without creating a duplicate organization.
- The onboarding owner-membership upsert now targets the phase 4 partial unique index, preventing a transaction failure during fresh onboarding.
- `database/audit_org_ownership.sql` provides read-only checks for staff-owned organizations, membership-role inconsistencies, hall-less organizations, and orphaned organizations.
- `database/migration_phase6_remove_phantom_orgs.sql` safely removes eligible hall-less organizations owned by staff while protecting organizations with halls, other members, or no alternate membership.

- `requireActiveOrg` verifies active organization membership from `X-Org-Id` or the organization in the JWT.
- `requireActiveHall` resolves organization membership, org-wide roles, creator access, explicit hall assignments, and read-only hall scope.
- Customer access and refresh tokens accept `Authorization: Bearer <token>` in addition to cookies.
- Permission middleware checks `permissions_version` and returns `401 TOKEN_STALE` when a role changed after token issuance.
- Role permission caches are invalidated for the entire organization after role changes.
- Role and team operations reject cross-organization roles and halls with typed validation errors.
- Organization owners cannot be demoted, suspended, removed, or assigned individual hall overrides.
- Removed members retain history and can be re-invited by reviving their membership.
- Hall CRUD, movies, shows, bookings, refunds, payments, offers, dashboard, settings, and roles now use explicit permission keys.
- Offers access control is now creator-scoped (`6e0705a` in `cinema-hall-api/controllers/offers.Controller.js:1` / `routes/offers.routes.js:27`): `GET /cinema-halls` uses `requirePermission('offers.create')` (was `verifySuperAdmin`) — SuperAdmin sees all halls, org members see only `WHERE org_id = resolveOrgId(req.admin.id)` via `middleware/requirePermission.js:resolveOrgId`. `GET /` lists only `WHERE created_by = req.admin.id` for non-SuperAdmin and joins `cinema_admin_user` + `LATERAL` `creator_role` to return `created_by_name/email/role` (`Super Admin` fallback). `GET /:id`, `PUT /:id`, `DELETE /:id` enforce creator ownership for non-SuperAdmin. `POST /create` and `PUT /update` reject `scope=global` for non-SuperAdmin (`403 Only Super Admin can create global offers.`) and validate `scope=hall` has `cinema_hall_id` belonging to the caller's `org_id`.
- Phase 4 hardens tenant foreign keys and ownership deletion behavior. Phase 5 adds `halls.read` and `halls.manage`.

## User App

- Movie cards and hero slides display normalized `vote_average` values to one decimal place.
- Movie details provide a location-first empty state, sticky date selection, availability indicators, and responsive hall/show cards.
- Users can favorite theatres; IDs are stored in local storage under `favourite_theatres`.
- Theatre cards include Google Maps directions, using coordinates first and an address search fallback.
- Movie, theatre, seat selection, order summary, and booking result pages received responsive layout and interaction refinements without changing the booking API contract.

## Source Commits

| App | Latest commits |
|---|---|
| Admin | `2b54a38`, `fa801d3`, `2f9bbeb`, `ed9aa47`, `e2b1564`, `f7952e5`, `a79e555`, `cd66dd9` |
| API | `50b1feb`, `c35886c`, `99f165e`, `d802f3c`, `680c9c4`, `36a7e4e`, `6e0705a` |
| Users | `548e50f`, `74049d1` |

## Related Documentation

- [Roles, Permissions & Team](modules/roles-permissions-team/README.md)
- [Settings](modules/settings/README.md)
- [Authentication](modules/authentication/README.md)
- [User App Experience](modules/user-app-experience/README.md)
- [Movie Management](modules/movie-management/README.md)
