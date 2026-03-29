# Backend API Documentation

## Overview

The Cinema Hall Ticket Booking backend is built with **Express.js** and **PostgreSQL (via Neon)**, providing RESTful APIs for both cinema administrators and end-users. The system supports JWT-based authentication, role-based access control, and comprehensive cinema management features.

**Tech Stack:**

- **Runtime**: Node.js with Express.js
- **Database**: PostgreSQL (Neon serverless)
- **Authentication**: JWT with HttpOnly cookies (access + refresh tokens)
- **Deployment**: Vercel-ready with local development support

---

## Database Schema

### Entity Relationship Diagram

```mermaid
erDiagram
    cinema_admin_user ||--o{ cinema_hall : "owns"
    cinema_hall ||--o{ screens : "contains"
    screens ||--o{ shows : "hosts"
    movies ||--o{ shows : "featured in"
    shows ||--o{ show_booked_seats : "has bookings"
    shows ||--o{ bookings : "has bookings"
    shows ||--o{ payment_orders : "has orders"
    customers ||--o{ bookings : "makes"
    customers ||--o{ payment_orders : "creates"
    customers ||--o{ otp_verifications : "verifies"
    customers ||--o{ ad_clicks : "clicks"
    ads ||--o{ ad_clicks : "receives"
    offers ||--o{ offer_redemptions : "redeemed via"
    customers ||--o{ offer_redemptions : "uses"
    bookings ||--o| offer_redemptions : "linked to"
    cinema_hall ||--o{ offers : "scoped to (optional)"
    cinema_admin_user ||--o{ offers : "created by"

    settings {
        text key PK
        text value
        timestamptz updated_at
    }

    cinema_admin_user {
        uuid id PK
        text email UK
        text password
        text name
        text phone
        text role
        timestamptz created_at
    }

    cinema_hall {
        uuid id PK
        uuid admin_id FK
        text name
        text location
        text district
        text state
        timestamptz created_at
    }

    screens {
        uuid id PK
        uuid cinema_hall_id FK
        text name
        int total_seats
        int premium_seats
        int gold_seats
        int silver_seats
        numeric premium_price
        numeric gold_price
        numeric silver_price
        int rows
        int columns
        text screen_position
        jsonb layout
        timestamptz created_at
    }

    movies {
        uuid id PK
        int tmdb_id
        text title
        text description
        text poster_url
        text trailer_url
        int duration_mins
        text[] genre
        text[] language
        text status
        date release_date
        jsonb cast
        numeric vote_average
        int vote_count
        timestamptz created_at
    }

    shows {
        uuid id PK
        uuid movie_id FK
        uuid screen_id FK
        date show_date
        time start_time
        time end_time
        text status
        text language_version
        jsonb price_override
        timestamptz created_at
    }

    show_booked_seats {
        uuid id PK
        uuid show_id FK
        text seat_id
        text seat_label
        text row_label
        int column_number
        text status
        timestamptz booked_at
        timestamptz lock_expires_at
    }

    offers {
        uuid id PK
        varchar code UK
        varchar title
        text description
        varchar discount_type
        numeric discount_value
        numeric max_discount_amount
        numeric min_booking_amount
        boolean is_active
        timestamptz valid_until
        varchar scope
        uuid cinema_hall_id FK
        varchar user_eligibility
        timestamptz user_joined_after
        uuid created_by FK
        timestamptz created_at
    }

    offer_redemptions {
        uuid id PK
        uuid offer_id FK
        uuid customer_id FK
        uuid booking_id FK
        numeric discount_applied
        timestamptz created_at
    }

    bookings {
        uuid id PK
        uuid customer_id FK
        uuid show_id FK
        text[] seats
        decimal total_amount
        decimal convenience_fee
        decimal gst_amount
        varchar payment_status
        varchar payment_id
        varchar booking_status
        varchar offer_code
        numeric discount_amount
        timestamptz created_at
        timestamptz updated_at
    }

    customers {
        uuid id PK
        text email UK
        text password
        text name
        text phone
        text district
        text state
        boolean is_verified
        timestamptz created_at
        timestamptz updated_at
    }

    payment_orders {
        uuid id PK
        varchar order_id UK
        uuid show_id FK
        uuid customer_id FK
        jsonb seats
        decimal amount
        decimal convenience_fee
        decimal gst_amount
        varchar status
        varchar payment_id
        varchar payment_signature
        varchar offer_code
        numeric discount_amount
        timestamptz created_at
        timestamptz updated_at
    }

    otp_verifications {
        uuid id PK
        text email FK
        text otp
        boolean is_verified
        timestamptz created_at
        timestamptz expires_at
    }

    ads {
        uuid id PK
        varchar title
        text image_url
        text click_url
        varchar placement
        date start_date
        date end_date
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    ad_clicks {
        uuid id PK
        uuid ad_id FK
        uuid customer_id FK
        timestamptz clicked_at
    }
```

### Key Database Features

#### Constraints

- **Unique screen showtime**: Prevents double-booking same screen at same time
- **Show overlap prevention**: Trigger function prevents overlapping shows on same screen
- **Show status values**: `scheduled` | `booking_started` | `in_progress` | `show_ended` | `cancelled`

#### Triggers

- **`prevent_overlapping_shows()`**: Validates show times don't overlap on INSERT/UPDATE
- **`update_updated_at_column()`**: Auto-updates `updated_at` timestamp for customers

#### Data Types

- **Arrays**: `genre[]`, `language[]` for multi-value fields
- **JSONB**: `layout`, `price_override`, `seats` for flexible structured data
- **UUID**: All primary keys use `gen_random_uuid()`

---

## Authentication System

### Admin Authentication Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant DB
    participant JWT

    Client->>API: POST /api/auth/register
    API->>DB: Insert cinema_admin_user + cinema_hall
    DB-->>API: Return admin + hall data
    API-->>Client: 201 Created

    Client->>API: POST /api/auth/login
    API->>DB: SELECT admin + hall by email
    DB-->>API: Return admin data
    API->>JWT: Generate access + refresh tokens
    JWT-->>API: Return tokens
    API->>Client: Set HttpOnly cookies
    API-->>Client: 200 OK + admin data

    Client->>API: GET /api/auth/me (with cookies)
    API->>JWT: Verify access token
    JWT-->>API: Decoded payload
    API->>DB: Fetch admin + hall details
    DB-->>API: Return data
    API-->>Client: 200 OK + admin info

    Client->>API: POST /api/auth/refresh (refresh token)
    API->>JWT: Verify refresh token
    JWT-->>API: Valid
    API->>JWT: Generate new access token
    API->>Client: Set new access token cookie
    API-->>Client: 200 OK

    Client->>API: POST /api/auth/logout
    API->>Client: Clear cookies
    API-->>Client: 200 OK
```

### Customer Authentication Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant DB
    participant Email

    Client->>API: POST /api/customer/signup
    API->>DB: Insert customer (is_verified=false)
    DB-->>API: Return customer data
    API-->>Client: 201 Created

    Client->>API: POST /api/otp/send
    API->>DB: Insert OTP record
    API->>Email: Send OTP email
    Email-->>Client: OTP received
    API-->>Client: 200 OK

    Client->>API: POST /api/otp/verify
    API->>DB: Validate OTP + update customer.is_verified
    DB-->>API: Success
    API-->>Client: 200 OK

    Client->>API: POST /api/customer/login
    API->>DB: Validate credentials + check is_verified
    DB-->>API: Customer data
    API->>Client: Set cusAccessToken + cusRefreshToken
    API-->>Client: 200 OK + customer data
```

### Token Strategy

| Token Type       | Cookie Name       | Expiry | Purpose            |
| ---------------- | ----------------- | ------ | ------------------ |
| Admin Access     | `accessToken`     | 1 day  | API authentication |
| Admin Refresh    | `refreshToken`    | 7 days | Token renewal      |
| Customer Access  | `cusAccessToken`  | 1 day  | API authentication |
| Customer Refresh | `cusRefreshToken` | 7 days | Token renewal      |

**Security Features:**

- HttpOnly cookies (prevents XSS)
- SameSite policy (production: `None`, dev: `Lax`)
- Secure flag in production
- Bcrypt password hashing (10 rounds)

