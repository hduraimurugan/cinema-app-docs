# Frontend

## Admin App — `cinema-hall-admin`

### `OffersManagement.jsx` (src/pages/OffersManagement.jsx)

Offer list page accessible at `/offers`.

**Features:**
- Search by code or title (debounced 400ms)
- Filter by scope (all / global / hall) and status (all / active / inactive)
- Paginated table (50 per page) with Prev/Next controls
- Each row shows: code, title, discount (formatted), scope badge, eligibility, valid until, status badge
- Row actions: edit pencil (navigates to `/offers/:id/edit`) and delete trash (confirmation dialog)
- Export button: downloads visible offers as CSV with columns Code, Title, Discount, Scope, etc.
- Refresh button, create button (navigates to `/offers/new`)
- Total offer count badge
- Loading skeleton, empty states, error states

**State management:** `useState` for offers list, pagination, filters, delete target. `useEffect` refetches on filter/page changes.

### `OfferFormPage.jsx` (src/pages/OfferFormPage.jsx)

Create/edit form accessible at `/offers/new` and `/offers/:id/edit`.

**Fields:**
| Section | Fields |
|---|---|
| Offer Details | Code (uppercase, disabled on edit), Active toggle, Title, Description, Discount Type (percentage/fixed), Discount Value, Max Discount Cap (percentage only), Min Booking Amount |
| Schedule & Targeting | Valid Until (date picker), Scope (global/hall), Cinema Hall (hall scope only, loaded from API), User Eligibility (all/joined_after), Joined After date (joined_after only) |

**On create:** Sends uppercased code, numeric conversions, conditional nulls for optional fields.
**On edit:** Loads existing offer via `offersAPI.getById(id)`, pre-fills form, updates via `offersAPI.update(id, payload)`.
**Validation:** Client-side checks for required fields, hall selection, joined_after date.

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
