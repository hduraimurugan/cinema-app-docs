# Frontend

## Admin App — `cinema-hall-admin`

### `OffersManagement.jsx` (src/pages/OffersManagement.jsx, updated `a79e555`)

Offer list page accessible at `/offers` (permission `offers.read`; write via `offers.create/update/delete`; see `PagePermissions`).

**Features:**
- Search by code or title (debounced 400ms via `debounce` at line 17)
- Filter by scope (all / global / hall) and status (all / active / inactive)
- Paginated table (50 per page) with Prev/Next controls
- Each row shows: code, title, discount (formatted via `formatDiscount`), scope badge, eligibility, valid until, status badge, **Created By** (since `a79e555`: avatar `w-7 h-7 rounded-full` with initials via `initials(name)` at line 48, email `text-xs truncate max-w-[160px]`, role pill `text-[10px] capitalize` with `roleBadgeClass` at line 40 — `Super Admin` amber, `owner` violet, `admin` sky, default zinc)
- Row actions: edit pencil (`/offers/:id/edit`) and delete trash gated to `isSuperAdmin || offer.created_by === user.id` from `useAuth` (lines 46, 384); otherwise `—` muted text. Confirmation via delete dialog.
- Export button: downloads visible offers as CSV/Excel with columns Code, Title, Discount, Scope, Cinema Hall, **Creator Email**, **Creator Role**, Eligibility, Valid Until, Status (lines 168-173, `a79e555` adds the two creator fields)
- Refresh button, create button (navigates to `/offers/new`)
- Total offer count badge + `roleBadgeClass` / `defaultRoleBadgeClass` styling
- Loading skeleton (extra `Created By` column added at lines 262/282), empty states, error states

**State management:** `useState` for offers list, pagination, filters, delete target. `useEffect` refetches on filter/page changes. Auth via `useAuth` at line 46.

### `OfferFormPage.jsx` (src/pages/OfferFormPage.jsx, updated `a79e555`)

Create/edit form at `/offers/new` and `/offers/:id/edit` (requires `offers.create` / `offers.update`).

**Role-aware behavior (`a79e555`, lines 18/40/294):**
- Imports `useAuth` (`isSuperAdmin`) at line 18.
- Initial state defaults non-SuperAdmin scope to `hall`: `useState(() => isSuperAdmin ? EMPTY_FORM : { ...EMPTY_FORM, scope: "hall" })` (line 40).
- Scope `<Select>` hides `Global (all halls)` for non-SuperAdmin (`{isSuperAdmin && <SelectItem value="global">...}` at line 298) and shows helper `text-xs text-muted-foreground` "Only Super Admin can create offers valid across all halls." when `!isSuperAdmin`.

**Fields:**
| Section | Fields |
|---|---|
| Offer Details | Code (uppercase, disabled on edit), Active toggle, Title, Description, Discount Type (percentage/fixed), Discount Value, Max Discount Cap (percentage only), Min Booking Amount |
| Schedule & Targeting | Valid Until (date picker), Scope (global/hall with role gate), Cinema Hall (hall scope only, `GET /cinema-halls` filtered by `resolveOrgId` for org members), User Eligibility (all/joined_after), Joined After date (joined_after only) |

**On create:** Sends uppercased code, numeric conversions, conditional nulls for optional fields. Server enforces global-only-SuperAdmin and hall-org match (`6e0705a`).
**On edit:** Loads existing offer via `offersAPI.getById(id)` (creator owned for non-SuperAdmin else `403`), pre-fills form, updates via `offersAPI.update(id, payload)`.
**Validation:** Client-side checks for required fields, hall selection, joined_after date. Server re-validates scope/hall ownership.

### `services/api.js` — `offersAPI`

```js
offersAPI.getCinemaHalls()          // GET /api/offers/cinema-halls
offersAPI.getAll(filters)           // GET /api/offers?scope=&is_active=&search=&page=
offersAPI.create(data)              // POST /api/offers/create
offersAPI.getById(id)              // GET /api/offers/:id
offersAPI.update(id, data)         // PUT /api/offers/update/:id
offersAPI.delete(id)               // DELETE /api/offers/delete/:id
```

All calls use `credentials: 'include'` for cookie/session auth. POST/PUT set JSON content type.

---

## User App — `cinema-hall-users`

### `OffersPage.jsx` (src/pages/OffersPage.jsx)

Customer-facing offer browsing page.

**Features:**
- Grid layout (responsive: 1/2/3 columns)
- Each card shows: title, discount value (formatted large text), description, min booking amount, validity date, hall name (if hall-scoped), eligibility info
- Cards marked `is_redeemed` are dimmed (60% opacity) with strikethrough code and "Applied" badge
- "Ending soon" badge shown if valid_until ≤ 3 days away
- Click-to-copy code button with checkmark feedback (2s timeout)
- Loading skeleton (3 cards), empty state, requires-login prompt

**Discount formatting:**
```
fixed:      "₹100 OFF"
percentage: "10% OFF up to ₹150"  // if max_discount_amount set
percentage: "10% OFF"             // if no cap
```

### `services/api.js` — `offersAPI`

```js
offersAPI.getActive()                  // GET /api/offers/active
offersAPI.validateOffer({offer_code, show_id, total_amount})  // POST /api/offers/validate
```