---

## API Endpoints

### Admin Authentication (`/api/auth`)

| Method | Endpoint    | Auth          | Description                         |
| ------ | ----------- | ------------- | ----------------------------------- |
| POST   | `/register` | None          | Register cinema admin + create hall |
| POST   | `/login`    | None          | Login admin                         |
| POST   | `/logout`   | None          | Clear auth cookies                  |
| GET    | `/me`       | Access Token  | Get logged-in admin + hall info     |
| POST   | `/refresh`  | Refresh Token | Refresh access token                |

#### POST `/api/auth/register`

**Request Body:**

```json
{
  "name": "John Doe",
  "email": "admin@cinema.com",
  "password": "securepass123",
  "phone": "+1234567890",
  "hall_name": "Grand Cinema",
  "hall_location": "Downtown Plaza",
  "hall_district": "Mumbai",
  "hall_state": "Maharashtra"
}
```

**Response (201):**

```json
{
  "message": "Cinema admin registered successfully!",
  "admin": {
    "id": "uuid",
    "name": "John Doe",
    "email": "admin@cinema.com",
    "phone": "+1234567890",
    "created_at": "2024-01-29T10:00:00Z"
  },
  "hall": {
    "id": "uuid",
    "name": "Grand Cinema",
    "location": "Downtown Plaza",
    "district": "Mumbai",
    "state": "Maharashtra",
    "created_at": "2024-01-29T10:00:00Z"
  }
}
```

#### POST `/api/auth/login`

**Request Body:**

```json
{
  "email": "admin@cinema.com",
  "password": "securepass123"
}
```

**Response (200):**

```json
{
  "message": "Login successful",
  "accessToken": "jwt-token",
  "refreshToken": "jwt-refresh-token",
  "admin": {
    "id": "uuid",
    "name": "John Doe",
    "email": "admin@cinema.com",
    "phone": "+1234567890",
    "role": "admin",
    "created_at": "2024-01-29T10:00:00Z"
  },
  "hall": {
    "id": "uuid",
    "name": "Grand Cinema",
    "location": "Downtown Plaza",
    "district": "Mumbai",
    "state": "Maharashtra",
    "created_at": "2024-01-29T10:00:00Z"
  }
}
```

---

### Customer Authentication (`/api/customer`)

| Method | Endpoint   | Auth           | Description                                |
| ------ | ---------- | -------------- | ------------------------------------------ |
| POST   | `/signup`  | None           | Register customer                          |
| POST   | `/login`   | None           | Login customer (requires OTP verification) |
| POST   | `/logout`  | None           | Clear auth cookies                         |
| GET    | `/me`      | Customer Token | Get logged-in customer info                |
| PUT    | `/update`  | Customer Token | Update customer profile                    |
| POST   | `/refresh` | Refresh Token  | Refresh access token                       |

#### POST `/api/customer/signup`

**Request Body:**

```json
{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "password": "password123",
  "phone": "+9876543210",
  "district": "Pune",
  "state": "Maharashtra"
}
```

**Response (201):**

```json
{
  "message": "Customer registered successfully! Please verify your email with OTP.",
  "customer": {
    "id": "uuid",
    "name": "Jane Smith",
    "email": "jane@example.com",
    "phone": "+9876543210",
    "district": "Pune",
    "state": "Maharashtra",
    "is_verified": false,
    "created_at": "2024-01-29T10:00:00Z"
  }
}
```

---

### OTP Verification (`/api/otp`)

| Method | Endpoint  | Auth | Description                           |
| ------ | --------- | ---- | ------------------------------------- |
| POST   | `/send`   | None | Send OTP to email                     |
| POST   | `/verify` | None | Verify OTP and mark customer verified |

#### POST `/api/otp/send`

**Request Body:**

```json
{
  "email": "jane@example.com"
}
```

**Response (200):**

```json
{
  "message": "OTP sent to email"
}
```

#### POST `/api/otp/verify`

**Request Body:**

```json
{
  "email": "jane@example.com",
  "otp": "123456"
}
```

**Response (200):**

```json
{
  "message": "OTP verified successfully",
  "customer": {
    "id": "uuid",
    "email": "jane@example.com",
    "is_verified": true
  }
}
```

---

### Movies Management (`/api/movies`)

| Method | Endpoint           | Auth       | Description                 |
| ------ | ------------------ | ---------- | --------------------------- |
| POST   | `/add`             | SuperAdmin | Add new movie               |
| PUT    | `/edit/:movieId`   | SuperAdmin | Edit movie details          |
| DELETE | `/delete/:movieId` | SuperAdmin | Delete movie                |
| GET    | `/`                | None       | Get all movies with filters |
| GET    | `/:id`             | None       | Get single movie by ID      |
| PATCH  | `/:movieId/status` | SuperAdmin | Update movie status         |

#### POST `/api/movies/add`

**Request Body:**

```json
{
  "title": "Inception",
  "description": "A mind-bending thriller",
  "poster_url": "https://example.com/poster.jpg",
  "trailer_url": "https://youtube.com/watch?v=xyz",
  "duration_mins": 148,
  "genre": ["Action", "Sci-Fi", "Thriller"],
  "language": ["English", "Hindi"],
  "release_date": "2024-02-15",
  "status": "upcoming",
  "tmdb_id": 27205,
  "vote_average": 8.4,
  "vote_count": 35820,
  "cast": [
    { "name": "Leonardo DiCaprio", "character": "Cobb", "profile_path": "/path.jpg", "order": 0 }
  ]
}
```

**Response (201):**

```json
{
  "id": "uuid",
  "title": "Inception",
  "description": "A mind-bending thriller",
  "poster_url": "https://example.com/poster.jpg",
  "trailer_url": "https://youtube.com/watch?v=xyz",
  "duration_mins": 148,
  "genre": ["Action", "Sci-Fi", "Thriller"],
  "language": ["English", "Hindi"],
  "release_date": "2024-02-15",
  "status": "upcoming",
  "tmdb_id": 27205,
  "vote_average": "8.40",
  "vote_count": 35820,
  "cast": [
    { "name": "Leonardo DiCaprio", "character": "Cobb", "profile_path": "/path.jpg", "order": 0 }
  ],
  "created_at": "2024-01-29T10:00:00Z"
}
```

> **Note:** `cast` is a PostgreSQL reserved keyword — the column is stored as `"cast"` (double-quoted) in all SQL queries.

#### GET `/api/movies`

**Query Parameters:**

- `page` (number): Page number (default: 1)
- `limit` (number): Items per page (default: 10)
- `genre` (string[]): Filter by genres (e.g., `?genre=Action&genre=Drama`)
- `language` (string[]): Filter by languages
- `status` (string): Filter by status (`upcoming`, `now_showing`, `ended`)
- `release_date` (date): Filter by release date
- `search` (string): Search in title/description

**Response (200):**

```json
{
  "movies": [
    {
      "id": "uuid",
      "title": "Inception",
      "genre": ["Action", "Sci-Fi"],
      "language": ["English", "Hindi"],
      "status": "now_showing",
      "release_date": "2024-02-15"
    }
  ],
  "page": 1,
  "limit": 10,
  "total": 25
}
```

---

### TMDB Proxy (`/api/tmdb`)

All endpoints require **SuperAdmin** authentication. The backend proxies requests to the TMDB API using a server-side bearer token (`TMDB_API_KEY` env var), so the key is never exposed to the browser.

| Method | Endpoint             | Auth       | Description                                  |
| ------ | -------------------- | ---------- | -------------------------------------------- |
| GET    | `/popular`           | SuperAdmin | Popular movies (paginated)                   |
| GET    | `/now-playing`       | SuperAdmin | Now-playing movies (paginated)               |
| GET    | `/in-theatres`       | SuperAdmin | Theatrical releases in the past 30 days      |
| GET    | `/upcoming`          | SuperAdmin | Upcoming movies (paginated)                  |
| GET    | `/top-rated`         | SuperAdmin | Top-rated movies (paginated)                 |
| GET    | `/search`            | SuperAdmin | Search TMDB by title (`?query=…`)            |
| GET    | `/movie/:tmdbId`     | SuperAdmin | Full movie details with videos + cast        |

