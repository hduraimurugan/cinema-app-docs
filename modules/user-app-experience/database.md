# Database — User App Experience

## Collections / Models

### `movies`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `title` | String | Movie title |
| `slug` | String | URL-safe slug |
| `poster_url` | String | Poster image URL |
| `backdrop_url` | String | Backdrop image URL |
| `genre` | [String] | Genre tags (Action, Comedy, etc.) |
| `language` | [String] | Available languages |
| `duration_minutes` | Number | Runtime in minutes |
| `release_date` | Date | Theatrical release date |
| `rating` | String | Rating (U/A, PG-13, etc.) |
| `synopsis` | String | Plot summary |
| `cast` | [{ name, role, image_url }] | Cast and crew |
| `status` | String | `now-showing`, `coming-soon`, `archived` |
| `created_at` | Date | Auto-generated |
| `updated_at` | Date | Auto-generated |

**Indexes:** `{ status: 1, release_date: -1 }`, `{ genre: 1 }`, `{ language: 1 }`, `{ slug: 1 } (unique)`

### `halls` (Theatres)

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `name` | String | Hall name |
| `location` | Object | `{ city, state, address, coordinates }` |
| `amenities` | [String] | List of amenities |
| `layout` | Object | Seat layout configuration (total rows, columns, sections) |
| `seat_categories` | [{ name, color, price }] | Pricing tiers (Premium, Gold, Silver) |
| `status` | String | `active`, `inactive` |
| `created_at` | Date | Auto-generated |
| `updated_at` | Date | Auto-generated |

**Indexes:** `{ "location.city": 1 }`, `{ status: 1 }`

### `shows`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `hall_id` | ObjectId | Ref → halls |
| `movie_id` | ObjectId | Ref → movies |
| `show_date` | Date | Date of the show |
| `start_time` | Date | Start time |
| `end_time` | Date | Estimated end time |
| `seat_pricing` | Object | `{ premium: price, gold: price, silver: price }` — overrides hall defaults |
| `seat_layout` | [[Object]] | 2D array of seat objects with `{ row, col, category, status, label }` |
| `status` | String | `scheduled`, `in-progress`, `completed`, `cancelled` |
| `has_offer` | Boolean | Whether show participates in active offers |
| `created_at` | Date | Auto-generated |
| `updated_at` | Date | Auto-generated |

**Indexes:** `{ hall_id: 1, show_date: 1, start_time: 1 }`, `{ movie_id: 1, show_date: 1 }`, `{ status: 1 }`

### `bookings`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `user_id` | ObjectId | Ref → users |
| `show_id` | ObjectId | Ref → shows |
| `hall_id` | ObjectId | Ref → halls (denormalized for fast queries) |
| `movie_id` | ObjectId | Ref → movies (denormalized) |
| `seats` | [{ row, col, category, label }] | Selected seats array |
| `total_amount` | Number | Total amount in paise |
| `discount_amount` | Number | Discount applied (paise) |
| `offer_code` | String | Applied offer code (if any) |
| `payment_status` | String | `pending`, `paid`, `failed`, `refunded` |
| `payment_id` | String | Razorpay payment ID |
| `order_id` | String | Razorpay order ID |
| `booking_status` | String | `hold`, `confirmed`, `cancelled`, `released` |
| `hold_expires_at` | Date | TTL for seat hold |
| `confirmed_at` | Date | When booking was confirmed |
| `qr_code` | String | QR code data for entry |
| `created_at` | Date | Auto-generated |
| `updated_at` | Date | Auto-generated |

**Indexes:** `{ user_id: 1, created_at: -1 }`, `{ show_id: 1, booking_status: 1, seats: 1 }`, `{ payment_id: 1 } (unique, sparse)`, `{ order_id: 1 } (unique, sparse)`, `{ hold_expires_at: 1 } (TTL index)`

### `offers`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `code` | String | Promo code (e.g. `WELCOME50`) |
| `description` | String | Human-readable offer text |
| `discount_type` | String | `percentage` or `flat` |
| `discount_value` | Number | Discount amount/percentage |
| `min_order_value` | Number | Minimum order amount (paise) |
| `max_discount` | Number | Maximum discount cap (paise) |
| `usage_limit` | Number | Max times code can be used |
| `used_count` | Number | Current usage count |
| `valid_from` | Date | Offer start date |
| `valid_until` | Date | Offer expiry date |
| `status` | String | `active`, `inactive`, `expired` |
| `created_at` | Date | Auto-generated |
| `updated_at` | Date | Auto-generated |

**Indexes:** `{ code: 1 } (unique)`, `{ status: 1, valid_from: 1, valid_until: 1 }`

### `ads`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `title` | String | Ad title |
| `image_url` | String | Banner/image URL |
| `link_url` | String | Click-through URL |
| `placement` | String | `homepage`, `movie-detail`, `theatre-list` |
| `clicks` | Number | Click counter |
| `status` | String | `active`, `inactive` |
| `valid_from` | Date | Start date |
| `valid_until` | Date | End date |
| `created_at` | Date | Auto-generated |
| `updated_at` | Date | Auto-generated |

**Indexes:** `{ placement: 1, status: 1, valid_from: 1, valid_until: 1 }`

### `settings`

| Field | Type | Description |
|-------|------|-------------|
| `_id` | ObjectId | Primary key |
| `key` | String | Setting key (e.g. `razorpay_key_id`) |
| `value` | Mixed | Setting value |
| `public` | Boolean | Whether exposed via GET /api/settings |
| `updated_at` | Date | Auto-generated |

**Indexes:** `{ key: 1 } (unique)`
