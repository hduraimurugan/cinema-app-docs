# Ads Management - API

## Admin Endpoints

### GET `/api/ads`
- **Description**: List all ads with total click count
- **Auth**: `verifySuperAdmin`
- **Success (200)**: `{ ads: [{ id, title, image_url, click_url, placement, start_date, end_date, is_active, created_at, updated_at, click_count }] }`

### POST `/api/ads/create`
- **Description**: Create a new ad
- **Auth**: `verifySuperAdmin`
- **Body**: `{ title, image_url, click_url?, placement, start_date, end_date, is_active? }`
- **Required**: `title`, `image_url`, `placement`, `start_date`, `end_date`
- **Defaults**: `is_active` defaults to `true`, `click_url` defaults to `null`
- **Success (201)**: `{ ad: { ...full ad object } }`
- **Errors**: 400 (missing required fields)

### PUT `/api/ads/update/:id`
- **Description**: Full update of an ad
- **Auth**: `verifySuperAdmin`
- **Body**: `{ title, image_url, click_url?, placement, start_date, end_date, is_active }`
- **Success (200)**: `{ ad: { ...updated ad object } }`
- **Errors**: 404 (ad not found)

### DELETE `/api/ads/delete/:id`
- **Description**: Hard delete an ad (cascades to ad_clicks)
- **Auth**: `verifySuperAdmin`
- **Success (200)**: `{ message: "Ad deleted" }`
- **Errors**: 404 (ad not found)

### GET `/api/ads/:id/clicks`
- **Description**: List click-throughs for an ad with customer details
- **Auth**: `verifySuperAdmin`
- **Success (200)**: `{ clicks: [{ id, clicked_at, customer_name, customer_email, customer_phone }] }`
- **Notes**: Anonymous clicks return null for customer fields

## Public Endpoints

### GET `/api/ads/active?placement=banner`
- **Description**: Get currently active ads for a placement
- **Auth**: None (public)
- **Query**: `placement` (required) - e.g. `banner`, `sidebar`, `popup`
- **Success (200)**: `{ ads: [{ id, title, image_url, click_url, placement }] }`
- **Errors**: 400 (placement query param required)
- **Filters**: `is_active=true`, `placement` match, `start_date <= today`, `end_date >= today`

### POST `/api/ads/click/:id`
- **Description**: Record an ad click with optional customer attribution
- **Auth**: None (public, optional auth via cookie)
- **Success (200)**: `{ recorded: true }`
- **Notes**: If `cusAccessToken` cookie is present and valid, the click is attributed to that customer. Invalid or missing tokens result in anonymous clicks.
