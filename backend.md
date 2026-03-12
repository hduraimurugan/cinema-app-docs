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
        text title
        text description
        text poster_url
        text trailer_url
        int duration_mins
        text[] genre
        text[] language
        text status
        date release_date
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

    bookings {
        uuid id PK
        uuid customer_id FK
        uuid show_id FK
        text[] seats
        decimal total_amount
        varchar payment_status
        varchar payment_id
        varchar booking_status
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
        varchar status
        varchar payment_id
        varchar payment_signature
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
```

### Key Database Features

#### Constraints

- **Unique screen showtime**: Prevents double-booking same screen at same time
- **Show overlap prevention**: Trigger function prevents overlapping shows on same screen
- **Show status values**: `scheduled` | `running` | `cancelled` | `completed`

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
  "status": "upcoming"
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
  "created_at": "2024-01-29T10:00:00Z"
}
```

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

| Method | Endpoint        | Auth                 | Description                          |
| ------ | --------------- | -------------------- | ------------------------------------ |
| POST   | `/create`       | Admin + Screen Owner | Create single show                   |
| POST   | `/bulk`         | Admin + Screen Owner | Create multiple shows                |
| PUT    | `/edit/:id`     | Admin + Screen Owner | Edit show details                    |
| DELETE | `/delete/:id`   | Admin                | Delete show                          |
| GET    | `/date/:date`   | Admin                | Get shows by date (grouped by movie) |
| GET    | `/get/:id`      | None                 | Get show details with seat layout    |
| POST   | `/book/:showId` | None                 | Book seats for show                  |

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
  "page": 1
}
```

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
| `verifySuperAdmin`              | Verify SuperAdmin role        | Movie CRUD       |
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

### Show Status Auto-Update (Background Job)

Show statuses transition automatically via a `setInterval` job in `server.js` (runs every 60 seconds):

| Transition | Condition |
|---|---|
| `scheduled` → `running` | `show_date = today AND start_time <= now < end_time` |
| `scheduled`/`running` → `completed` | `show_date < today` OR `(show_date = today AND end_time <= now)` |

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
  status VARCHAR(20) DEFAULT 'created',        -- created, paid, failed, expired
  payment_id VARCHAR(255),                     -- Filled after payment
  payment_signature VARCHAR(500),
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
  seats TEXT[] NOT NULL,                      -- {"A1", "A2"}
  total_amount DECIMAL(10, 2) NOT NULL,
  payment_status VARCHAR(20) DEFAULT 'pending',
  payment_id VARCHAR(255),                    -- Razorpay payment ID
  booking_status VARCHAR(20) DEFAULT 'confirmed',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### API Endpoints

#### 1. Create Payment Order

**POST** `/api/payment/create-order`

Creates a Razorpay order before initiating payment.

**Auth**: Customer required

**Request Body**:

```json
{
  "show_id": "550e8400-e29b-41d4-a716-446655440000",
  "seats": ["A1", "A2", "A3"],
  "amount": 450
}
```

**Response** (200 OK):

```json
{
  "order_id": "order_MlOhPxFJdD8SQy",
  "amount": 45000,
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
| Duplicate booking      | Race condition       | Use database unique constraints    |

### Migration

Run this SQL to create payment tables:

```bash
psql -U postgres -d cinema_hall -f migration_payment_tables.sql
```

Or manually:

```sql
-- See migration_payment_tables.sql for full schema
CREATE TABLE IF NOT EXISTS payment_orders (...);
CREATE TABLE IF NOT EXISTS bookings (...);
```

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
- 🎫 Discount codes and promotional offers
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

**Last Updated**: March 7, 2026
