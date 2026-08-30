# Ads Management - Frontend

## Admin App (`cinema-hall-admin`)

### Pages

#### `AdsManagement.jsx`
- **Path**: `src/pages/AdsManagement.jsx`
- **Purpose**: Full ad management page with card grid and analytics table views, create/edit via slide-over sheet, click-through detail dialog, and delete confirmation
- **State**: `ads[]`, `loading`, `formOpen`, `editingAd`, `formData` (title, image_url, click_url, placement, start_date, end_date, is_active), `formLoading`, `clicksOpen`, `clicksAd`, `clicks[]`, `clicksLoading`, `deleteTarget`, `deleteLoading`
- **API Usage**: `adsAPI.getAll()`, `adsAPI.create()`, `adsAPI.update()`, `adsAPI.delete()`, `adsAPI.getClicks()`
- **Data Flow**: On mount fetches all ads. Two tabs: "Ads" (card grid with image previews, placement badges, click counts) and "Analytics" (tabular view with all fields + export). Create/edit via Sheet with inline preview. Click-throughs shown in a Dialog with customer details table.
- **Key Functions**:
  - `loadAds` - Fetches all ads on mount
  - `openCreate` / `openEdit` - Opens sheet with empty or pre-filled form
  - `handleFormSubmit` - Creates or updates ad via API
  - `handleDelete` - Deletes ad with confirmation dialog
  - `openClicks` - Fetches and displays click-through details for an ad
- **Form Fields**:
  - `title` (text, required)
  - `image_url` (text + live preview, required)
  - `click_url` (text, optional)
  - `placement` (select: banner/side, required)
  - `start_date` / `end_date` (date pickers, required)
  - `is_active` (toggle switch)

### Services

#### `api.js` (adsAPI section)
- **Path**: `src/services/api.js` (line 740)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `getAll()` | GET `/api/ads` | List all ads with click counts |
| `create(data)` | POST `/api/ads/create` | Create a new ad (accepts `notify` payload; response `announced`) |
| `update(id, data)` | PUT `/api/ads/update/:id` | Update an existing ad |
| `delete(id)` | DELETE `/api/ads/delete/:id` | Delete an ad |
| `announce(id, data)` | POST `/api/ads/:id/announce` | Announce an existing ad (`99c1870`) |
| `getClicks(id)` | GET `/api/ads/:id/clicks` | Get click-through details |

- **Auth**: All admin endpoints use `credentials: 'include'` for cookie-based auth

---

## User App (`cinema-hall-users`)

### Components

#### `AdBanner.jsx`
- **Path**: `src/components/AdBanner.jsx`
- **Purpose**: Displays active banner ads in an auto-rotating carousel with AD badge, click tracking, and dot navigation
- **State**: `ads[]`, `currentIndex`, `emblaApi`
- **API Usage**: `adsAPI.getActive('banner')`, `adsAPI.recordClick(adId)`
- **Data Flow**: On mount fetches active banner ads. Renders a full-width embla-carousel with autoplay (3s delay). Each slide is clickable — records click via API and opens `click_url` in new tab. Returns null if no ads available.
- **Key Behaviors**:
  - Autoplay with 3s delay, `stopOnInteraction: false`
  - Loop enabled, drag disabled
  - Dot indicators appear when > 1 ad
  - Click handler fires `recordClick` (fire-and-forget) then `window.open` to click_url
  - AD badge overlay on each slide
  - Responsive aspect ratios: `3/1` (mobile) to `5/1` (desktop)

### Services

#### `api.js` (adsAPI section)
- **Path**: `src/services/api.js` (line 436)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `getActive(placement)` | GET `/api/ads/active?placement=` | Fetch active ads for a placement |
| `recordClick(adId)` | POST `/api/ads/click/:id` | Record a click (with optional auth cookie) |