#### Common Query Parameters (list endpoints)

| Parameter              | Type   | Description                                  |
| ---------------------- | ------ | -------------------------------------------- |
| `page`                 | number | TMDB page number (default: 1)                |
| `with_original_language` | string | ISO 639-1 language code filter (e.g. `ta`, `hi`) |

#### GET `/api/tmdb/movie/:tmdbId`

Fetches a single movie's full details including trailers and cast via TMDB's `append_to_response=videos,credits`.

**Response structure (relevant fields):**

```json
{
  "id": 27205,
  "title": "Inception",
  "overview": "A thief who steals corporate secrets...",
  "poster_path": "/edv5CZvWj09paQCbCcBnLkk8pYn.jpg",
  "runtime": 148,
  "release_date": "2010-07-16",
  "vote_average": 8.4,
  "vote_count": 35820,
  "videos": {
    "results": [
      { "key": "YoHD9XEInc0", "site": "YouTube", "type": "Trailer", "official": true }
    ]
  },
  "credits": {
    "cast": [
      { "name": "Leonardo DiCaprio", "character": "Cobb", "profile_path": "/path.jpg", "order": 0 }
    ]
  }
}
```

**Import mapping in the admin panel:**

| TMDB field                        | Saved as            |
| --------------------------------- | ------------------- |
| `id`                              | `tmdb_id`           |
| `title`                           | `title`             |
| `overview`                        | `description`       |
| `https://image.tmdb.org/t/p/w500` + `poster_path` | `poster_url` |
| First YouTube Trailer key         | `trailer_url`       |
| `runtime`                         | `duration_mins`     |
| `release_date`                    | `release_date`      |
| `vote_average`                    | `vote_average`      |
| `vote_count`                      | `vote_count`        |
| `credits.cast` (top 10)           | `cast` (JSONB)      |

---

### Screens Management (`/api/screens`)

| Method | Endpoint            | Auth        | Description                      |
| ------ | ------------------- | ----------- | -------------------------------- |
| POST   | `/create`           | Admin Token | Create screen with seat layout   |
| GET    | `/`                 | Admin Token | Get all screens for admin's hall |
| PUT    | `/update/:screenId` | Admin Token | Update screen details            |
| DELETE | `/delete/:screenId` | Admin Token | Delete screen                    |

#### POST `/api/screens/create`

**Request Body:**

```json
{
  "name": "Screen 1",
  "total_seats": 100,
  "premium_seats": 20,
  "gold_seats": 40,
  "silver_seats": 40,
  "premium_price": 500,
  "gold_price": 300,
  "silver_price": 200,
  "rows": 10,
  "columns": 10,
  "screen_position": "top",
  "layout": [
    {
      "id": "A1",
      "row": 0,
      "col": 0,
      "type": "premium",
      "label": "A1",
      "rowLabel": "A",
      "isAisle": false,
      "isEmpty": false
    }
  ]
}
```

**Response (201):**

```json
{
  "id": "uuid",
  "cinema_hall_id": "uuid",
  "name": "Screen 1",
  "total_seats": 100,
  "premium_seats": 20,
  "gold_seats": 40,
  "silver_seats": 40,
  "premium_price": 500,
  "gold_price": 300,
  "silver_price": 200,
  "rows": 10,
  "columns": 10,
  "screen_position": "top",
  "layout": [...],
  "created_at": "2024-01-29T10:00:00Z"
}
```

---

### Shows Management (`/api/shows`)

| Method | Endpoint                | Auth                 | Description                                       |
| ------ | ----------------------- | -------------------- | ------------------------------------------------- |
| POST   | `/create`               | Admin + Screen Owner | Create single show                                |
| POST   | `/bulk`                 | Admin + Screen Owner | Create multiple shows                             |
| PUT    | `/edit/:id`             | Admin + Screen Owner | Edit show details                                 |
| DELETE | `/delete/:id`           | Admin                | Delete show                                       |
| GET    | `/date/:date`           | Admin                | Get shows by date (grouped by movie)              |
| PUT    | `/booking-status/:id`   | Admin                | Open bookings (`open`) or revert to scheduled (`revert`) |
| PUT    | `/cancel/:id`           | Admin                | Cancel show + cancel bookings + initiate refunds  |
| GET    | `/get/:id`              | None                 | Get show details with seat layout                 |
| POST   | `/book/:showId`         | None                 | Book seats for show                               |

#### POST `/api/shows/create`

> **Note:** `show_date` is automatically normalized to `YYYY-MM-DD` format on the server using `dayjs` — any ISO datetime string (e.g. `2026-03-10T00:00:00Z`) is safely stripped to date-only before insertion.

**Request Body:**

```json
{
  "movie_id": "uuid",
  "screen_id": "uuid",
  "show_date": "2024-02-15",
  "start_time": "14:00:00",
  "end_time": "16:30:00",
  "language_version": "English",
  "price_override": {
    "premium": 600,
    "gold": 350,
    "silver": 250
  }
}
```

**Response (201):**

```json
{
  "id": "uuid",
  "movie_id": "uuid",
  "screen_id": "uuid",
  "show_date": "2024-02-15",
  "start_time": "14:00:00",
  "end_time": "16:30:00",
  "status": "scheduled",
  "language_version": "English",
  "price_override": {
    "premium": 600,
    "gold": 350,
    "silver": 250
  },
  "created_at": "2024-01-29T10:00:00Z"
}
```

#### POST `/api/shows/bulk`

**Request Body:**

```json
{
  "movie_id": "uuid",
  "screen_id": "uuid",
  "dates": ["2024-02-15", "2024-02-16", "2024-02-17"],
  "start_time": "14:00:00",
  "end_time": "16:30:00",
  "language_version": "English"
}
```

**Response (201):**

```json
{
  "message": "3 shows created successfully",
  "shows": [...]
}
```

#### GET `/api/shows/date/:date`

**Response (200):**

```json
{
  "date": "2024-02-15",
  "movies": [
    {
      "movie_id": "uuid",
      "title": "Inception",
      "poster_url": "...",
      "shows": [
        {
          "show_id": "uuid",
          "screen_name": "Screen 1",
          "start_time": "14:00:00",
          "end_time": "16:30:00",
          "language_version": "English"
        }
      ]
    }
  ]
}
```

#### PUT `/api/shows/booking-status/:id`

Opens or reverts booking availability for a show. Admin only.

**Request Body:**

```json
{ "action": "open" }
```

| `action` value | From status | To status | Condition |
|---|---|---|---|
| `"open"` | `scheduled` | `booking_started` | Always allowed |
| `"revert"` | `booking_started` | `scheduled` | Only if zero confirmed bookings exist |

**Response (200):**

```json
{ "message": "Booking opened successfully", "status": "booking_started" }
```

Returns `400` if the action is invalid, the show is in the wrong state, or (for revert) confirmed bookings already exist.

#### PUT `/api/shows/cancel/:id`

Cancels a show. Admin only. This action:
1. Sets `shows.status = 'cancelled'`
2. Sets `bookings.booking_status = 'cancelled'` for all paid bookings
3. Sets `payment_orders.status = 'refunded'` for related orders
4. Calls `razorpay.payments.refund()` for each paid booking's `payment_id`

Returns `400` if the show is already `cancelled` or `show_ended`.

**Response (200):**

```json
{
  "message": "Show cancelled successfully",
  "bookings_cancelled": 3,
  "refunds": [
    { "payment_id": "pay_xxx", "status": "refund_initiated" }
  ]
}
```

---

### User Movies (`/api/user/movies`)

| Method | Endpoint                 | Auth | Description                             |
| ------ | ------------------------ | ---- | --------------------------------------- |
| GET    | `/`                      | None | Get all movies with filters             |
| GET    | `/:id`                   | None | Get movie by ID                         |
| GET    | `/location/movies`       | None | Get movies by district + state          |
| GET    | `/state/movies`          | None | Get movies by state                     |
| GET    | `/:movieId/showtimes`    | None | Get movie with cinema halls + showtimes for a date |
| GET    | `/location/districts`    | None | Get districts in state                  |
| GET    | `/location/cinema-halls` | None | Get cinema halls in location            |
| GET    | `/location/theatres`     | None | Get cinema halls with movies + shows for a date |

