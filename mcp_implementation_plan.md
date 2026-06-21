# Cinemax MCP Server — Implementation Plan

> **Blueprint for a production-grade MCP server serving the Cinemax cinema booking platform.**
> Covers architecture, tool design, security, roadmap, and full implementation scaffold.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Technology Stack](#2-technology-stack)
3. [Folder Structure](#3-folder-structure)
4. [Phase 1 Tool Catalog](#4-phase-1-tool-catalog)
5. [Backend Integration Strategy](#5-backend-integration-strategy)
6. [Security Architecture](#6-security-architecture)
7. [Phase-wise Roadmap](#7-phase-wise-roadmap)
8. [Initial Implementation](#8-initial-implementation)
9. [Client Configuration](#9-client-configuration)
10. [Future AI Capabilities](#10-future-ai-capabilities)

---

## 1. Architecture Overview

### Context

The Cinemax backend is **Express 5 + PostgreSQL (Neon)** — not MongoDB. Key characteristics:

| Aspect | Detail |
|---|---|
| Runtime | Node.js 20+ ESM (`"type": "module"`) |
| Database | PostgreSQL via Neon, `pg` Pool (max 10) |
| Auth | JWT in HttpOnly cookies: `accessToken` (admin), `cusAccessToken` (customer) |
| Roles | `admin` / `superAdmin` (in `cinema_admin_user.role`) |
| Multi-hall | `X-Hall-Id` header + `requireActiveHall` middleware → `req.currentHallId` |
| Hall isolation | Admin routes use `verifyCinemaAdminAccessToken` + `requireActiveHall` (new) or `verifyCinemaHall` (legacy) |
| Monitoring | Sentry (`@sentry/node`) + Winston logging |
| Payments | Razorpay (order creation, signature verification, webhooks) |
| Deployment | Vercel (serverless) |

### High-Level Architecture

```mermaid
flowchart LR
    subgraph Clients["MCP Clients"]
        CD[Claude Desktop]
        CC[Claude Code / OpenCode]
        CUR[Cursor / Cline / Roo]
        GPT[ChatGPT / OpenAI Agents]
    end
    subgraph Server["cinemax-mcp-server (Node.js 20, ESM)"]
        TIO[stdio Transport]
        HTTP[Streamable HTTP Transport]
        AUTH[Auth: API key → scope]
        REG[Tool Registry]
        VAL[zod validation]
        RL[Rate Limiter]
        DB[Read-Only PG Client (RLS)]
        API[API Client<br/>service bearer + X-Hall-Id]
        LOG[pino + Sentry]
    end
    subgraph Backend["Cinemax Backend"]
        EX[Express 5 API]
        PG[(PostgreSQL Neon)]
    end
    CD --> TIO
    CC --> TIO
    CUR --> TIO
    GPT --> HTTP
    TIO --> AUTH
    HTTP --> AUTH
    AUTH --> RL
    RL --> VAL
    VAL --> REG
    REG --> DB
    REG --> API
    DB --> PG
    API --> EX
```

### Component Architecture

```mermaid
graph TD
    subgraph Transports
        T1[StdioServerTransport]
        T2[StreamableHTTPServerTransport]
    end
    subgraph Core
        S[McpServer<br/>@modelcontextprotocol/sdk]
        R[Registry<br/>tools/index.js]
    end
    subgraph Cross-Cutting
        A[auth/scopeResolver.js]
        V[validation/schemas.js]
        L[RateLimit: token-bucket]
        O[Logger: pino + optional Sentry]
    end
    subgraph Data Access
        D[db/readonly.js: pg Pool + query allowlist]
        C[api/client.js: axios + bearer + X-Hall-Id]
    end
    subgraph Tools
        TC[cinema.tools.js]
        TM[movie.tools.js]
        TS[show.tools.js]
        TB[booking.tools.js]
        TU[user.tools.js]
        TA[analytics.tools.js]
        TP[platform.tools.js]
    end
    T1 --> S ; T2 --> S
    S --> R
    R --> TC & TM & TS & TB & TU & TA & TP
    TC & TM & TS & TB & TU & TA & TP --> A & V & L & D & C
```

### Data Flow (single tool call)

```mermaid
sequenceDiagram
    participant C as MCP Client
    participant T as Transport
    participant S as McpServer
    participant A as Scope Resolver
    participant V as zod
    participant H as Tool Handler
    participant D as Read-Only DB

    C->>T: tools/call {name, args}
    T->>A: resolve(apiKey/headers)
    A-->>H: scope = {role, hall_ids[]}
    H->>V: validate(args)
    V-->>H: typed args
    H->>D: parameterized SQL + scope.hall_ids
    D-->>H: rows
    H-->>S: {content: [{type: "text", text: JSON.stringify(result)}]}
    S-->>C: result
```

### Security Architecture

```mermaid
flowchart TD
    K[Client API Key] --> SR[Scope Resolver]
    SR --> SC[Scope: role + hall_ids + rate_tier]
    SC --> PG[Permission Gate]
    PG -->|admin| T[Admin-scoped tools]
    PG -->|superAdmin| SA[All tools incl. customer/admin lists]
    T --> QG[Query with hall_ids filter]
    SA --> QG2[Query with optional hall filter]
    QG --> DB[(PG: cinemax_reader role)]
    DB --> RLS[Row-Level Security]
    RLS -->|hall_id IN current_hall_ids| Rows
    RLS -->|mismatch| Empty
```

---

## 2. Technology Stack

| Concern | Choice | Rationale |
|---|---|---|
| Runtime | Node.js 20+ ESM | Matches backend `"type": "module"`; native `fetch` available |
| MCP SDK | `@modelcontextprotocol/sdk` ^1.2.0 | Official; supports stdio + Streamable HTTP; consumes zod schemas natively |
| Validation | `zod` ^3.23 | MCP SDK integrates zod for auto-generated tool input schemas |
| DB Driver | `pg` ^8.16 | Same library as backend; prepared statements; connection pooling |
| HTTP Client | `axios` ^1.7 | Matches backend's frontend API services |
| Logging | `pino` ^9.5 | Structured JSON; ~3x faster than Winston; good for long-lived process |
| Config | `dotenv` + zod env schema | Typed configuration; fails fast on missing env vars |
| Rate Limiting | In-memory token bucket (stdio); Redis (`ioredis`) for HTTP | Per-tool, per-scope limits; burst protection for analytics queries |
| Errors | Sentry (optional) | Matches backend's error monitoring |
| Tests | `vitest` ^4 | Matches backend's test runner |

---

## 3. Folder Structure

```
cinemax-mcp-server/
├── package.json
├── .env.example
├── README.md
├── src/
│   ├── server.js                      # Entry point: McpServer + transport selector
│   │
│   ├── transports/
│   │   ├── stdio.js                   # StdioServerTransport bootstrap
│   │   └── http.js                    # Express + StreamableHTTPServerTransport
│   │
│   ├── config/
│   │   ├── index.js                   # Typed env config via zod
│   │   └── scope-map.js               # API key → {role, hall_ids[]} loader
│   │
│   ├── auth/
│   │   ├── scopeResolver.js           # key/header → scope object
│   │   └── permissions.js             # Permission gate: tool → required role
│   │
│   ├── db/
│   │   └── readonly.js                # pg Pool (cinemax_reader role) + query functions
│   │
│   ├── api/
│   │   └── client.js                  # axios client (bearer token + X-Hall-Id)
│   │
│   ├── registry/
│   │   └── index.js                   # Aggregates all tools, registers on McpServer
│   │
│   ├── tools/
│   │   ├── cinema.tools.js            # Tools 1–4: cinemas and screens
│   │   ├── movie.tools.js             # Tools 5–9: movie catalog + performance
│   │   ├── show.tools.js              # Tools 10–13: shows and occupancy
│   │   ├── booking.tools.js           # Tools 14–17: bookings and summary
│   │   ├── user.tools.js              # Tools 18–20: customers (superAdmin)
│   │   ├── analytics.tools.js         # Tools 21–28: collections, occupancy, revenue
│   │   └── platform.tools.js          # Tools 29–36: dashboard, refunds, offers, etc.
│   │
│   ├── validation/
│   │   └── schemas.js                 # Shared zod: uuid, date, pagination, filters
│   │
│   ├── errors/
│   │   └── index.js                   # McpError → safe response; never leaks internals
│   │
│   ├── ratelimit/
│   │   └── tokenBucket.js             # Per-scope + per-tool token bucket
│   │
│   ├── logging/
│   │   └── logger.js                  # pino instance + Sentry transport
│   │
│   └── util/
│       ├── pagination.js              # Pagination helpers
│       └── date.js                    # Date range utilities
│
├── sql/
│   ├── 01_readonly_role.sql           # CREATE ROLE cinemax_reader + GRANT SELECT
│   └── 02_rls_policies.sql            # Per-table RLS policies for hall isolation
│
├── tests/
│   ├── tools/
│   │   ├── cinema.tools.test.js
│   │   ├── booking.tools.test.js
│   │   └── analytics.tools.test.js
│   └── helpers/
│       └── mockScope.js
│
└── examples/
    ├── claude_desktop_config.json
    └── .env.example
```

---

## 4. Phase 1 Tool Catalog

All 36 tools are **read-only**. Tools are grouped by domain. Each entry lists:
- **Name** — the MCP tool name
- **Description** — shown to the AI model
- **Input schema** — zod shape
- **Output schema** — JSON shape returned
- **Access** — who can call it
- **Source** — DB (direct SQL) or API (REST endpoint)

### 4.1 Cinema Tools (1–4)

#### `list_cinemas`
- **Description:** List cinema halls. Admins see only their own halls; SuperAdmins see all active halls.
- **Input:** `{ active?: boolean }` — filter by active status
- **Output:** `{ cinemas: T[] }` — `{ id, name, location, district, state, phone, is_active, screens_count, created_at }`
- **Access:** any authenticated scope
- **Source:** DB

#### `get_cinema`
- **Description:** Get a single cinema hall by ID, including screen count and current show count.
- **Input:** `{ cinema_hall_id: uuid }`
- **Output:** `{ cinema: { id, name, location, district, state, phone, description, is_active, latitude, longitude, screens_count, shows_today, created_at } }`
- **Access:** any (hall-scoped; admins can only see their own)
- **Source:** DB

#### `get_cinema_stats`
- **Description:** Key performance indicators for a cinema hall over a date range: bookings, revenue, fees, screen occupancy, top movies.
- **Input:** `{ cinema_hall_id: uuid, from_date?: date, to_date?: date }` (defaults: past 30 days)
- **Output:** `{ cinema_hall_id, range: {from, to}, bookings, revenue, convenience_fee, gst, occupancy_pct, screens_count, shows_count, top_movies: [{movie_id, title, bookings, revenue}] }`
- **Access:** any (hall-scoped)
- **Source:** DB

#### `list_cinema_screens`
- **Description:** List all screens in a cinema hall with seat configuration and pricing.
- **Input:** `{ cinema_hall_id: uuid }`
- **Output:** `{ screens: [{ id, name, total_seats, premium_seats, gold_seats, silver_seats, premium_price, gold_price, silver_price, rows, columns }] }`
- **Access:** any (hall-scoped)
- **Source:** DB

### 4.2 Movie Tools (5–9)

#### `list_movies`
- **Description:** Search and filter the movie catalog. Supports genre/language/status filters and full-text search.
- **Input:** `{ status?: "upcoming"|"now_showing"|"ended", genre?: string[], language?: string[], search?: string, page?: number, limit?: number }`
- **Output:** `{ movies: T[], page, limit, total }` — `{ id, title, poster_url, genre, language, status, release_date, duration_mins, vote_average }`
- **Access:** any
- **Source:** API (`GET /api/movies`)

#### `get_movie`
- **Description:** Full movie details including description, cast, trailer URL, and TMDB metadata.
- **Input:** `{ movie_id: uuid }`
- **Output:** `{ movie: { id, tmdb_id, title, description, poster_url, backdrop_path, trailer_url, duration_mins, genre, language, status, release_date, cast, vote_average, vote_count } }`
- **Access:** any
- **Source:** API (`GET /api/movies/:id`)

#### `list_now_showing_movies`
- **Description:** Convenience tool — movies currently showing in theatres.
- **Input:** `{ page?: number, limit?: number }`
- **Output:** same as `list_movies` with `status="now_showing"` filter
- **Access:** any
- **Source:** API

#### `list_upcoming_movies`
- **Description:** Convenience tool — movies coming soon.
- **Input:** `{ page?: number, limit?: number }`
- **Output:** same as `list_movies` with `status="upcoming"` filter
- **Access:** any
- **Source:** API

#### `get_movie_stats`
- **Description:** Bookings and revenue statistics for a specific movie in a cinema hall (or platform-wide for superAdmin).
- **Input:** `{ movie_id: uuid, cinema_hall_id?: uuid, from_date?: date, to_date?: date }`
- **Output:** `{ movie_id, title, bookings, revenue, avg_occupancy, shows_count, avg_ticket_price, genre_rank }`
- **Access:** any (hall-scoped if `cinema_hall_id` provided)
- **Source:** DB

### 4.3 Show Tools (10–13)

#### `list_shows_by_date`
- **Description:** Shows scheduled for a specific date, grouped by movie.
- **Input:** `{ cinema_hall_id: uuid, date: date }`
- **Output:** `{ date, movies: [{ movie_id, title, poster_url, shows: [{ show_id, screen_name, start_time, end_time, language_version, show_status, pricing }] }] }`
- **Access:** any (hall-scoped)
- **Source:** API (`GET /api/shows/date/:date`)

#### `get_show`
- **Description:** Full show details with screen layout and seat availability summary.
- **Input:** `{ show_id: uuid }`
- **Output:** `{ show: { id, movie_title, screen_name, show_date, start_time, end_time, status, language_version, pricing, seat_layout: { total, premium, gold, silver, booked }, seat_map } }`
- **Access:** any
- **Source:** API (`GET /api/shows/get/:id`) + DB for occupancy

#### `get_show_occupancy`
- **Description:** Seat occupancy breakdown for a show: booked vs available by seat category.
- **Input:** `{ show_id: uuid }`
- **Output:** `{ show_id, total_seats, booked_seats, available_seats, occupancy_pct, by_category: { premium: {total, booked, pct}, gold: {...}, silver: {...} } }`
- **Access:** any
- **Source:** DB (`show_booked_seats` + `screens.layout`)

#### `get_show_booking_count`
- **Description:** Confirmed booking count and total refund amount for a show. Useful for admin cancel-warnings.
- **Input:** `{ show_id: uuid }`
- **Output:** `{ show_id, booking_count, total_amount }`
- **Access:** any (hall-scoped)
- **Source:** API (`GET /api/shows/booking-count/:id`)

### 4.4 Booking Tools (14–17)

#### `get_booking`
- **Description:** Fetch a single booking by UUID with full details (scoped to the admin's cinema hall).
- **Input:** `{ booking_id: uuid }`
- **Output:** `{ booking: { id, booking_status, payment_status, total_amount, convenience_fee, gst_amount, movie_title, show_date, start_time, end_time, screen_name, cinema_hall_name, customer_name, customer_email, seat_labels, seats, offer_code, discount_amount, refund_status, created_at } }`
- **Access:** any (hall-scoped via `GET /api/booking/admin/verify/:id`)
- **Source:** API

#### `list_bookings`
- **Description:** List bookings for a cinema hall with filters and pagination.
- **Input:** `{ cinema_hall_id: uuid, from_date?: date, to_date?: date, status?: "confirmed"|"cancelled", screen_id?: uuid, search?: string, page?: number, limit?: number }`
- **Output:** `{ bookings: T[], total, page, stats: { total_revenue, total_convenience_fee, total_gst } }`
- **Access:** any (hall-scoped)
- **Source:** API (`GET /api/booking/admin/all`)

#### `get_booking_summary`
- **Description:** Aggregate booking statistics for a cinema hall over a date range.
- **Input:** `{ cinema_hall_id: uuid, from_date?: date, to_date?: date }`
- **Output:** `{ total_bookings, confirmed_bookings, cancelled_bookings, total_revenue, total_convenience_fee, total_gst, avg_ticket_price, by_status: {confirmed, cancelled} }`
- **Access:** any (hall-scoped)
- **Source:** DB

#### `get_bookings_by_date`
- **Description:** Booking count and revenue grouped by individual dates in a range.
- **Input:** `{ cinema_hall_id: uuid, from_date?: date, to_date?: date }`
- **Output:** `{ series: [{ date, bookings_count, revenue, convenience_fee, gst }] }`
- **Access:** any (hall-scoped)
- **Source:** DB

### 4.5 User Tools (18–20) — SuperAdmin only

#### `list_customers`
- **Description:** Platform-wide customer list with search and stats. SuperAdmin only.
- **Input:** `{ search?: string, page?: number, limit?: number }`
- **Output:** `{ customers: T[], total, stats: { total, verified } }` — `{ id, name, email, phone, district, state, is_verified, created_at, booking_count, auth_providers }`
- **Access:** superAdmin
- **Source:** API (`GET /api/customers`)

#### `get_customer`
- **Description:** Full customer details including recent bookings and active sessions.
- **Input:** `{ customer_id: uuid }`
- **Output:** `{ customer: { id, name, email, phone, district, state, is_verified, failed_login_attempts, last_login_at, created_at, auth_providers, has_password }, recent_bookings: T[], active_sessions: T[] }`
- **Access:** superAdmin
- **Source:** API (`GET /api/customers/:id`)

#### `get_customer_booking_history`
- **Description:** All confirmed bookings for a specific customer.
- **Input:** `{ customer_id: uuid, page?: number, limit?: number }`
- **Output:** `{ bookings: T[], total }` — `{ id, movie_title, show_date, start_time, screen_name, cinema_hall_name, total_amount, booking_status, seat_labels, created_at }`
- **Access:** superAdmin
- **Source:** DB

### 4.6 Analytics Tools (21–28)

#### `get_daily_collections`
- **Description:** Daily revenue, bookings, and fees for a hall over a date range.
- **Input:** `{ cinema_hall_id: uuid, from_date?: date, to_date?: date }`
- **Output:** `{ series: [{ date, revenue, convenience_fee, gst, bookings_count }] }`
- **Source:** DB (generate_series LEFT JOIN bookings)

#### `get_weekly_collections`
- **Description:** Weekly aggregated collections. Groups by ISO week.
- **Input:** `{ cinema_hall_id: uuid, from_date?: date, to_date?: date }`
- **Output:** `{ series: [{ week_start, week_end, label, revenue, bookings_count }] }`
- **Source:** DB

#### `get_monthly_collections`
- **Description:** Monthly aggregated collections grouped by year-month.
- **Input:** `{ cinema_hall_id: uuid, year?: number, months?: number }` (defaults: current year)
- **Output:** `{ series: [{ month, year, revenue, bookings_count, convenience_fee }] }`
- **Source:** DB

#### `get_hall_occupancy`
- **Description:** Per-show seat occupancy for a hall on a specific date or date range.
- **Input:** `{ cinema_hall_id: uuid, date?: date, from_date?: date, to_date?: date }`
- **Output:** `{ shows: [{ show_id, movie_title, screen_name, start_time, end_time, total_seats, booked_seats, occupancy_pct, status }] }`
- **Source:** DB

#### `get_seat_utilization`
- **Description:** Overall seat utilization % for a hall over a period. The percentage of all available seats that were booked across all shows.
- **Input:** `{ cinema_hall_id: uuid, from_date?: date, to_date?: date }`
- **Output:** `{ utilization_pct, total_seat_capacity, total_booked_seats, total_shows, total_screens, by_screen: [{ screen_name, utilization_pct }] }`
- **Source:** DB

#### `get_revenue_report`
- **Description:** Comprehensive revenue breakdown. Can be grouped by movie, screen, or seat category.
- **Input:** `{ cinema_hall_id: uuid, from_date?: date, to_date?: date, group_by?: "movie"|"screen"|"category" }`
- **Output:** varies by `group_by`. Default: `{ total_revenue, by_movie: [...], by_screen: [...], by_category: { premium, gold, silver } }`
- **Source:** DB

#### `get_movie_performance`
- **Description:** Per-movie metrics across all shows in a hall: bookings, revenue, occupancy, average ticket price.
- **Input:** `{ cinema_hall_id: uuid, from_date?: date, to_date?: date }`
- **Output:** `{ movies: [{ movie_id, title, poster_url, genre, shows_count, bookings, revenue, avg_occupancy_pct, avg_ticket_price }] }`
- **Source:** DB

#### `get_show_performance`
- **Description:** Per-show performance metrics: occupancy, revenue, ticket mix.
- **Input:** `{ cinema_hall_id: uuid, from_date?: date, to_date?: date }`
- **Output:** `{ shows: [{ show_id, movie_title, screen_name, date, start_time, total_revenue, bookings_count, occupancy_pct, premium_booked, gold_booked, silver_booked }] }`
- **Source:** DB

### 4.7 Platform Tools (29–36)

#### `get_dashboard_stats`
- **Description:** All dashboard metrics in one call: today's stats, 7-day trend, recent bookings, today's shows with occupancy.
- **Input:** `{ cinema_hall_id: uuid }`
- **Output:** mirrors `GET /api/dashboard/stats`: `{ today, allTime, customers, activeOffers, screens, revenueTrend, recentBookings, todayShows }`
- **Access:** any (hall-scoped)
- **Source:** API (`GET /api/dashboard/stats`)

#### `list_payment_orders`
- **Description:** Payment orders for a cinema hall with filters and pagination.
- **Input:** `{ cinema_hall_id: uuid, from_date?: date, to_date?: date, status?: "created"|"paid"|"failed"|"expired", search?: string, page?: number, limit?: number }`
- **Output:** `{ orders: T[], total, page }` — includes customer, movie, screen joined data
- **Access:** any (hall-scoped)
- **Source:** API (`GET /api/payment/admin/orders`)

#### `list_refunds`
- **Description:** Refund records for a cinema hall, filterable by status and paginated.
- **Input:** `{ cinema_hall_id: uuid, status?: "initiated"|"processed"|"failed", from_date?: date, to_date?: date, page?: number, limit?: number }`
- **Output:** `{ refunds: T[], total, page }`
- **Access:** any (hall-scoped)
- **Source:** API (`GET /api/refunds`)

#### `list_offers`
- **Description:** All offers/coupons with filters. SuperAdmin only.
- **Input:** `{ scope?: "global"|"hall", is_active?: boolean, search?: string, page?: number, limit?: number }`
- **Output:** `{ offers: T[], total, page }`
- **Access:** superAdmin
- **Source:** API (`GET /api/offers`)

#### `list_active_ads`
- **Description:** Currently active advertisements by placement. Public data.
- **Input:** `{ placement?: "banner"|"side" }`
- **Output:** `{ ads: [{ id, title, image_url, click_url, placement }] }`
- **Access:** any
- **Source:** API (`GET /api/ads/active`)

#### `get_settings`
- **Description:** System-wide fee configuration.
- **Input:** none
- **Output:** `{ convenience_fee_per_ticket: number, gst_percentage: number }`
- **Access:** any
- **Source:** API (`GET /api/settings`)

#### `list_admins`
- **Description:** All cinema hall admins with their hall details. SuperAdmin only.
- **Input:** `{ search?: string, page?: number, limit?: number }`
- **Output:** `{ admins: T[], total }` — `{ id, name, email, phone, email_verified, last_login_at, created_at, halls: [{ id, name, location, district, state }] }`
- **Access:** superAdmin
- **Source:** API (`GET /api/auth/admins`)

#### `get_admin_audit_logs`
- **Description:** Security audit logs for a specific cinema admin. SuperAdmin only.
- **Input:** `{ admin_id: uuid }`
- **Output:** `{ admin: {...}, logs: [{ action, ip_address, user_agent, metadata, created_at }] }`
- **Access:** superAdmin
- **Source:** API (`GET /api/auth/admins/:id/logs`)

---

## 5. Backend Integration Strategy

### 5.1 Two Access Paths

**DB path (direct, for analytics):**
- PostgreSQL role `cinemax_reader` with `SELECT`-only on approved tables
- Row-Level Security (RLS) enforces `cinema_hall_id` scoping
- Used for: analytics tools, aggregate stats, custom queries

**API path (REST proxy, for existing endpoints):**
- Phase 1: public endpoints only (no auth needed: `/api/movies`, `/api/settings`, `/api/ads/active`)
- Phase 3+: service-account bearer token + `X-Hall-Id` header for all hall-scoped endpoints
- Used for: movie catalog, dashboard stats, booking admin endpoints

### 5.2 Trade-offs: DB Read vs API Proxy

| Dimension | DB Read-Only + RLS | API Proxy (service account) |
|---|---|---|
| Speed to Phase 1 | ✅ Zero backend changes | ❌ Needs `verifyServiceAccount` middleware |
| Query flexibility | ✅ Arbitrary analytics SQL | ❌ Limited to endpoint shapes |
| Performance | ✅ 1 hop (DB) | ❌ 2 hops (API → DB) |
| RBAC reuse | ❌ Must replicate via RLS | ✅ Reuses `requireActiveHall`, `verifySuperAdmin` |
| Business logic reuse | ❌ Bypasses validation | ✅ Full validation chain |
| Schema coupling | ⚠️ Schema changes break MCP | ✅ Stable API contract |
| Mutation support | ❌ Not suitable | ✅ Natural for Phase 3+ |
| Multi-tenant scale | ✅ RLS scales linearly | ✅ Stateless API scales |

### 5.3 Recommended Hybrid Approach

**Phase 1:** DB-read for analytics, public API for catalog. RLS + read-only role. **No backend changes.**

**Phase 2:** Materialized views for heavy analytics queries. Redis cache for frequently-accessed dashboard data.

**Phase 3+:** Add `verifyServiceAccount` middleware to the backend. Migrate hall-scoped reads and all mutations to the API path. Keep DB-read for complex OLAP analytics where the API shape is insufficient.

**Why hybrid wins:** Phase 1 ships this week. The migration to API is incremental — each tool swaps its `db/readonly.js` call for an `api/client.js` call with zero client-facing changes and zero schema coupling.

### 5.4 Read-Only Role SQL

```sql
-- sql/01_readonly_role.sql
CREATE ROLE cinemax_reader WITH LOGIN PASSWORD :'reader_password' NOBYPASSRLS;
GRANT USAGE ON SCHEMA public TO cinemax_reader;

-- Tables accessible to MCP
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cinemax_reader;

-- Revoke sensitive tables (no tokens, no passwords, no raw OTPs)
REVOKE SELECT ON admin_sessions FROM cinemax_reader;
REVOKE SELECT ON customer_sessions FROM cinemax_reader;
REVOKE SELECT ON admin_verification_tokens FROM cinemax_reader;
REVOKE SELECT ON admin_password_reset_tokens FROM cinemax_reader;
REVOKE SELECT ON otp_verifications FROM cinemax_reader;
REVOKE SELECT ON webhook_events FROM cinemax_reader;

-- Revoke sensitive columns on remaining tables
REVOKE SELECT (password) ON cinema_admin_user FROM cinemax_reader;
REVOKE SELECT (password) ON customers FROM cinemax_reader;
```

### 5.5 Row-Level Security Policies

```sql
-- sql/02_rls_policies.sql

-- cinema_hall: admins see only their halls; superAdmin sees all
ALTER TABLE cinema_hall ENABLE ROW LEVEL SECURITY;
CREATE POLICY cinema_hall_admin_scope ON cinema_hall
  FOR SELECT TO cinemax_reader
  USING (
    current_setting('app.scope_role', true) = 'superAdmin'
    OR id = ANY(string_to_array(current_setting('app.current_hall_ids', true), ',')::uuid[])
  );

-- screens: scoped by cinema_hall
ALTER TABLE screens ENABLE ROW LEVEL SECURITY;
CREATE POLICY screens_hall_scope ON screens
  FOR SELECT TO cinemax_reader
  USING (
    cinema_hall_id = ANY(string_to_array(current_setting('app.current_hall_ids', true), ',')::uuid[])
  );

-- shows: scoped via screens → cinema_hall
ALTER TABLE shows ENABLE ROW LEVEL SECURITY;
CREATE POLICY shows_hall_scope ON shows
  FOR SELECT TO cinemax_reader
  USING (
    screen_id IN (SELECT id FROM screens WHERE cinema_hall_id = ANY(
      string_to_array(current_setting('app.current_hall_ids', true), ',')::uuid[]
    ))
  );

-- bookings: scoped via shows → screens → cinema_hall
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
CREATE POLICY bookings_hall_scope ON bookings
  FOR SELECT TO cinemax_reader
  USING (
    show_id IN (SELECT s.id FROM shows s JOIN screens sc ON sc.id = s.screen_id
      WHERE sc.cinema_hall_id = ANY(
        string_to_array(current_setting('app.current_hall_ids', true), ',')::uuid[]
      ))
  );

-- customers: only superAdmin can read
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY customers_superadmin_only ON customers
  FOR SELECT TO cinemax_reader
  USING (current_setting('app.scope_role', true) = 'superAdmin');
```

---

## 6. Security Architecture

### 6.1 Authentication Layers

```mermaid
flowchart LR
    subgraph Layer1["Layer 1: Client → MCP"]
        A1[API Key in env/x-api-key]
    end
    subgraph Layer2["Layer 2: MCP → DB"]
        A2[pg Pool + cinemax_reader role]
        A3[SET LOCAL session vars → RLS]
    end
    subgraph Layer3["Layer 3: MCP internal"]
        A4[Tool permission gate]
        A5[zod input validation]
        A6[Output size limits]
    end
    A1 --> A4 --> A5 --> A2 --> A3
```

### 6.2 API Key Model

**Key format:** `cmax_<32-byte-random-hex>` (e.g. `cmax_a1b2c3d4e5f6...`)

**Scope map (config/scope-map.js):**
```js
{
  "cmax_abc...": { scope_id: "admin-1", role: "admin", hall_ids: ["<uuid>"] },
  "cmax_def...": { scope_id: "super-1", role: "superAdmin", hall_ids: [] },  // empty = all
}
```

**Environment variable:**
```
CINEMAX_MCP_API_KEY=cmax_abc...
# OR for multiple keys:
MCP_API_KEYS="key1=admin:uuid1,uuid2;key2=superAdmin"
```

### 6.3 Permission Model

| Role | Can call | Cannot call |
|---|---|---|
| `admin` | Cinema 1–4, Movie 5–9, Show 10–13, Booking 14–17, Analytics 21–28, Dashboard 29, PaymentOrders 30, Refunds 31, Ads 33, Settings 34 | User tools 18–20, Offers 32, Admins 35, AuditLogs 36 |
| `superAdmin` | All 36 tools | — |

Enforced in the tool handler wrapper before any DB call:

```js
function checkPermission(requiredRole, scope) {
  if (requiredRole === "superAdmin" && scope.role !== "superAdmin") {
    throw Object.assign(new Error("FORBIDDEN"), { code: 403, expose: true });
  }
}
```

### 6.4 Prompt Injection Protections

1. **Non-bypassable permission gate** — tool descriptions can say anything; the gate checks `scope.role`, not tool description text
2. **Parameterized SQL** — all queries use `$1`, `$2` placeholders; no template-literals with user args
3. **Output size limits** — max 50 rows or 256 KB per tool response, with `truncated: true` flag
4. **No PII in non-superAdmin tools** — customer names/emails stripped from booking tools
5. **Dual-confirmation for all future mutations** (Phase 3+) — `prepare_X` returns nonce; `confirm_X` requires nonce + approval
6. **Audit trail** — every tool call logged with `{tool, scope_id, args_hash, rows, duration}`

### 6.5 Audit Logging

Every tool call produces a pino log:

```json
{
  "level": "info",
  "ts": "2026-06-21T10:30:00.000Z",
  "tool": "get_cinema_stats",
  "scope_id": "admin-1",
  "role": "admin",
  "hall_ids": ["<uuid>"],
  "args": {"cinema_hall_id": "<uuid>", "from_date": "2026-06-01"},
  "rows": 1,
  "duration_ms": 42,
  "status": "success",
  "correlationId": "cid_abc"
}
```

---

## 7. Phase-wise Roadmap

### Phase 1: Read-Only Tools (Current)

**Delivery:** Complete MCP server with 36 read-only tools.

**Includes:**
- [x] Architecture design and implementation plan
- [ ] Dual transport (stdio + Streamable HTTP)
- [ ] API-key auth → scope resolver
- [ ] Read-only PG pool (cinemax_reader role)
- [ ] RLS policies for hall isolation
- [ ] 36 tool implementations (cinema, movie, show, booking, user, analytics, platform)
- [ ] Error handling (safe responses, no leak)
- [ ] Rate limiting (in-memory token bucket)
- [ ] Structured logging (pino)
- [ ] Client configs for all 9 AI tools

### Phase 2: Analytics Deep-Dive

**Scope:** Advanced analytics, caching, materialized views.

- Cohort analysis (repeat customers, retention)
- Booking funnel (visit → hold → pay → confirm)
- Time-comparison reports (MoM, YoY)
- Redis cache for frequently-accessed stats (60s TTL)
- Neon materialized views for heavy aggregation queries
- CSV/table output format option
- Pagination for all list tools

### Phase 3: Admin Management (Write)

**Scope:** CRUD for halls, screens, shows, offers, ads.

Requires backend changes:
- New `verifyServiceAccount` middleware in the Express app
- Service bearer tokens with tool allowlists
- MCP mutations use `prepare_*` / `confirm_*` pattern with nonce

**Tools:** `create_cinema`, `update_cinema`, `create_screen`, `update_screen`, `create_show`, `bulk_create_shows`, `update_show_status`, `create_offer`, `update_offer`, `create_ad`, `update_ad`

### Phase 4: Booking Management (Write)

**Scope:** Seat holds, confirmations, cancellations, refunds.

- `hold_seats` — mirrors existing hold but via API
- `confirm_booking` — mirrors existing confirm
- `cancel_show` — full cancellation + refund initiation
- `process_refund` — manual refund settlement
- All mutating tools require `prepare_` + `confirm_` dual-call pattern

### Phase 5: AI-Powered Analytics & Recommendations

**Scope:** ML inference tools surfaced through MCP.

- Demand prediction (time-series model on historical bookings + TMDB popularity)
- Occupancy forecast per show (gradient boosting)
- Revenue forecasting (Prophet/ARIMA)
- Dynamic pricing recommendations (constrained optimization)

### Phase 6: Multi-Cinema BI Platform

**Scope:** Cross-cinema analytics, executive dashboards, benchmarking.

- Cross-cinema performance comparison
- Territory/regional analytics
- Customer cohort retention across halls
- Executive reports (auto-generated narratives)
- Embeddings-based movie discovery

---

## 8. Initial Implementation

### 8.1 `package.json`

```json
{
  "name": "cinemax-mcp-server",
  "version": "1.0.0",
  "type": "module",
  "description": "MCP server for Cinemax cinema booking platform",
  "bin": {
    "cinemax-mcp": "src/server.js"
  },
  "scripts": {
    "start": "node src/server.js",
    "start:http": "MCP_TRANSPORT=http node src/server.js",
    "dev": "node --watch src/server.js",
    "test": "vitest",
    "test:run": "vitest run"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.2.0",
    "axios": "^1.7.9",
    "dotenv": "^16.5.0",
    "ioredis": "^5.6.1",
    "pg": "^8.16.2",
    "pino": "^9.6.0",
    "zod": "^3.24.4"
  },
  "devDependencies": {
    "vitest": "^4.1.8"
  }
}
```

### 8.2 `src/server.js`

```js
import "dotenv/config";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { registerTools } from "./registry/index.js";
import { startStdio } from "./transports/stdio.js";
import { startHttp } from "./transports/http.js";
import logger from "./logging/logger.js";
import { env } from "./config/index.js";

logger.info("cinemax-mcp-server booting");

const server = new McpServer({
  name: "cinemax-mcp",
  version: "1.0.0",
  capabilities: { tools: {} },
});

registerTools(server);

const transport = env.MCP_TRANSPORT === "http" ? "http" : "stdio";
if (transport === "http") {
  await startHttp(server);
} else {
  await startStdio(server);
}

logger.info({ transport, node: process.version }, "cinemax-mcp-server ready");
```

### 8.3 `src/config/index.js`

```js
import { z } from "zod";

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  API_BASE_URL: z.string().url().default("http://localhost:5000"),
  MCP_TRANSPORT: z.enum(["stdio", "http"]).default("stdio"),
  HTTP_PORT: z.coerce.number().default(8787),
  MCP_API_KEYS: z.string().optional(),           // "key1=admin:uuid1,uuid2;key2=superAdmin"
  CINEMAX_MCP_API_KEY: z.string().optional(),    // Single-key mode (simpler)
  RATELIMIT_CAPACITY: z.coerce.number().default(30),
  RATELIMIT_REFILL_PER_SEC: z.coerce.number().default(2),
  SENTRY_DSN: z.string().optional(),
  REDIS_URL: z.string().optional(),
});

export const env = envSchema.parse(process.env);
```

### 8.4 `src/config/scope-map.js`

```js
export function loadScopeMap(raw) {
  const map = new Map();
  if (!raw) return map;
  for (const entry of raw.split(";")) {
    const [key, spec] = entry.split("=");
    if (!key || !spec) continue;
    const [role, ...hallParts] = spec.split(":");
    const hall_ids = hallParts.length ? hallParts.join(":").split(",").filter(Boolean) : [];
    map.set(key.trim(), { scope_id: `key-${key.slice(0, 8)}`, role, hall_ids });
  }
  return map;
}
```

### 8.5 `src/auth/scopeResolver.js`

```js
import { env } from "../config/index.js";
import { loadScopeMap } from "../config/scope-map.js";

const scopeMap = loadScopeMap(env.MCP_API_KEYS);

function missingKey(key) {
  const e = new Error("UNAUTHORIZED: Invalid or missing API key");
  e.code = 401;
  e.expose = true;
  throw e;
}

export function resolveScope(credentials = {}) {
  const key = credentials.apiKey || env.CINEMAX_MCP_API_KEY;
  if (!key) missingKey();

  if (scopeMap.size > 0) {
    const scope = scopeMap.get(key);
    if (!scope) missingKey(key);
    return scope;
  }

  // Single-key mode: treat as superAdmin
  return { scope_id: "default", role: "superAdmin", hall_ids: [] };
}
```

### 8.6 `src/auth/permissions.js`

```js
export function requirePermission(requiredRole, scope) {
  if (requiredRole === "superAdmin" && scope.role !== "superAdmin") {
    const e = new Error("FORBIDDEN: SuperAdmin access required");
    e.code = 403;
    e.expose = true;
    throw e;
  }
  // Admin can access all non-superAdmin-tagged tools
}
```

### 8.7 `src/db/readonly.js`

```js
import { Pool } from "pg";
import { env } from "../config/index.js";
import logger from "../logging/logger.js";

const pool = new Pool({
  connectionString: env.DATABASE_URL,
  max: 8,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 3000,
});

pool.on("error", (err) => {
  logger.error({ err: err.message }, "Read-only pool error");
});

/**
 * Execute a read-only query with RLS scoping.
 * Sets session vars for RLS policies before each query.
 */
export async function query(sql, params = [], scope = { hall_ids: [], role: "admin" }) {
  const client = await pool.connect();
  try {
    const hallIds = scope.hall_ids.length > 0 ? scope.hall_ids : [];  // superAdmin has []
    await client.query("SET LOCAL app.current_hall_ids = $1", [hallIds.join(",")]);
    await client.query("SET LOCAL app.scope_role = $1", [scope.role]);
    const result = await client.query(sql, params);
    return result.rows;
  } finally {
    client.release();
  }
}

// --- Query functions (allowlist -- no SQL from tool args) ---

export const listCinemas = (scope, onlyActive) =>
  query(
    `SELECT ch.*, (SELECT COUNT(*) FROM screens WHERE cinema_hall_id = ch.id) AS screens_count
     FROM cinema_hall ch
     WHERE ($1::bool IS NULL OR ch.is_active = $1)
     ORDER BY ch.name`,
    [onlyActive ?? null],
    scope,
  );

export const getCinema = (id, scope) =>
  query(
    `SELECT ch.*,
       (SELECT COUNT(*) FROM screens WHERE cinema_hall_id = ch.id) AS screens_count,
       (SELECT COUNT(*) FROM shows s JOIN screens sc ON sc.id = s.screen_id
        WHERE sc.cinema_hall_id = ch.id AND s.show_date = CURRENT_DATE) AS shows_today
     FROM cinema_hall ch WHERE ch.id = $1`,
    [id],
    scope,
  );

export const getCinemaStats = (hallId, fromDate, toDate, scope) =>
  query(
    `WITH stats AS (
       SELECT COUNT(b.id)::int AS bookings,
              COALESCE(SUM(b.total_amount), 0)::numeric(10,2) AS revenue,
              COALESCE(SUM(b.convenience_fee), 0)::numeric(10,2) AS convenience_fee,
              COALESCE(SUM(b.gst_amount), 0)::numeric(10,2) AS gst
       FROM bookings b
       JOIN shows sh ON sh.id = b.show_id
       JOIN screens sc ON sc.id = sh.screen_id
       WHERE sc.cinema_hall_id = $1 AND sh.show_date BETWEEN $2 AND $3
     ),
     top_movies AS (
       SELECT m.id AS movie_id, m.title,
              COUNT(b.id)::int AS bookings,
              COALESCE(SUM(b.total_amount), 0)::numeric(10,2) AS revenue
       FROM bookings b
       JOIN shows sh ON sh.id = b.show_id
       JOIN screens sc ON sc.id = sh.screen_id
       JOIN movies m ON m.id = sh.movie_id
       WHERE sc.cinema_hall_id = $1 AND sh.show_date BETWEEN $2 AND $3
       GROUP BY m.id, m.title
       ORDER BY revenue DESC
       LIMIT 5
     )
     SELECT (SELECT * FROM stats) AS stats,
            (SELECT json_agg(top_movies) FROM top_movies) AS top_movies`,
    [hallId, fromDate, toDate],
    scope,
  );

export const listScreens = (hallId, scope) =>
  query(
    `SELECT id, name, total_seats, premium_seats, gold_seats, silver_seats,
            premium_price, gold_price, silver_price, rows, columns, screen_position, created_at
     FROM screens WHERE cinema_hall_id = $1 ORDER BY name`,
    [hallId],
    scope,
  );

export const getMovieStats = (movieId, hallId, fromDate, toDate, scope) =>
  query(
    `SELECT m.id AS movie_id, m.title,
       COUNT(b.id)::int AS bookings,
       COALESCE(SUM(b.total_amount), 0)::numeric(10,2) AS revenue,
       COALESCE(AVG(occ.occupancy), 0)::numeric(5,2) AS avg_occupancy,
       COUNT(DISTINCT sh.id)::int AS shows_count
     FROM movies m
     JOIN shows sh ON sh.movie_id = m.id
     JOIN screens sc ON sc.id = sh.screen_id
     LEFT JOIN bookings b ON b.show_id = sh.id
     LEFT JOIN (
       SELECT sbs.show_id, COUNT(*) FILTER (WHERE sbs.status = 'BOOKED')::float / NULLIF(COUNT(*), 0) * 100 AS occupancy
       FROM show_booked_seats sbs GROUP BY sbs.show_id
     ) occ ON occ.show_id = sh.id
     WHERE m.id = $1 AND ($2::uuid IS NULL OR sc.cinema_hall_id = $2)
       AND sh.show_date BETWEEN $3 AND $4
     GROUP BY m.id, m.title`,
    [movieId, hallId ?? null, fromDate, toDate],
    scope,
  );

export const getShowOccupancy = (showId, scope) =>
  query(
    `SELECT sh.id AS show_id,
       (SELECT COUNT(*) FROM jsonb_array_elements(sc.layout->'seats') s WHERE (s->>'isBlocked')::bool IS NOT TRUE) AS total_seats,
       (SELECT COUNT(*) FROM show_booked_seats WHERE show_id = $1 AND status = 'BOOKED') AS booked_seats,
       sc.layout->'seats' AS seat_map
     FROM shows sh
     JOIN screens sc ON sc.id = sh.screen_id
     WHERE sh.id = $1`,
    [showId],
    scope,
  );

export const getDailyCollections = (hallId, from, to, scope) =>
  query(
    `SELECT gs.date::date AS date,
       COALESCE(SUM(b.total_amount), 0)::numeric(10,2) AS revenue,
       COALESCE(SUM(b.convenience_fee), 0)::numeric(10,2) AS convenience_fee,
       COALESCE(SUM(b.gst_amount), 0)::numeric(10,2) AS gst,
       COUNT(b.id)::int AS bookings_count
     FROM generate_series($2::date, $3::date, '1 day') gs(date)
     LEFT JOIN shows sh ON sh.show_date = gs.date
       AND sh.screen_id IN (SELECT id FROM screens WHERE cinema_hall_id = $1)
     LEFT JOIN bookings b ON b.show_id = sh.id AND b.booking_status = 'confirmed'
     GROUP BY gs.date
     ORDER BY gs.date`,
    [hallId, from, to],
    scope,
  );

export const getMonthlyCollections = (hallId, year, scope) =>
  query(
    `SELECT EXTRACT(MONTH FROM sh.show_date)::int AS month,
       EXTRACT(YEAR FROM sh.show_date)::int AS year,
       COUNT(b.id)::int AS bookings_count,
       COALESCE(SUM(b.total_amount), 0)::numeric(10,2) AS revenue,
       COALESCE(SUM(b.convenience_fee), 0)::numeric(10,2) AS convenience_fee
     FROM shows sh
     JOIN screens sc ON sc.id = sh.screen_id
     LEFT JOIN bookings b ON b.show_id = sh.id AND b.booking_status = 'confirmed'
     WHERE sc.cinema_hall_id = $1 AND EXTRACT(YEAR FROM sh.show_date) = $2
     GROUP BY year, month
     ORDER BY year, month`,
    [hallId, year],
    scope,
  );

export const getHallOccupancy = (hallId, date, scope) =>
  query(
    `SELECT sh.id AS show_id, m.title AS movie_title, sc.name AS screen_name,
       sh.start_time, sh.end_time, sh.status,
       (SELECT COUNT(*) FROM jsonb_array_elements(sc.layout->'seats') s WHERE (s->>'isBlocked')::bool IS NOT TRUE) AS total_seats,
       (SELECT COUNT(*) FROM show_booked_seats WHERE show_id = sh.id AND status = 'BOOKED') AS booked_seats
     FROM shows sh
     JOIN movies m ON m.id = sh.movie_id
     JOIN screens sc ON sc.id = sh.screen_id
     WHERE sc.cinema_hall_id = $1 AND sh.show_date = $2
     ORDER BY sh.start_time`,
    [hallId, date],
    scope,
  );

export const getSeatUtilization = (hallId, from, to, scope) =>
  query(
    `WITH seat_stats AS (
       SELECT sc.name AS screen_name,
              (SELECT COUNT(*) FROM jsonb_array_elements(sc.layout->'seats') s WHERE (s->>'isBlocked')::bool IS NOT TRUE) AS capacity,
              (SELECT COUNT(*) FROM shows WHERE screen_id = sc.id AND show_date BETWEEN $2 AND $3) AS shows_count,
              (SELECT COUNT(*) FROM show_booked_seats sbs
               JOIN shows s ON s.id = sbs.show_id
               WHERE s.screen_id = sc.id AND s.show_date BETWEEN $2 AND $3 AND sbs.status = 'BOOKED') AS booked
       FROM screens sc WHERE sc.cinema_hall_id = $1
     )
     SELECT *, ROUND(booked::numeric / NULLIF(capacity * shows_count, 0) * 100, 1) AS utilization_pct
     FROM seat_stats`,
    [hallId, from, to],
    scope,
  );

export const getMoviePerformance = (hallId, from, to, scope) =>
  query(
    `SELECT m.id AS movie_id, m.title, m.poster_url, m.genre,
       COUNT(DISTINCT sh.id)::int AS shows_count,
       COUNT(b.id)::int AS bookings,
       COALESCE(SUM(b.total_amount), 0)::numeric(10,2) AS revenue,
       COALESCE(AVG(occ.occupancy), 0)::numeric(5,2) AS avg_occupancy_pct
     FROM movies m
     JOIN shows sh ON sh.movie_id = m.id
     JOIN screens sc ON sc.id = sh.screen_id
     LEFT JOIN bookings b ON b.show_id = sh.id AND b.booking_status = 'confirmed'
     LEFT JOIN (
       SELECT show_id, COUNT(*) FILTER (WHERE status = 'BOOKED')::numeric / NULLIF(COUNT(*), 0) * 100 AS occupancy
       FROM show_booked_seats GROUP BY show_id
     ) occ ON occ.show_id = sh.id
     WHERE sc.cinema_hall_id = $1 AND sh.show_date BETWEEN $2 AND $3
     GROUP BY m.id, m.title, m.poster_url, m.genre
     ORDER BY revenue DESC`,
    [hallId, from, to],
    scope,
  );

export const getShowPerformance = (hallId, from, to, scope) =>
  query(
    `SELECT sh.id AS show_id, m.title AS movie_title, sc.name AS screen_name,
       sh.show_date, sh.start_time,
       COUNT(b.id)::int AS bookings_count,
       COALESCE(SUM(b.total_amount), 0)::numeric(10,2) AS total_revenue,
       ROUND(AVG(occ.occupancy), 1) AS occupancy_pct
     FROM shows sh
     JOIN movies m ON m.id = sh.movie_id
     JOIN screens sc ON sc.id = sh.screen_id
     LEFT JOIN bookings b ON b.show_id = sh.id AND b.booking_status = 'confirmed'
     LEFT JOIN (
       SELECT show_id, COUNT(*) FILTER (WHERE status = 'BOOKED')::numeric / NULLIF(COUNT(*), 0) * 100 AS occupancy
       FROM show_booked_seats GROUP BY show_id
     ) occ ON occ.show_id = sh.id
     WHERE sc.cinema_hall_id = $1 AND sh.show_date BETWEEN $2 AND $3
     GROUP BY sh.id, m.title, sc.name, sh.show_date, sh.start_time
     ORDER BY sh.show_date, sh.start_time`,
    [hallId, from, to],
    scope,
  );

export const getBookingSummary = (hallId, from, to, scope) =>
  query(
    `SELECT COUNT(*)::int AS total_bookings,
       COUNT(*) FILTER (WHERE booking_status = 'confirmed')::int AS confirmed_bookings,
       COUNT(*) FILTER (WHERE booking_status = 'cancelled')::int AS cancelled_bookings,
       COALESCE(SUM(total_amount) FILTER (WHERE booking_status = 'confirmed'), 0)::numeric(10,2) AS total_revenue,
       COALESCE(SUM(convenience_fee), 0)::numeric(10,2) AS total_convenience_fee,
       COALESCE(SUM(gst_amount), 0)::numeric(10,2) AS total_gst,
       ROUND(
         COALESCE(SUM(total_amount) FILTER (WHERE booking_status = 'confirmed'), 0)
         / NULLIF(COUNT(*) FILTER (WHERE booking_status = 'confirmed'), 0), 2
       ) AS avg_ticket_price
     FROM bookings b
     JOIN shows sh ON sh.id = b.show_id
     JOIN screens sc ON sc.id = sh.screen_id
     WHERE sc.cinema_hall_id = $1 AND sh.show_date BETWEEN $2 AND $3`,
    [hallId, from, to],
    scope,
  );

export const getCustomerBookingHistory = (customerId, page, limit, scope) => {
  const offset = (page - 1) * limit;
  return Promise.all([
    query(
      `SELECT b.id, m.title AS movie_title, sh.show_date, sh.start_time,
         sc.name AS screen_name, ch.name AS cinema_hall_name,
         b.total_amount, b.booking_status, b.seats, b.created_at
       FROM bookings b
       JOIN shows sh ON sh.id = b.show_id
       JOIN screens sc ON sc.id = sh.screen_id
       JOIN cinema_hall ch ON ch.id = sc.cinema_hall_id
       JOIN movies m ON m.id = sh.movie_id
       WHERE b.customer_id = $1
       ORDER BY b.created_at DESC
       LIMIT $2 OFFSET $3`,
      [customerId, limit, offset],
      scope,
    ),
    query(`SELECT COUNT(*)::int AS total FROM bookings WHERE customer_id = $1`, [customerId], scope),
  ]);
};
```

### 8.8 `src/registry/index.js`

```js
import { cinemaTools } from "../tools/cinema.tools.js";
import { movieTools } from "../tools/movie.tools.js";
import { showTools } from "../tools/show.tools.js";
import { bookingTools } from "../tools/booking.tools.js";
import { userTools } from "../tools/user.tools.js";
import { analyticsTools } from "../tools/analytics.tools.js";
import { platformTools } from "../tools/platform.tools.js";
import { requirePermission } from "../auth/permissions.js";
import { checkRateLimit } from "../ratelimit/tokenBucket.js";
import { toMcpError } from "../errors/index.js";
import logger from "../logging/logger.js";

const allToolDefs = [
  ...cinemaTools,
  ...movieTools,
  ...showTools,
  ...bookingTools,
  ...userTools,
  ...analyticsTools,
  ...platformTools,
];

export function registerTools(server) {
  for (const def of allToolDefs) {
    server.tool(
      def.name,
      def.description,
      def.inputSchema,
      async (rawArgs, extra) => {
        const start = Date.now();
        const scope = extra?.scope || { role: "admin", hall_ids: [], scope_id: "unknown" };

        try {
          requirePermission(def.permission ?? "admin", scope);
          checkRateLimit(def.name, scope, def.rateLimit);

          const result = await def.handler(rawArgs, scope);

          logger.info({
            tool: def.name, scope_id: scope.scope_id, role: scope.role,
            hall_ids: scope.hall_ids, duration_ms: Date.now() - start, status: "ok",
          });

          return result;
        } catch (err) {
          const errorResponse = toMcpError(err);

          logger.error({
            tool: def.name, scope_id: scope.scope_id, role: scope.role,
            duration_ms: Date.now() - start, status: "error",
            err: err.expose ? err.message : "INTERNAL",
          });

          return errorResponse;
        }
      },
    );
  }

  logger.info({ toolCount: allToolDefs.length }, "tools registered");
}
```

### 8.9 `src/errors/index.js`

```js
export function toMcpError(err) {
  const code = err.code || 500;
  const message = err.expose ? err.message : "An internal error occurred";

  return {
    content: [{ type: "text", text: JSON.stringify({ error: message, code }) }],
    isError: true,
  };
}
```

### 8.10 `src/ratelimit/tokenBucket.js`

```js
const buckets = new Map();

export function checkRateLimit(toolName, scope, config = {}) {
  const capacity = config.capacity ?? 30;
  const refillPerSec = config.refillPerSec ?? 2;
  const key = `${scope.scope_id}:${toolName}`;

  let bucket = buckets.get(key);
  const now = Date.now();

  if (!bucket) {
    bucket = { tokens: capacity, lastRefill: now };
    buckets.set(key, bucket);
  }

  const elapsed = (now - bucket.lastRefill) / 1000;
  bucket.tokens = Math.min(capacity, bucket.tokens + elapsed * refillPerSec);
  bucket.lastRefill = now;

  if (bucket.tokens < 1) {
    const e = new Error(`RATE_LIMITED: Tool "${toolName}" capacity exceeded. Try again shortly.`);
    e.code = 429;
    e.expose = true;
    throw e;
  }

  bucket.tokens -= 1;
}

// Periodic cleanup (prevents memory leak)
setInterval(() => {
  const now = Date.now();
  for (const [key, bucket] of buckets.entries()) {
    if (now - bucket.lastRefill > 300_000) buckets.delete(key); // 5 min idle
  }
}, 60_000);
```

### 8.11 `src/transports/stdio.js`

```js
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { resolveScope } from "../auth/scopeResolver.js";
import { env } from "../config/index.js";

export async function startStdio(server) {
  const transport = new StdioServerTransport();
  transport.requestContext = () => ({
    scope: resolveScope({ apiKey: process.env.CINEMAX_MCP_API_KEY }),
  });
  await server.connect(transport);
}
```

### 8.12 `src/transports/http.js`

```js
import express from "express";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { resolveScope } from "../auth/scopeResolver.js";
import { env } from "../config/index.js";

export async function startHttp(server) {
  const app = express();
  app.use(express.json());

  app.get("/healthz", (_req, res) => res.json({ ok: true, uptime: process.uptime() }));
  app.get("/readyz", (_req, res) => res.json({ ok: true }));

  app.post("/mcp", async (req, res) => {
    try {
      const scope = resolveScope({ apiKey: req.headers["x-api-key"] });
      const transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: () => crypto.randomUUID(),
      });
      transport.requestContext = () => ({ scope });
      await server.connect(transport);
      await transport.handleRequest(req, res, req.body);
    } catch (err) {
      const status = err.code === 401 ? 401 : 500;
      res.status(status).json({ error: err.message || "Internal server error" });
    }
  });

  app.listen(env.HTTP_PORT, () => {
    console.log(`cinemax-mcp HTTP transport listening on port ${env.HTTP_PORT}`);
  });
}
```

### 8.13 `src/validation/schemas.js`

```js
import { z } from "zod";

export const uuid = z.string().uuid({ message: "Invalid UUID format" });
export const dateStr = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, { message: "Use YYYY-MM-DD format" });
export const pagination = { page: z.coerce.number().int().min(1).default(1), limit: z.coerce.number().int().min(1).max(100).default(10) };
export const dateRange = { from_date: dateStr.optional(), to_date: dateStr.optional() };
export const cinemaHallId = { cinema_hall_id: uuid };
export const movieStatus = z.enum(["upcoming", "now_showing", "ended"]).optional();
```

### 8.14 `src/logging/logger.js`

```js
import pino from "pino";

const isDev = process.env.NODE_ENV !== "production";

export default pino({
  level: process.env.LOG_LEVEL || (isDev ? "debug" : "info"),
  transport: isDev
    ? { target: "pino-pretty", options: { colorize: true, translateTime: "SYS:standard" } }
    : undefined,
  redact: {
    paths: ["args.password", "args.token", "headers.authorization"],
    censor: "[REDACTED]",
  },
});
```

### 8.15 Tool Example: `src/tools/cinema.tools.js`

```js
import { z } from "zod";
import { listCinemas, getCinema, getCinemaStats, listScreens } from "../db/readonly.js";

export const cinemaTools = [
  {
    name: "list_cinemas",
    description: "List cinema halls. Admins see only their own halls; SuperAdmins see all.",
    inputSchema: { active: z.boolean().optional() },
    permission: "any",
    rateLimit: { capacity: 30, refillPerSec: 2 },
    handler: async (args, scope) => {
      const rows = await listCinemas(scope, args.active);
      return { content: [{ type: "text", text: JSON.stringify({ cinemas: rows }) }] };
    },
  },
  {
    name: "get_cinema",
    description: "Get a single cinema hall by ID with screen count and today's shows count.",
    inputSchema: { cinema_hall_id: z.string().uuid() },
    permission: "any",
    rateLimit: { capacity: 30, refillPerSec: 2 },
    handler: async (args, scope) => {
      const rows = await getCinema(args.cinema_hall_id, scope);
      if (rows.length === 0) {
        return { content: [{ type: "text", text: JSON.stringify({ error: "Cinema hall not found" }) }], isError: true };
      }
      return { content: [{ type: "text", text: JSON.stringify({ cinema: rows[0] }) }] };
    },
  },
  {
    name: "get_cinema_stats",
    description: "Key performance indicators for a cinema hall over a date range.",
    inputSchema: {
      cinema_hall_id: z.string().uuid(),
      from_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
      to_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
    },
    permission: "any",
    rateLimit: { capacity: 10, refillPerSec: 1 },
    handler: async (args, scope) => {
      const today = new Date();
      const thirtyDaysAgo = new Date(today);
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      const from = args.from_date ?? thirtyDaysAgo.toISOString().slice(0, 10);
      const to = args.to_date ?? today.toISOString().slice(0, 10);

      const rows = await getCinemaStats(args.cinema_hall_id, from, to, scope);
      return { content: [{ type: "text", text: JSON.stringify({
        cinema_hall_id: args.cinema_hall_id,
        range: { from, to },
        ...rows[0]?.stats,
        top_movies: rows[0]?.top_movies ?? [],
      }) }] };
    },
  },
  {
    name: "list_cinema_screens",
    description: "List all screens in a cinema hall with seat configuration and pricing.",
    inputSchema: { cinema_hall_id: z.string().uuid() },
    permission: "any",
    rateLimit: { capacity: 30, refillPerSec: 2 },
    handler: async (args, scope) => {
      const rows = await listScreens(args.cinema_hall_id, scope);
      return { content: [{ type: "text", text: JSON.stringify({ screens: rows }) }] };
    },
  },
];
```

### 8.16 `src/tools/movie.tools.js`

```js
import { z } from "zod";
import { getMovieStats } from "../db/readonly.js";
import { apiClient } from "../api/client.js";

export const movieTools = [
  {
    name: "list_movies",
    description: "Search and filter movies by status, genre, language, or text search.",
    inputSchema: {
      status: z.enum(["upcoming", "now_showing", "ended"]).optional(),
      genre: z.array(z.string()).optional(),
      language: z.array(z.string()).optional(),
      search: z.string().optional(),
      page: z.coerce.number().int().min(1).default(1),
      limit: z.coerce.number().int().min(1).max(100).default(10),
    },
    permission: "any",
    rateLimit: { capacity: 30, refillPerSec: 2 },
    handler: async (args) => {
      const params = new URLSearchParams();
      if (args.status) params.set("status", args.status);
      if (args.genre) args.genre.forEach(g => params.append("genre", g));
      if (args.language) args.language.forEach(l => params.append("language", l));
      if (args.search) params.set("search", args.search);
      params.set("page", String(args.page));
      params.set("limit", String(args.limit));

      const client = apiClient();
      const { data } = await client.get(`/api/movies?${params.toString()}`);
      return { content: [{ type: "text", text: JSON.stringify(data) }] };
    },
  },
  {
    name: "get_movie",
    description: "Full movie details including description, cast, trailer URL, and TMDB metadata.",
    inputSchema: { movie_id: z.string().uuid() },
    permission: "any",
    rateLimit: { capacity: 30, refillPerSec: 2 },
    handler: async (args) => {
      const client = apiClient();
      const { data } = await client.get(`/api/movies/${args.movie_id}`);
      return { content: [{ type: "text", text: JSON.stringify(data) }] };
    },
  },
  {
    name: "list_now_showing_movies",
    description: "Movies currently showing in theatres.",
    inputSchema: {
      page: z.coerce.number().int().min(1).default(1),
      limit: z.coerce.number().int().min(1).max(100).default(10),
    },
    permission: "any",
    rateLimit: { capacity: 30, refillPerSec: 2 },
    handler: async (args) => {
      const client = apiClient();
      const { data } = await client.get(`/api/movies?status=now_showing&page=${args.page}&limit=${args.limit}`);
      return { content: [{ type: "text", text: JSON.stringify(data) }] };
    },
  },
  {
    name: "list_upcoming_movies",
    description: "Movies coming soon to theatres.",
    inputSchema: {
      page: z.coerce.number().int().min(1).default(1),
      limit: z.coerce.number().int().min(1).max(100).default(10),
    },
    permission: "any",
    rateLimit: { capacity: 30, refillPerSec: 2 },
    handler: async (args) => {
      const client = apiClient();
      const { data } = await client.get(`/api/movies?status=upcoming&page=${args.page}&limit=${args.limit}`);
      return { content: [{ type: "text", text: JSON.stringify(data) }] };
    },
  },
  {
    name: "get_movie_stats",
    description: "Bookings and revenue statistics for a movie in a specific cinema hall.",
    inputSchema: {
      movie_id: z.string().uuid(),
      cinema_hall_id: z.string().uuid().optional(),
      from_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
      to_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
    },
    permission: "any",
    rateLimit: { capacity: 20, refillPerSec: 1 },
    handler: async (args, scope) => {
      const today = new Date();
      const from = args.from_date ?? new Date(today.getTime() - 30 * 86400000).toISOString().slice(0, 10);
      const to = args.to_date ?? today.toISOString().slice(0, 10);
      const rows = await getMovieStats(args.movie_id, args.cinema_hall_id, from, to, scope);
      return { content: [{ type: "text", text: JSON.stringify({ movie_stats: rows[0] ?? null }) }] };
    },
  },
];
```

### 8.17 `src/api/client.js`

```js
import axios from "axios";
import { env } from "../config/index.js";

export function apiClient(scope) {
  const headers = { "Content-Type": "application/json" };

  if (process.env.MCP_SERVICE_TOKEN) {
    headers.Authorization = `Bearer ${process.env.MCP_SERVICE_TOKEN}`;
  }
  if (scope?.hall_ids?.length > 0) {
    headers["X-Hall-Id"] = scope.hall_ids[0];
  }

  return axios.create({
    baseURL: env.API_BASE_URL,
    headers,
    timeout: 10000,
    validateStatus: (status) => status < 500,
  });
}
```

### 8.18 `.env.example`

```env
# Required: PostgreSQL read-only connection string
DATABASE_URL=postgresql://cinemax_reader:password@localhost:5432/cinema_hall_db

# Cinemax API base URL (for API-sourced tools)
API_BASE_URL=http://localhost:5000

# Transport: "stdio" (default) or "http"
MCP_TRANSPORT=stdio

# HTTP transport port (MCP_TRANSPORT=http)
HTTP_PORT=8787

# API key configuration (choose one):

# Option A: Single key
CINEMAX_MCP_API_KEY=cmax_abc123...

# Option B: Multi-key scoped (key=role:hallId1,hallId2)
# MCP_API_KEYS="cmax_admin=admin:uuid1,uuid2;cmax_super=superAdmin"

# Optional: service token (Phase 3+)
# MCP_SERVICE_TOKEN=eyJhbGci...

# Rate limiting limits
RATELIMIT_CAPACITY=30
RATELIMIT_REFILL_PER_SEC=2

# Optional: Redis for multi-instance rate limiting
# REDIS_URL=redis://localhost:6379

# Optional: Sentry error tracking
# SENTRY_DSN=https://key@oorg.ingest.us.sentry.io/project
LOG_LEVEL=info
```

---

## 9. Client Configuration

### Claude Desktop (`claude_desktop_config.json`)

```json
{
  "mcpServers": {
    "cinemax": {
      "command": "node",
      "args": ["D:/path/to/cinemax-mcp-server/src/server.js"],
      "env": {
        "CINEMAX_MCP_API_KEY": "cmax_your_key_here",
        "DATABASE_URL": "postgresql://cinemax_reader:password@host:5432/cinema_hall_db",
        "API_BASE_URL": "http://localhost:5000",
        "LOG_LEVEL": "info"
      }
    }
  }
}
```

### OpenCode (`~/.opencode/config.json` or MCP config)

```json
{
  "mcpServers": {
    "cinemax": {
      "command": "node",
      "args": ["D:/path/to/cinemax-mcp-server/src/server.js"],
      "env": {
        "CINEMAX_MCP_API_KEY": "cmax_your_key_here",
        "DATABASE_URL": "postgresql://cinemax_reader:password@host:5432/cinema_hall_db",
        "API_BASE_URL": "http://localhost:5000"
      }
    }
  }
}
```

### Cursor / Windsurf

Create `.cursor/mcp.json` (or platform equivalent):

```json
{
  "mcpServers": {
    "cinemax": {
      "command": "node",
      "args": ["D:/path/to/cinemax-mcp-server/src/server.js"],
      "env": {
        "CINEMAX_MCP_API_KEY": "cmax_your_key_here",
        "DATABASE_URL": "postgresql://cinemax_reader:password@host:5432/cinema_hall_db",
        "API_BASE_URL": "http://localhost:5000"
      }
    }
  }
}
```

### Cline / Roo Code

Add to MCP settings in the extension settings UI or config file:

```json
{
  "mcpServers": {
    "cinemax": {
      "command": "node",
      "args": ["D:/path/to/cinemax-mcp-server/src/server.js"],
      "env": {
        "CINEMAX_MCP_API_KEY": "cmax_your_key_here",
        "DATABASE_URL": "postgresql://cinemax_reader:password@host:5432/cinema_hall_db",
        "API_BASE_URL": "http://localhost:5000"
      }
    }
  }
}
```

### ChatGPT / OpenAI Agents (HTTP Mode)

Deploy the HTTP transport (e.g., on Fly.io, Railway, or Vercel), then register:

```
URL: https://cinemax-mcp.fly.io/mcp
Auth Header: x-api-key: cmax_your_key_here
```

---

## 10. Future AI Capabilities

| Phase | Tool | What it returns | Underlying approach |
|---|---|---|---|
| 5 | `predict_movie_demand` | Expected bookings with confidence interval | Time-series model on historical bookings + TMDB popularity + seasonality |
| 5 | `predict_occupancy` | Per-show occupancy % forecast for next 7 days | Gradient boosting on show/day/screen/hall features |
| 5 | `forecast_revenue` | Daily/weekly revenue with scenarios | Prophet/ARIMA on revenue series |
| 5 | `recommend_dynamic_pricing` | Suggested price multipliers per tier | Constrained optimization on demand curve |
| 5 | `score_cinema_performance` | Composite score (0–100) vs peers | Weighted KPIs (occupancy, revenue/screen, retention) |
| 5 | `recommend_movies` | Movie picks for a hall given audience taste | Collaborative filtering on bookings + genre affinity |
| 5 | `detect_fraud` | Risk flags on recent bookings | Rules + anomaly detection on payment velocity |
| 6 | `bi_assistant` | NL query → analytics + narrative summary | LLM router over analytics tools with citations |

**Governance:** All `predict_*`/`recommend_*` return **suggestions with confidence**, never auto-applied. Phase 3 mutations use `prepare_`/`confirm_` nonce pattern so AI proposes, human approves.

---

## Appendix: DB Schema Reference

Key tables used by Phase 1 tools:

```sql
-- cinema_hall: halls (scoped by admin_id)
-- screens: cinema screens, JSONB seat layout
-- movies: movie catalog synced from TMDB
-- shows: scheduled shows (scoped by screen → hall)
-- show_booked_seats: individual seat bookings per show
-- bookings: confirmed customer bookings (scoped by show → screen → hall)
-- payment_orders: Razorpay orders
-- refunds: refund records per booking
-- customers: registered customers
-- cinema_admin_user: admin users (role: admin | superAdmin)
-- offers: discount coupons
-- offer_redemptions: coupon usage tracking
-- ads: advertisement campaigns
-- ad_clicks: ad click-through logs
-- settings: global system settings (convenience fee, GST)
```

Full schema with all columns: see `docs/backend.md` or `docs/db_setup.sql`.

---

*End of Implementation Plan — June 2026*
