# Latest Changes

Updated: 2026-08-17

This page records the latest committed behavior across the three applications.

## Admin App

- Admin page access is driven by `src/config/pagePermissions.js` and shared by navigation, route guards, settings navigation, and the role editor.
- Settings sections hide when the active admin lacks the corresponding read permission. `/settings` redirects to the first accessible section.
- Role cards expose member and permission counts. The Owner role is read-only in the UI and API.
- Permission editing supports page actions, extra actions, advanced permissions, reset, dirty state, and save callbacks.
- Admin requests attach `X-Org-Id` and `X-Hall-Id` from the active context.
- A stale permission token is refreshed once and the original request is replayed; refreshed permissions update navigation.
- Hall-dependent pages wait for hall context before their first request. Staff still bypass onboarding after hall loading completes.
- Settings navigation shows a compact unsaved-change dot and expands the indicator on hover.

## API

- `requireActiveOrg` verifies active organization membership from `X-Org-Id` or the organization in the JWT.
- `requireActiveHall` resolves organization membership, org-wide roles, creator access, explicit hall assignments, and read-only hall scope.
- Customer access and refresh tokens accept `Authorization: Bearer <token>` in addition to cookies.
- Permission middleware checks `permissions_version` and returns `401 TOKEN_STALE` when a role changed after token issuance.
- Role permission caches are invalidated for the entire organization after role changes.
- Role and team operations reject cross-organization roles and halls with typed validation errors.
- Organization owners cannot be demoted, suspended, removed, or assigned individual hall overrides.
- Removed members retain history and can be re-invited by reviving their membership.
- Hall CRUD, movies, shows, bookings, refunds, payments, offers, dashboard, settings, and roles now use explicit permission keys.
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
| Admin | `2b54a38`, `fa801d3`, `2f9bbeb`, `ed9aa47`, `e2b1564` |
| API | `50b1feb`, `c35886c`, `99f165e`, `d802f3c`, `680c9c4` |
| Users | `548e50f`, `74049d1` |

## Related Documentation

- [Roles, Permissions & Team](modules/roles-permissions-team/README.md)
- [Settings](modules/settings/README.md)
- [Authentication](modules/authentication/README.md)
- [User App Experience](modules/user-app-experience/README.md)
- [Movie Management](modules/movie-management/README.md)