#### GET `/api/user/movies/location/movies`

**Query Parameters:**

- `district` (string): District name
- `state` (string): State name

**Response (200):**

```json
{
  "movies": [
    {
      "id": "uuid",
      "title": "Inception",
      "genre": ["Action", "Sci-Fi"],
      "language": ["English", "Hindi"],
      "poster_url": "...",
      "status": "now_showing"
    }
  ]
}
```

#### GET `/api/user/movies/:movieId/showtimes`

Returns movie details with cinema halls and showtimes filtered to a specific date. Used by `MovieDetailsPage`.

**Query Parameters:**

- `district` (string, required): District name
- `state` (string, required): State name
- `date` (string, optional): Date in `YYYY-MM-DD` format — defaults to today if omitted

**Response (200):**

```json
{
  "movie": {
    "id": "uuid",
    "title": "Inception",
    "description": "...",
    "poster_url": "...",
    "duration_mins": 148
  },
  "cinema_halls": [
    {
      "cinema_hall_id": "uuid",
      "cinema_hall_name": "Grand Cinema",
      "cinema_hall_location": "Downtown Plaza",
      "district": "Mumbai",
      "state": "Maharashtra",
      "shows": [
        {
          "show_id": "uuid",
          "screen_id": "uuid",
          "screen_name": "Screen 1",
          "show_date": "2026-03-08",
          "start_time": "14:00:00",
          "end_time": "16:30:00",
          "language_version": "English",
          "show_status": "scheduled",
          "pricing": { "premium": 200, "gold": 150, "silver": 120 }
        }
      ]
    }
  ]
}
```

#### GET `/api/user/movies/location/theatres`

Returns all cinema halls in a location for a specific date, with their movies and showtimes grouped hierarchically. Used by TheatresPage.

**Query Parameters:**

- `district` (string, required): District name
- `state` (string, required): State name
- `date` (string, optional): Date in `YYYY-MM-DD` format — defaults to today

**Response (200):**

```json
{
  "success": true,
  "count": 1,
  "district": "Mumbai",
  "state": "Maharashtra",
  "date": "2026-03-08",
  "cinema_halls": [
    {
      "hall_id": "uuid",
      "hall_name": "Grand Cinema",
      "location": "Downtown Plaza",
      "district": "Mumbai",
      "state": "Maharashtra",
      "movies": [
        {
          "movie_id": "uuid",
          "title": "Inception",
          "poster_url": "...",
          "duration_mins": 148,
          "genre": ["Sci-Fi", "Thriller"],
          "language": ["English", "Hindi"],
          "shows": [
            {
              "show_id": "uuid",
              "screen_id": "uuid",
              "screen_name": "IMAX Screen",
              "start_time": "11:00:00",
              "end_time": "13:28:00",
              "show_date": "2026-03-08",
              "language_version": "English",
              "pricing": { "premium": 350, "gold": 250, "silver": 180 }
            }
          ]
        }
      ]
    }
  ]
}
```

---

### Booking (`/api/booking`)

| Method | Endpoint                     | Auth     | Description                                    |
| ------ | ---------------------------- | -------- | ---------------------------------------------- |
| POST   | `/hold`                      | Customer | Hold selected seats for 5 minutes              |
| POST   | `/confirm`                   | Customer | Convert held seats to booked (without payment) |
| POST   | `/release`                   | Customer | Release held seats voluntarily                 |
| GET    | `/by-payment/:payment_id`    | Customer | Fetch confirmed booking by Razorpay payment ID |
| GET    | `/my-bookings`               | Customer | List all bookings for the logged-in customer   |
| GET    | `/admin/all`                 | Admin    | List all bookings for admin's cinema hall      |
| GET    | `/admin/verify/:booking_id`  | Admin    | Verify a booking by UUID (QR scan lookup)      |

#### GET `/api/booking/by-payment/:payment_id`

Fetches a confirmed booking with full details using the Razorpay `payment_id`. Used by the success page after payment.

**Auth**: Customer required (ownership enforced — customer can only fetch their own booking)

**Response (200):**

```json
{
  "booking": {
    "id": "booking-uuid",
    "customer_id": "customer-uuid",
    "show_id": "show-uuid",
    "seats": ["0-0", "1-1"],
    "total_amount": "440.00",
    "payment_status": "completed",
    "payment_id": "pay_MlOhsFJKxD8SQz",
    "booking_status": "confirmed",
    "movie_title": "Paranthu Po",
    "show_date": "2026-03-06",
    "start_time": "11:00:00",
    "seat_labels": ["A1", "B2"]
  }
}
```

**Notes:**
- `seat_labels` are derived from `screens.layout` (e.g. row `"A"` + column `1` → `"A1"`)
- Returns `404` if payment_id not found or belongs to another customer

---

#### GET `/api/booking/my-bookings`

Lists all confirmed bookings for the currently logged-in customer, ordered by show date descending.

**Auth**: Customer required

**Response (200):**

```json
{
  "bookings": [
    {
      "id": "booking-uuid",
      "show_id": "show-uuid",
      "seats": ["0-0", "1-1"],
      "total_amount": "440.00",
      "payment_status": "completed",
      "payment_id": "pay_MlOhsFJKxD8SQz",
      "booking_status": "confirmed",
      "movie_title": "Paranthu Po",
      "show_date": "2026-03-06",
      "start_time": "11:00:00",
      "screen_name": "Screen 1",
      "cinema_hall_name": "Grand Cinema",
      "seat_labels": ["A1", "B2"]
    }
  ]
}
```

---

#### GET `/api/booking/admin/all`

Lists all bookings for shows in the admin's cinema hall. Supports filtering and pagination (50 per page).

**Auth**: Admin required (`verifyCinemaAdminAccessToken` + `verifyCinemaHall`)

**Query Parameters:**

