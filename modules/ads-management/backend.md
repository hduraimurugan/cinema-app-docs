# Ads Management - Backend

## Routes

### `ads.routes.js`
- **Path**: `routes/ads.routes.js`
- **Purpose**: Ad management and click tracking endpoints

| Endpoint | Method | Middleware | Controller |
|----------|--------|-----------|------------|
| `/api/ads` | GET | `verifySuperAdmin` | `getAllAds` |
| `/api/ads/create` | POST | `verifySuperAdmin` | `createAd` |
| `/api/ads/update/:id` | PUT | `verifySuperAdmin` | `updateAd` |
| `/api/ads/delete/:id` | DELETE | `verifySuperAdmin` | `deleteAd` |
| `/api/ads/:id/announce` | POST | `verifySuperAdmin` | `announceAdById` (`99c1870`) |
| `/api/ads/:id/clicks` | GET | `verifySuperAdmin` | `getAdClicks` |
| `/api/ads/active?placement=banner` | GET | - | `getActiveAds` |
| `/api/ads/click/:id` | POST | - | `recordClick` |

## Controllers

### `ads.Controller.js`
- **Path**: `controllers/ads.Controller.js`

| Function | Purpose |
|----------|---------|
| `getAllAds` | Lists all ads with total click count via LEFT JOIN `ad_clicks`, grouped and ordered by `created_at DESC` |
| `createAd` | Inserts new ad with validation on required fields (title, image_url, placement, start_date, end_date) |
| `updateAd` | Full UPDATE on all ad fields by ID, sets `updated_at = NOW()`, returns 404 if not found |
| `deleteAd` | Hard DELETE by ID (cascades to ad_clicks via FK), returns 404 if not found |
| `getAdClicks` | Lists click-throughs for an ad with customer info (name, email, phone) via LEFT JOIN `customers` |
| `getActiveAds` | Returns active ads for a placement: `is_active=true`, placement match, `start_date <= CURRENT_DATE`, `end_date >= CURRENT_DATE` |
| `recordClick` | Records a click with optional customer identification from `cusAccessToken` cookie (jwt.verify), continues anonymously on failure/missing token |