| Param       | Type   | Description                                                        |
| ----------- | ------ | ------------------------------------------------------------------ |
| `date`      | date   | Filter by show date (e.g. `2026-03-07`)                            |
| `search`    | string | Filter by movie title (partial, case-insensitive)                  |
| `status`    | string | Filter by booking status (`confirmed`, `cancelled`, `completed`)   |
| `screen_id` | uuid   | Filter by screen ID (scoped to admin's cinema hall)                |
| `page`      | number | Page number (default: 1)                                           |

**Response (200):**

```json
{
  "bookings": [
    {
      "id": "booking-uuid",
      "show_id": "show-uuid",
      "seats": ["0-0", "1-1"],
      "total_amount": "440.00",
      "convenience_fee": "30.00",
      "gst_amount": "5.40",
      "booking_status": "confirmed",
      "movie_title": "Paranthu Po",
      "show_date": "2026-03-06",
      "start_time": "11:00:00",
      "screen_name": "Screen 1",
      "customer_name": "Jane Smith",
      "customer_email": "jane@example.com",
      "seat_labels": ["A1", "B2"]
    }
  ],
  "total": 120,
  "page": 1,
  "stats": {
    "total_revenue": 52800.00,
    "total_convenience_fee": 3600.00,
    "total_gst": 648.00
  }
}
```

> `stats` aggregates are scoped to the same filters as the `bookings` array — they reflect only the filtered result set, not all bookings.

#### GET `/api/booking/admin/verify/:booking_id`

Looks up a booking by its full UUID — used by the admin QR code scanner to verify a customer's ticket at the cinema entrance.

**Auth**: Admin required (`verifyCinemaAdminAccessToken` + `verifyCinemaHall`)

**Path Param**: `booking_id` — must be a valid UUID v4. Returns `400` if format is invalid.

**Security**: Result is scoped to the admin's cinema hall (`sc.cinema_hall_id = cinema_hall_id`). An admin cannot look up bookings from another cinema hall.

**Response (200):**

```json
{
  "booking": {
    "id": "booking-uuid",
    "show_id": "show-uuid",
    "seats": ["0-0", "1-1"],
    "total_amount": "340.00",
    "booking_status": "confirmed",
    "movie_title": "Thaai Kizhavi",
    "show_date": "2026-03-10",
    "start_time": "11:45:00",
    "screen_name": "Screen 1",
    "customer_name": "Jane Smith",
    "customer_email": "jane@example.com",
    "seat_labels": ["E7", "E8"]
  }
}
```

**Error Responses:**
- `400` — Invalid UUID format
- `404` — Booking not found (or belongs to a different cinema hall)

---

### Settings (`/api/settings`)

| Method | Endpoint | Auth | Description |
| ------ | -------- | ---- | ----------- |
| GET    | `/`      | None (public) | Get current system settings |
| PUT    | `/`      | SuperAdmin | Update convenience fee and/or GST percentage |

#### GET `/api/settings`

Returns system-wide booking fee configuration. Used by the user frontend to calculate the order total.

**Response (200):**

```json
{
  "convenience_fee_per_ticket": 15,
  "gst_percentage": 18
}
```

#### PUT `/api/settings`

Updates one or both settings. SuperAdmin only.

**Request Body:**

```json
{
  "convenience_fee_per_ticket": 20,
  "gst_percentage": 18
}
```

Both fields are optional — only the fields provided are updated.

**Response (200):**

```json
{ "message": "Settings updated successfully" }
```

**Validation:**
- `convenience_fee_per_ticket` must be ≥ 0
- `gst_percentage` must be between 0 and 100

#### settings table

```sql
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Default seed values
INSERT INTO settings (key, value) VALUES
  ('convenience_fee_per_ticket', '15'),
  ('gst_percentage', '18')
ON CONFLICT (key) DO NOTHING;
```

**Migration**: Run `migration_settings.sql`

---

### Ads (`/api/ads`)

| Method | Endpoint         | Auth          | Description                                      |
| ------ | ---------------- | ------------- | ------------------------------------------------ |
| GET    | `/active`        | None (public) | Get currently active ads filtered by `placement` |
| POST   | `/click/:id`     | None (optional customer cookie) | Record a click-through on an ad |
| GET    | `/`              | SuperAdmin    | List all ads with total click count              |
| POST   | `/create`        | SuperAdmin    | Create a new ad                                  |
| PUT    | `/update/:id`    | SuperAdmin    | Update an existing ad                            |
| DELETE | `/delete/:id`    | SuperAdmin    | Delete an ad (cascades click records)            |
| GET    | `/:id/clicks`    | SuperAdmin    | Get click-through details for a specific ad      |

#### GET `/api/ads/active?placement=banner`

Returns ads where `is_active = true` AND `start_date <= CURRENT_DATE <= end_date` for the given placement (`banner` or `side`). No auth required.

**Response (200):**

```json
{
  "ads": [
    {
      "id": "uuid",
      "title": "Summer Sale",
      "image_url": "https://example.com/banner.jpg",
      "click_url": "https://example.com/offer",
      "placement": "banner"
    }
  ]
}
```

#### POST `/api/ads/click/:id`

Records a click-through. If a valid `cusAccessToken` cookie is present, attaches the customer ID; otherwise records anonymously.

**Response (200):**

```json
{ "recorded": true }
```

#### GET `/api/ads/:id/clicks` *(SuperAdmin)*

**Response (200):**

```json
{
  "clicks": [
    {
      "id": "uuid",
      "clicked_at": "2026-03-14T10:30:00Z",
      "customer_name": "Jane Smith",
      "customer_email": "jane@example.com",
      "customer_phone": "+91 98765 43210"
    },
    {
      "id": "uuid",
      "clicked_at": "2026-03-14T11:00:00Z",
      "customer_name": null,
      "customer_email": null,
      "customer_phone": null
    }
  ]
}
```

> `customer_name` / `customer_email` / `customer_phone` are `null` for anonymous (non-logged-in) clicks.

#### Ad Fields

| Field        | Type    | Required | Description                                      |
| ------------ | ------- | -------- | ------------------------------------------------ |
| `title`      | string  | Yes      | Ad display name (admin reference)                |
| `image_url`  | string  | Yes      | URL of the ad image                              |
| `click_url`  | string  | No       | URL to open when the ad is clicked               |
| `placement`  | string  | Yes      | `"banner"` (MoviesPage carousel) or `"side"` (MovieInfoPage sidebar) |
| `start_date` | date    | Yes      | Date from which the ad becomes active            |
| `end_date`   | date    | Yes      | Date after which the ad stops serving            |
| `is_active`  | boolean | No       | Manual on/off toggle (default `true`)            |

---

### Offers (`/api/offers`)

| Method | Endpoint             | Auth          | Description                                              |
| ------ | -------------------- | ------------- | -------------------------------------------------------- |
| GET    | `/cinema-halls`      | SuperAdmin    | List all cinema halls (for hall-selector in admin form)  |
| GET    | `/`                  | SuperAdmin    | List all offers (paginated, filters: scope/is_active/search) |
| GET    | `/:id`               | SuperAdmin    | Fetch a single offer by ID (used by edit page)           |
| POST   | `/create`            | SuperAdmin    | Create a new offer                                       |
| PUT    | `/update/:id`        | SuperAdmin    | Update an existing offer                                 |
| DELETE | `/delete/:id`        | SuperAdmin    | Delete an offer (cascades redemptions)                   |
| GET    | `/active`            | Customer      | List active, eligible, non-expired offers for the logged-in user — includes redeemed offers with `is_redeemed: true` (sorted: available first) |
| POST   | `/validate`          | Customer      | Validate an offer code and calculate the discount preview |

#### Offer Fields

| Field                | Type    | Required | Description                                                          |
| -------------------- | ------- | -------- | -------------------------------------------------------------------- |
| `code`               | string  | Yes      | Unique coupon code (stored uppercase)                                |
| `title`              | string  | Yes      | Short display name shown to users                                    |
| `description`        | string  | No       | Longer description shown on the Offers page                          |
| `discount_type`      | string  | Yes      | `"percentage"` or `"fixed"`                                          |
| `discount_value`     | number  | Yes      | Percentage (e.g. `10` for 10%) or flat rupee amount (e.g. `50`)     |
| `max_discount_amount`| number  | No       | Maximum discount cap for percentage offers (e.g. `150` → max ₹150). `null` = no cap |
| `min_booking_amount` | number  | No       | Minimum grand total required for the offer to apply (default `0`)   |
| `is_active`          | boolean | No       | Manual on/off toggle (default `true`)                                |
| `valid_until`        | datetime| Yes      | Offer expires after this timestamp                                   |
| `scope`              | string  | Yes      | `"global"` (all halls) or `"hall"` (specific cinema hall)           |
| `cinema_hall_id`     | uuid    | No       | Required when `scope = "hall"`                                       |
| `user_eligibility`   | string  | Yes      | `"all"` or `"joined_after"`                                         |
| `user_joined_after`  | datetime| No       | Required when `user_eligibility = "joined_after"`. Only customers who registered after this date are eligible |

#### POST `/api/offers/validate`

Validates an offer code server-side and returns the calculated discount amount. **Does not record the redemption** — that happens in `verifyPayment`.

**Request Body:**

```json
{
  "offer_code": "SAVE50",
  "show_id": "uuid",
  "total_amount": 395.4
}
```

**Response (200):**

```json
{
  "offer_id": "uuid",
  "offer_code": "SAVE50",
  "offer_title": "Flat ₹50 Off",
  "discount_amount": 50,
  "final_amount": 345.4
}
```

**Validation checks (in order):**
1. Offer exists and `is_active = true`
2. `valid_until > NOW()`
3. `total_amount >= min_booking_amount`
4. If `scope = "hall"`: show's cinema hall matches offer's `cinema_hall_id`
5. If `user_eligibility = "joined_after"`: customer joined after `user_joined_after`
6. No prior entry in `offer_redemptions` for `(offer_id, customer_id)` (once per user)
7. Discount calculation: fixed → `discount_value`; percentage → `min(total × val/100, max_discount_amount)`

#### Offer Redemption Flow

```mermaid
sequenceDiagram
    participant U as User
    participant FE as OrderSummaryPage
    participant API as /api/offers/validate
    participant PAY as /api/payment/create-order
    participant VER as /api/payment/verify

    U->>FE: Enter coupon code
    FE->>API: POST /validate { offer_code, show_id, total_amount }
    API-->>FE: { discount_amount, final_amount }
    FE->>FE: Show discount in price breakdown
    U->>FE: Click Pay
    FE->>PAY: POST /create-order { show_id, seats, offer_code }
    PAY->>PAY: Re-validate offer server-side
    PAY->>PAY: Calculate final_amount = grandTotal - discount
    PAY-->>FE: Razorpay order with discounted amount
    FE->>VER: POST /verify { razorpay_order_id, ... }
    VER->>VER: Confirm booking + INSERT offer_redemptions
    VER-->>FE: { success: true, booking }
```

> **Security note:** The offer is always re-validated server-side in `createOrder` — the frontend discount preview is never trusted for the final charge.

---

### Customers (`/api/customers`)

| Method | Endpoint | Auth       | Description                              |
| ------ | -------- | ---------- | ---------------------------------------- |
| GET    | `/`      | SuperAdmin | List all customers with search + stats   |

#### GET `/api/customers` *(SuperAdmin)*

Returns a paginated list of all registered platform customers. Supports search across name, email, and phone.

**Query Parameters:**

| Param    | Type   | Default | Description                         |
| -------- | ------ | ------- | ----------------------------------- |
| `search` | string | —       | Filter by name, email, or phone     |
| `page`   | number | `1`     | Page number (50 results per page)   |

**Response (200):**

```json
{
  "customers": [
    {
      "id": "uuid",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "9876543210",
      "district": "Chennai",
      "state": "Tamil Nadu",
      "is_verified": true,
      "created_at": "2025-01-15T10:30:00Z",
      "booking_count": 5
    }
  ],
  "total": 120,
  "stats": {
    "total": 120,
    "verified": 98
  }
}
```

`booking_count` is the number of confirmed (paid) bookings for each customer. `stats` always reflects the full unfiltered totals.

---

### Cinema Hall Admins (`/api/auth/admins`)

| Method | Endpoint   | Auth       | Description                                         |
| ------ | ---------- | ---------- | --------------------------------------------------- |
| GET    | `/admins`  | SuperAdmin | List all cinema hall admins with their hall details |

#### GET `/api/auth/admins` *(SuperAdmin)*

Returns a paginated list of all registered cinema hall admins (excludes SuperAdmin). Supports search by admin name, email, or hall name.

**Query Parameters:**

| Param    | Type   | Default | Description                              |
| -------- | ------ | ------- | ---------------------------------------- |
| `search` | string | —       | Filter by name, email, or hall name      |
| `page`   | number | `1`     | Page number (50 results per page)        |

**Response (200):**

```json
{
  "admins": [
    {
      "id": "uuid",
      "name": "Ravi Kumar",
      "email": "ravi@example.com",
      "phone": "9876543210",
      "role": "admin",
      "created_at": "2025-02-01T08:00:00Z",
      "hall_id": "uuid",
      "hall_name": "Ravi Cinemas",
      "location": "Tirunelveli",
      "district": "Tirunelveli",
      "state": "Tamil Nadu"
    }
  ],
  "total": 12
}
```

`hall_id` / `hall_name` / `location` will be `null` if the admin has not yet created a cinema hall.

---

### Dashboard (`/api/dashboard`)

| Method | Endpoint  | Auth                   | Description                          |
| ------ | --------- | ---------------------- | ------------------------------------ |
| GET    | `/stats`  | Admin + Cinema Hall    | All dashboard metrics in one call    |

#### GET `/api/dashboard/stats` *(Admin + Cinema Hall)*

Returns everything the admin dashboard needs in a single request. All DB queries run in parallel via `Promise.all`. Scoped to `req.my_cinema_hall.id` (set by `verifyCinemaHall` middleware).

**Response (200):**

```json
{
  "today": {
    "bookings": 24,
    "revenue": 12400.00,
    "convenience_fee": 480.00,
    "gst": 480.00
  },
  "allTime": {
    "bookings": 1204,
    "revenue": 620000.00
  },
  "customers": 980,
  "activeOffers": 3,
  "screens": 3,
  "revenueTrend": [
    { "date": "2026-03-14", "revenue": 8200.00, "bookings_count": 18 },
    { "date": "2026-03-15", "revenue": 11500.00, "bookings_count": 24 }
  ],
  "recentBookings": [
    {
      "id": "uuid",
      "total_amount": "385.00",
      "booking_status": "confirmed",
      "created_at": "2026-03-20T14:32:00Z",
      "movie_title": "Superman",
      "customer_name": "Duraimurugan Don H",
      "seat_labels": ["C3", "C4"]
    }
  ],
  "todayShows": [
    {
      "id": "uuid",
      "start_time": "10:00:00",
      "status": "open",
      "movie_title": "KGF Chapter 2",
      "screen_name": "Screen 1",
      "total_seats": 120,
      "booked_seats": 45
    }
  ]
}
```

**Data sources:**

| Field | Query |
|-------|-------|
| `today` | `SUM(total_amount / convenience_fee / gst_amount)` + `COUNT(*)` filtered by `show_date = CURRENT_DATE` |
| `allTime` | Same aggregation without date filter |
| `customers` | `COUNT(*) FROM customers` (platform-wide) |
| `activeOffers` | `COUNT(*) FROM offers WHERE (cinema_hall_id = ? OR scope = 'global') AND is_active AND valid_until >= NOW()` |
| `screens` | `COUNT(*) FROM screens WHERE cinema_hall_id = ?` |
| `revenueTrend` | `generate_series(CURRENT_DATE - 6 days, CURRENT_DATE)` LEFT JOINed with bookings |
| `recentBookings` | Last 5 bookings with customer + movie + seat labels |
| `todayShows` | Shows with `show_date = CURRENT_DATE`, seat counts from `show_booked_seats` |

---

## Middleware

### Authentication Middleware

```mermaid
flowchart TD
    A[Request] --> B{Has Cookie?}
    B -->|No| C[401 Unauthorized]
    B -->|Yes| D[Verify JWT]
    D -->|Invalid| C
    D -->|Valid| E{Check Role}
    E -->|SuperAdmin Required| F{Is SuperAdmin?}
    E -->|Admin Required| G{Is Admin?}
    E -->|Customer Required| H{Is Customer?}
    F -->|No| I[403 Forbidden]
    F -->|Yes| J[Attach user to req]
    G -->|No| I
    G -->|Yes| J
    H -->|No| I
    H -->|Yes| J
    J --> K[Next Middleware]
```

### Middleware Functions

| Middleware                      | Purpose                       | Used In          |
| ------------------------------- | ----------------------------- | ---------------- |
| `verifyCinemaAdminAccessToken`  | Verify admin access token     | Admin routes     |
| `verifyCinemaAdminRefreshToken` | Verify admin refresh token    | Token refresh    |
| `verifySuperAdmin`              | Verify SuperAdmin role        | Movie CRUD, Ads, Offers, Customers, Admins list |
| `verifyCinemaHall`              | Verify admin owns cinema hall | Shows management |
| `verifyScreenOwnership`         | Verify admin owns screen      | Show creation    |
| `verifyCustomer`                | Verify customer access token  | Customer routes  |
| `verifyCustomerRefreshToken`    | Verify customer refresh token | Token refresh    |

---

## Request/Response Flow

```mermaid
sequenceDiagram
    participant Client
    participant CORS
    participant Auth
    participant Controller
    participant DB
    participant Response

    Client->>CORS: HTTP Request
    CORS->>CORS: Check origin
    CORS->>Auth: Pass if allowed
    Auth->>Auth: Verify JWT token
    Auth->>Controller: req.admin/req.customer
    Controller->>DB: Query/Mutation
    DB-->>Controller: Result
    Controller->>Response: Format JSON
    Response-->>Client: HTTP Response
```

---

## Error Handling

### Global Error Handler

All errors are caught by the global error handler in `server.js`:

```javascript
app.use((err, req, res, next) => {
  console.error("🔥 Global Error:", err.stack);
  res.status(500).json({ error: "Something went wrong!" });
});
```

### Common Error Responses

| Status | Error                 | Description                   |
| ------ | --------------------- | ----------------------------- |
| 400    | Bad Request           | Missing/invalid fields        |
| 401    | Unauthorized          | Invalid/missing token         |
| 403    | Forbidden             | Insufficient permissions      |
| 404    | Not Found             | Resource doesn't exist        |
| 409    | Conflict              | Show overlap, duplicate email |
| 500    | Internal Server Error | Database/server error         |

---

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:pass@host/db

# JWT
JWT_SECRET=your-secret-key

# Server
PORT=5000
NODE_ENV=production

# Email (for OTP)
EMAIL_SERVICE=gmail
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
```

---

## Deployment

### Vercel Configuration

The API is configured for Vercel serverless deployment via `vercel.json`:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "server.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "server.js"
    }
  ]
}
```

### CORS Configuration

Allowed origins:

- `http://localhost:5173` (Admin dev)
- `http://localhost:5174` (User dev)
- `http://localhost:5175` (Alternative)
- `https://cinema-hall-admin.vercel.app` (Production)

---

## Database Triggers & Functions

### Show Overlap Prevention

```sql
CREATE OR REPLACE FUNCTION prevent_overlapping_shows()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM shows
    WHERE screen_id = NEW.screen_id
      AND show_date = NEW.show_date
      AND (NEW.start_time, NEW.end_time) OVERLAPS (start_time, end_time)
      AND (id IS DISTINCT FROM NEW.id)
  ) THEN
    RAISE EXCEPTION 'Show overlaps with an existing show on the same screen.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_prevent_overlap
BEFORE INSERT OR UPDATE ON shows
FOR EACH ROW
EXECUTE FUNCTION prevent_overlapping_shows();
```

### Show Status Lifecycle

Shows follow a controlled lifecycle. Admin-triggered transitions are manual; time-based transitions are automatic.

```
scheduled → booking_started → in_progress → show_ended
                ↘                  ↘
              (revert)           cancelled (with refunds)
```

| Transition | Trigger | Condition |
|---|---|---|
| `scheduled` → `booking_started` | Admin (PUT `/booking-status/:id` `open`) | Manual |
| `booking_started` → `scheduled` | Admin (PUT `/booking-status/:id` `revert`) | No confirmed bookings |
| `booking_started` → `in_progress` | Auto (background job) | `show_date = today AND start_time <= now < end_time` |
| `in_progress` → `show_ended` | Auto (background job) | `show_date < today` OR `end_time <= now` |
| `booking_started` → `show_ended` | Auto (background job) | Missed in_progress window; end_time passed |
| `scheduled` → `show_ended` | Auto (background job) | Never opened for booking; end_time passed |
| Any → `cancelled` | Admin (PUT `/cancel/:id`) | Not already `cancelled` or `show_ended` |

### Show Status Auto-Update (Background Job)

Show statuses transition automatically via a `setInterval` job in `server.js` (runs every 60 seconds):

Times are compared in **IST (`Asia/Kolkata`)** since show times are stored in local time.

```javascript
// server.js
setInterval(async () => {
  await updateShowStatuses();
}, 60000);
```

> **Production note:** `setInterval` only runs when `NODE_ENV !== 'production'`. For Vercel deployments, use Vercel Cron Jobs to call `GET /api/shows/update-statuses`.

### Auto-Update Timestamp

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_customers_updated_at
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
```

---

## API Testing

### Sample cURL Commands

**Admin Login:**

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@cinema.com","password":"password123"}' \
  --cookie-jar cookies.txt
```

**Get Movies:**

```bash
curl http://localhost:5000/api/movies?status=now_showing&genre=Action
```

**Create Show:**

```bash
curl -X POST http://localhost:5000/api/shows/create \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{
    "movie_id":"uuid",
    "screen_id":"uuid",
    "show_date":"2024-02-15",
    "start_time":"14:00:00",
    "end_time":"16:30:00"
  }'
```

---

## Performance Considerations

- **Connection Pooling**: PostgreSQL connection pool managed by `pg`
- **Indexing**: Primary keys (UUID), foreign keys, and unique constraints
- **Query Optimization**: JOIN queries for related data (admin + hall, shows + movies)
- **Pagination**: Implemented for movies listing
- **JSONB**: Efficient storage for flexible data (layouts, price overrides)---

## 💳 Payment Integration (Razorpay)

The application integrates with Razorpay for secure online payments. The payment flow follows industry best practices with order creation, signature verification, and webhook handling.

### Payment Flow

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant Backend
    participant Razorpay
    participant Database

    User->>Frontend: Select seats & click "Pay"
    Frontend->>Backend: POST /api/booking/hold (seats)
    Backend->>Database: Hold seats for 5 minutes
    Database-->>Backend: Seats held
    Backend-->>Frontend: Hold confirmation

    Frontend->>Backend: POST /api/payment/create-order
    Backend->>Database: Verify seats still held
    Backend->>Razorpay: Create Order (amount, receipt)
    Razorpay-->>Backend: Order ID + Key
    Backend->>Database: Store order in payment_orders table
    Backend-->>Frontend: Order details

    Frontend->>Razorpay: Open checkout modal
    User->>Razorpay: Enter payment details
    Razorpay-->>Frontend: Payment success (order_id, payment_id, signature)

    Frontend->>Backend: POST /api/payment/verify (signature)
    Backend->>Backend: Verify Razorpay signature
    Backend->>Database: BEGIN TRANSACTION
    Backend->>Database: Update seats to BOOKED
    Backend->>Database: Create booking record
    Backend->>Database: Update payment_orders status
    Backend->>Database: COMMIT
    Backend-->>Frontend: Payment verified ✅
    Frontend->>User: Show success page

    Note over Razorpay,Backend: Webhook (Backup)
    Razorpay->>Backend: POST /api/payment/webhook (payment.captured)
    Backend->>Backend: Verify webhook signature
    Backend->>Database: Confirm booking (if not already done)
```

### Database Tables

#### payment_orders

Tracks Razorpay orders before payment completion.

```sql
CREATE TABLE payment_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id VARCHAR(255) UNIQUE NOT NULL,      -- Razorpay order ID
  show_id UUID NOT NULL REFERENCES shows(id),
  customer_id UUID NOT NULL REFERENCES customers(id),
  seats JSONB NOT NULL,                        -- ["A1", "A2"]
  amount DECIMAL(10, 2) NOT NULL,
  convenience_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
  gst_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
  status VARCHAR(20) DEFAULT 'created',        -- created, paid, failed, expired
  payment_id VARCHAR(255),                     -- Filled after payment
  payment_signature VARCHAR(500),
  offer_code VARCHAR(50),
  discount_amount NUMERIC(10, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### bookings

Final confirmed bookings after successful payment.

```sql
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES customers(id),
  show_id UUID NOT NULL REFERENCES shows(id),
  seats TEXT[] NOT NULL,                      -- seat IDs e.g. {"0-0", "1-1"}
  total_amount DECIMAL(10, 2) NOT NULL,       -- seat subtotal + convenience + GST - discount
  convenience_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
  gst_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
  payment_status VARCHAR(20) DEFAULT 'pending',
  payment_id VARCHAR(255),                    -- Razorpay payment ID
  booking_status VARCHAR(20) DEFAULT 'confirmed',
  offer_code VARCHAR(50),
  discount_amount NUMERIC(10, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### API Endpoints

#### 1. Create Payment Order

**POST** `/api/payment/create-order`

Creates a Razorpay order before initiating payment. **Amount is calculated server-side** — the frontend does not send an amount.

**Auth**: Customer required

**Request Body**:

```json
{
  "show_id": "550e8400-e29b-41d4-a716-446655440000",
  "seats": ["seatId1", "seatId2", "seatId3"]
}
```

**Server-Side Amount Calculation**:

1. Fetches `shows.price_override` and `screens.layout` (seats + pricing) from DB
2. Resolves per-seat price (price_override takes priority over layout.pricing)
3. Fetches `convenience_fee_per_ticket` and `gst_percentage` from `settings` table
4. Calculates:
   - `seatTotal = sum of per-seat prices`
   - `convenienceTotal = numSeats × convenience_fee_per_ticket`
   - `gstAmount = convenienceTotal × (gst_percentage / 100)`
   - `grandTotal = seatTotal + convenienceTotal + gstAmount`
5. Creates Razorpay order with `Math.round(grandTotal * 100)` paise
6. Stores `convenience_fee` and `gst_amount` in `payment_orders` for later retrieval during booking confirmation

**Response** (200 OK):

```json
{
  "order_id": "order_MlOhPxFJdD8SQy",
  "amount": 45270,
  "currency": "INR",
  "key_id": "rzp_test_XXXXXXXXXXXXX"
}
```

**Validations**:

- Seats must still be held by requesting customer
- Hold must not be expired (< 5 minutes old)

#### 2. Verify Payment

**POST** `/api/payment/verify`

Verifies Razorpay payment signature and confirms booking.

**Auth**: Customer required

**Request Body**:

```json
{
  "razorpay_order_id": "order_MlOhPxFJdD8SQy",
  "razorpay_payment_id": "pay_MlOhsFJKxD8SQz",
  "razorpay_signature": "abc123...xyz"
}
```

**Response** (200 OK):

```json
{
  "success": true,
  "message": "Payment verified and booking confirmed!",
  "booking": {
    "id": "booking-uuid",
    "show_id": "show-uuid",
    "customer_id": "customer-uuid",
    "seats": ["A1", "A2", "A3"],
    "total_amount": "450.00",
    "payment_status": "completed",
    "payment_id": "pay_MlOhsFJKxD8SQz",
    "booking_status": "confirmed",
    "created_at": "2026-01-29T15:30:00Z"
  }
}
```

**Process** (Atomic Transaction):

1. Verify Razorpay signature using HMAC-SHA256
2. BEGIN TRANSACTION
3. Update `show_booked_seats`: status='BOOKED', clear hold
4. Insert into `bookings` table
5. Update `payment_orders`: status='paid'
6. COMMIT

#### 3. Webhook Handler

**POST** `/api/payment/webhook`

Receives webhook events from Razorpay (backup confirmation).

**Auth**: Webhook signature verification

**Events Handled**:

- `payment.captured` - Payment successful
- `payment.failed` - Payment failed, release seats
- `order.paid` - Order fully paid (backup)

**Signature Verification**:

```javascript
const expectedSignature = crypto
  .createHmac("sha256", RAZORPAY_WEBHOOK_SECRET)
  .update(JSON.stringify(req.body))
  .digest("hex");

if (expectedSignature !== req.headers["x-razorpay-signature"]) {
  return res.status(400).json({ error: "Invalid signature" });
}
```

### Environment Variables

Add to `.env`:

```bash
# Razorpay Test Mode Keys (Get from: https://dashboard.razorpay.com/app/keys)
RAZORPAY_KEY_ID=rzp_test_XXXXXXXXXXXXX
RAZORPAY_KEY_SECRET=your_secret_key_here
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret_here
```

**How to Get Keys**:

1. Sign up at [Razorpay Dashboard](https://dashboard.razorpay.com)
2. Navigate to Settings → API Keys
3. Generate Test Mode keys
4. For webhooks: Settings → Webhooks → Add Webhook URL
5. Copy the webhook secret

### Frontend Integration

**1. Load Razorpay Script** (`index.html`):

```html
<script src="https://checkout.razorpay.com/v1/checkout.js"></script>
```

**2. Initialize Payment** (React hook):

```javascript
const initiatePayment = async ({ show_id, seats, amount, customer }) => {
  // Step 1: Create order
  const orderRes = await fetch("/api/payment/create-order", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    credentials: "include",
    body: JSON.stringify({ show_id, seats, amount }),
  });
  const order = await orderRes.json();

  // Step 2: Open Razorpay checkout
  const options = {
    key: order.key_id,
    amount: order.amount,
    currency: order.currency,
    order_id: order.order_id,
    name: "CineMax",
    description: "Movie Ticket Booking",
    prefill: {
      name: customer.name,
      email: customer.email,
      contact: customer.phone,
    },
    handler: async (response) => {
      // Step 3: Verify payment
      const verifyRes = await fetch("/api/payment/verify", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({
          razorpay_order_id: response.razorpay_order_id,
          razorpay_payment_id: response.razorpay_payment_id,
          razorpay_signature: response.razorpay_signature,
        }),
      });

      if (verifyRes.ok) {
        const data = await verifyRes.json();
        // Navigate to success page with payment_id as query param
        navigate(`/booking/success?payment_id=${data.booking.payment_id}`);
      }
    },
  };

  const razorpay = new window.Razorpay(options);
  razorpay.open();
};
```

### Security Features

✅ **Implemented**:

- **Signature Verification**: All payments verified using HMAC-SHA256
- **Webhook Security**: Signature verification for webhook events
- **Hold Timeout**: Seats auto-release after 5 minutes
- **Atomic Transactions**: Database ACID compliance
- **Receipt ID Validation**: Max 40 chars, format: `TKT-{timestamp}-{customer}`
- **HTTPS Only**: Razorpay requires TLS 1.2+
- **Server-Side Amount Calculation**: `createOrder` ignores any frontend-provided amount — recalculates from DB seat prices + settings, preventing price tampering

⚠️ **Important**:

- Never expose `RAZORPAY_KEY_SECRET` in frontend code
- Always use Test Mode keys during development
- Set up IP whitelisting for webhook endpoints in production
- Implement idempotency to prevent duplicate bookings
- Log all payment attempts for audit trails

### Test Payment Details

For testing in Test Mode:

**Test Cards**:

```
Card:  4111 1111 1111 1111
CVV:   123
Expiry: Any future date (e.g., 12/25)
Name:   Test User
```

**Test UPI**: `success@razorpay`

**Test Wallets**: All wallets work in test mode

### Error Handling

| Error                  | Cause                | Solution                           |
| ---------------------- | -------------------- | ---------------------------------- |
| Invalid signature      | Wrong webhook secret | Check `RAZORPAY_WEBHOOK_SECRET`    |
| Order not found        | Order ID mismatch    | Verify order creation succeeded    |
| Seats no longer held   | Hold expired         | Refresh and select seats again     |
| Receipt too long       | Receipt > 40 chars   | Fixed: `TKT-{time}-{customer}`     |
| payment_orders missing | Migration not run    | Run `migration_payment_tables.sql` |
| convenience_fee missing | Migration not run   | Run `migration_fee_columns.sql`    |
| settings missing       | Migration not run    | Run `migration_settings.sql`       |
| Duplicate booking      | Race condition       | Use database unique constraints    |

### Migration

Run these SQL migrations in order:

```bash
psql -U postgres -d cinema_hall -f migration_payment_tables.sql
psql -U postgres -d cinema_hall -f migration_fee_columns.sql
```

`migration_fee_columns.sql` adds `convenience_fee` and `gst_amount` columns to both `payment_orders` and `bookings`. Existing rows default to `0`.

### Monitoring & Logs

**Backend Logs**:

```bash
✅ Create order success: order_MlOhPxFJdD8SQy
✅ Payment verified: pay_MlOhsFJKxD8SQz
📥 Webhook received: payment.captured
✅ Webhook: Order order_MlOhPxFJdD8SQy confirmed
```

**Razorpay Dashboard**:

- View all orders and payments
- Track settlement status
- Monitor webhook delivery
- Download transaction reports

### Future Enhancements

- 🔄 Automatic refunds for cancelled bookings
- 📧 Email receipts after successful payment
- 📱 QR code generation for ticket verification
- 💰 Partial payments and split payments
- ~~🎫 Discount codes and promotional offers~~ ✅ Implemented (Offers system)
- 📊 Revenue analytics dashboard

---

## Security Best Practices

✅ **Implemented:**

- Password hashing with bcrypt
- JWT tokens in HttpOnly cookies
- CORS with whitelist
- SQL injection prevention (parameterized queries)
- Role-based access control
- Token expiration and refresh mechanism

⚠️ **Recommendations:**

- Add rate limiting (e.g., express-rate-limit)
- Implement request validation (e.g., Joi, Zod)
- Add API logging (e.g., Winston, Morgan)
- Set up monitoring (e.g., Sentry)
- Add input sanitization
- Implement CSRF protection for state-changing operations

---

**Last Updated**: March 29, 2026 — Show status lifecycle: new statuses `booking_started`, `in_progress`, `show_ended`; two new admin routes (`PUT /api/shows/booking-status/:id`, `PUT /api/shows/cancel/:id`); background job updated to use new transitions; user-facing showtime queries now filter `booking_started` only.
