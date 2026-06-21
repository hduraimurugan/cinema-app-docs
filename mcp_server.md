# Cinemax MCP Server

> Model Context Protocol (MCP) server for the Cinemax cinema booking platform — Phase 1 read-only.
> Provides **read-only** tools for AI assistants to query cinema, movie, show, booking, user, and analytics data.

## Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Project Structure](#project-structure)
4. [Quick Start](#quick-start)
5. [Configuration](#configuration)
6. [Architecture](#architecture)
7. [Security](#security)
8. [Tool Catalog (36 Tools)](#tool-catalog)
9. [Client Configuration](#client-configuration)
10. [Database Setup](#database-setup)
11. [Phase Roadmap](#phase-roadmap)

---

## Overview

The Cinemax MCP server acts as a bridge between AI assistants (Claude Desktop, OpenCode, Cursor, ChatGPT, etc.) and the Cinemax cinema booking platform. It exposes **36 read-only tools** across 7 domains — Cinema, Movies, Shows, Bookings, Users, Analytics, and Platform.

**Data sources:**
- **Direct DB queries** — analytics, aggregate stats, cinema/screen/show occupancy (PostgreSQL via `pg` pool, `cinemax_reader` role, RLS-enforced)
- **REST API proxy** — movie catalog, dashboard, booking admin endpoints, offers, ads, settings (via `axios` to the Cinemax Express API)

**Transport modes:**
- **stdio** — for local AI assistants (Claude Desktop, OpenCode, Cursor, Cline, Roo Code)
- **Streamable HTTP** — for remote access (ChatGPT, OpenAI Agents, web deployments)

---

## Technology Stack

| Concern | Choice | Rationale |
|---|---|---|
| Runtime | Node.js 20+ ESM (`"type": "module"`) | Matches backend |
| MCP SDK | `@modelcontextprotocol/sdk` ^1.8.0 | Official; supports stdio + Streamable HTTP; consumes zod schemas natively |
| Validation | `zod` ^3.24.4 | MCP SDK integration for auto-generated tool input schemas |
| DB Driver | `pg` ^8.16.2 | Prepared statements; connection pooling (max 8) |
| HTTP Client | `axios` ^1.7.9 | Matches backend frontend API services |
| Logging | `pino` ^9.6.0 | Structured JSON; fast for long-lived process |
| Rate Limiting | In-memory token bucket | Per-tool, per-scope limits; 5-minute idle cleanup |
| Config | `dotenv` + zod env schema | Typed configuration; fails fast on missing env vars |
| Tests | `vitest` ^4.1.8 | Matches backend test runner |

---

## Project Structure

```
cinemax-mcp-server/
├── .env.example
├── .gitignore
├── package.json
├── README.md
├── start-cinemax-mcp.bat           # Windows launcher (sets env vars for Claude Desktop)
│
├── src/
│   ├── server.js                   # Entry point: McpServer + transport selector
│   │
│   ├── transports/
│   │   ├── stdio.js                # StdioServerTransport bootstrap + scope injection
│   │   └── http.js                 # Express + StreamableHTTPServerTransport + /healthz, /readyz
│   │
│   ├── config/
│   │   ├── index.js                # Typed env config via zod (schema + parse)
│   │   └── scope-map.js            # MCP_API_KEYS → {role, hall_ids[]} loader
│   │
│   ├── auth/
│   │   ├── scopeResolver.js        # API key → scope object (single-key or multi-key map)
│   │   └── permissions.js          # Permission gate: tool → required role (admin / superAdmin)
│   │
│   ├── db/
│   │   └── readonly.js             # pg Pool (cinemax_reader) + query functions (allowlist)
│   │
│   ├── api/
│   │   └── client.js               # axios client (MCP_SERVICE_TOKEN + X-Hall-Id)
│   │
│   ├── registry/
│   │   └── index.js                # Aggregates all 36 tools, registers on McpServer with middleware
│   │
│   ├── tools/
│   │   ├── cinema.tools.js         # 4 tools: list/get cinemas, stats, screens
│   │   ├── movie.tools.js          # 5 tools: catalog search, details, now showing, upcoming, stats
│   │   ├── show.tools.js           # 4 tools: schedule by date, show detail, occupancy, booking count
│   │   ├── booking.tools.js        # 4 tools: single booking, list, summary, daily trend
│   │   ├── user.tools.js           # 3 tools: customers list/detail/history (superAdmin only)
│   │   ├── analytics.tools.js      # 8 tools: daily/weekly/monthly collections, occupancy, utilization, revenue, movie/show performance
│   │   └── platform.tools.js       # 8 tools: dashboard stats, payment orders, refunds, offers, ads, settings, admins, audit logs
│   │
│   ├── validation/
│   │   └── schemas.js              # Shared zod: uuid, dateStr, pagination, dateRange, cinemaHallId, bookingStatus
│   │
│   ├── errors/
│   │   └── index.js                # toMcpError → safe MCP error response (never leaks internals)
│   │
│   ├── ratelimit/
│   │   └── tokenBucket.js          # Per-scope + per-tool token bucket with periodic cleanup
│   │
│   ├── logging/
│   │   └── logger.js               # pino instance (stderr)
│   │
│   └── util/                       # (reserved for future pagination/date helpers)
│
├── sql/
│   ├── 01_readonly_role.sql        # CREATE ROLE cinemax_reader + GRANT SELECT + sensitive revocations
│   └── 02_rls_policies.sql         # Per-table RLS policies for hall isolation (cinema_hall, screens, shows, bookings, customers, etc.)
│
├── tests/
│   ├── tools/                      # (test files planned)
│   └── helpers/                    # (test helpers planned)
│
└── examples/
    ├── claude_desktop_config.json  # Claude Desktop MCP config template
    └── opencode_mcp_config.json    # OpenCode MCP config template
```

---

## Quick Start

### Prerequisites

- Node.js 20+
- PostgreSQL database (read-only access via `cinemax_reader` role)
- Access to the Cinemax API

### Installation

```bash
cd cinemax-mcp-server
npm install
cp .env.example .env
```

Edit `.env`:
- Set `DATABASE_URL` to your PostgreSQL connection string (use the `cinemax_reader` role)
- Set `CINEMAX_MCP_API_KEY` to a secure random key (`node -e "console.log('cmax_' + require('crypto').randomBytes(32).toString('hex'))"`)
- Set `API_BASE_URL` to your Cinemax API endpoint

### Run

```bash
# stdio mode (default) — for Claude Desktop, OpenCode, Cursor, Cline, Roo Code
npm start

# HTTP mode — for ChatGPT, OpenAI Agents, remote access
npm run start:http

# Dev mode with file watching
npm run dev
```

---

## Configuration

All configuration is via environment variables, validated at startup by a zod schema.

| Variable | Required | Default | Description |
|---|---|---|---|
| `DATABASE_URL` | Yes | — | PostgreSQL connection string (e.g., `postgresql://cinemax_reader:pass@localhost:5432/cinema_hall_db`) |
| `API_BASE_URL` | Yes | `http://localhost:5000` | Cinemax REST API base URL |
| `MCP_TRANSPORT` | No | `stdio` | Transport mode: `stdio` or `http` |
| `HTTP_PORT` | No | `8787` | HTTP transport listen port |
| `CINEMAX_MCP_API_KEY` | Maybe | — | Single API key (simplest for stdio mode; gets superAdmin) |
| `MCP_API_KEYS` | Maybe | — | Multi-key scoped config: `key1=admin:uuid1,uuid2;key2=superAdmin` |
| `LOG_LEVEL` | No | `info` | pino log level: `fatal`, `error`, `warn`, `info`, `debug`, `trace` |
| `SENTRY_DSN` | No | — | Sentry error tracking DSN (optional) |
| `MCP_SERVICE_TOKEN` | Yes (for API tools) | — | JWT access token used by the MCP server to authenticate its proxy requests with the backend API |


**Authentication modes:**
- **Single-key mode:** Set `CINEMAX_MCP_API_KEY` — the key gets `superAdmin` privileges with access to all halls.
- **Multi-key mode:** Set `MCP_API_KEYS` — format: `key1=admin:uuid1,uuid2;key2=superAdmin`. Each key maps to a role and optional hall ID allowlist. `superAdmin` with no hall IDs = access to all.

---

## Architecture

### High-Level Flow

```
AI Assistant ──stdio/HTTP──> cinemax-mcp-server ──DB/API──> Cinemax Backend
(Claude,                        (McpServer + 36          (Express 5 + PostgreSQL)
 ChatGPT,                        tools + RLS)
 Cursor...)
```

### Tool Call Flow

```
1. Client sends tools/call {name, args}
2. Transport receives call → resolves API key → scope = {role, hall_ids[], scope_id}
3. Registry injects scope into handler context
4. Permission gate checks tool's required role vs scope.role
5. Rate limiter checks per-tool, per-scope token bucket
6. Handler validates args with zod
7. Handler executes:
   a. DB path: parameterized SQL + RLS session vars → pg Pool
   b. API path: axios GET with X-Hall-Id → Cinemax Express API
8. Result returned as {content: [{type: "text", text: JSON.stringify(...)}]}
```

### Security Layers

1. **API key authentication** — key → scope resolver (single-key or multi-key map)
2. **Permission gate** — tool-level role check (`any`, `admin`, `superAdmin`)
3. **zod input validation** — all inputs validated before handler execution
4. **Parameterized SQL** — no raw SQL injection from tool arguments
5. **RLS policies** — database-level row-level security enforces per-hall scoping
6. **Read-only DB role** — `cinemax_reader` has SELECT-only, no write capabilities
7. **Sensitive column revocation** — passwords, tokens, OTPs explicitly revoked from reader role
8. **Audit logging** — every tool call logged with scope, duration, and status

---

## Security

### Permission Model

| Role | Can call | Cannot call |
|---|---|---|
| `admin` | Cinema (1–4), Movie (5–9), Show (10–13), Booking (14–17), Analytics (21–28), Dashboard stats (29), Payment orders (30), Refunds (31), Active ads (33), Settings (34) | User tools (18–20), Offers (32), Admins (35), Audit logs (36) |
| `superAdmin` | All 36 tools | — |

### RLS Architecture

The SQL scripts in `sql/` set up:
- **`01_readonly_role.sql`** — creates `cinemax_reader` role, grants SELECT on all tables, revokes sensitive tables/columns
- **`02_rls_policies.sql`** — per-table RLS policies that check `app.current_hall_ids` and `app.scope_role` session variables (set by the MCP server before each query)
  - SuperAdmin bypasses all RLS restrictions
  - Admin queries are scoped to their authorized hall IDs
  - `customers` and `cinema_admin_user` tables are superAdmin-only

---

## Tool Catalog

### Cinema Tools (4)

| Tool | Description | Input | Permission | Source |
|---|---|---|---|---|
| `list_cinemas` | List cinema halls (admins see own, superAdmins see all) | `{ active?: boolean }` | any | DB |
| `get_cinema` | Single cinema hall by ID with screen count + today's shows | `{ cinema_hall_id: uuid }` | any | DB |
| `get_cinema_stats` | KPIs over date range: bookings, revenue, fees, top movies | `{ cinema_hall_id: uuid, from_date?, to_date? }` | any | DB |
| `list_cinema_screens` | Screens in a hall with seat config and pricing tiers | `{ cinema_hall_id: uuid }` | any | DB |

### Movie Tools (5)

| Tool | Description | Input | Permission | Source |
|---|---|---|---|---|
| `list_movies` | Search/filter movie catalog by status, genre, language, text | `{ status?, genre?, language?, search?, page?, limit? }` | any | API |
| `get_movie` | Full movie details (description, cast, trailer, TMDB) | `{ movie_id: uuid }` | any | API |
| `list_now_showing_movies` | Convenience — movies currently in theatres | `{ page?, limit? }` | any | API |
| `list_upcoming_movies` | Convenience — movies coming soon | `{ page?, limit? }` | any | API |
| `get_movie_stats` | Bookings, revenue, occupancy for a movie (optionally scoped to hall) | `{ movie_id: uuid, cinema_hall_id?, from_date?, to_date? }` | any | DB |

### Show Tools (4)

| Tool | Description | Input | Permission | Source |
|---|---|---|---|---|
| `list_shows_by_date` | Shows scheduled for a date, grouped by movie | `{ cinema_hall_id: uuid, date: YYYY-MM-DD }` | any | API |
| `get_show` | Full show details with pricing and seat breakdown | `{ show_id: uuid }` | any | API |
| `get_show_occupancy` | Seat occupancy breakdown by category (premium, gold, silver) | `{ show_id: uuid }` | any | DB |
| `get_show_booking_count` | Confirmed booking count + total amount for a show | `{ show_id: uuid }` | any | API |

### Booking Tools (4)

| Tool | Description | Input | Permission | Source |
|---|---|---|---|---|
| `get_booking` | Single booking by UUID with full details | `{ booking_id: uuid }` | any | API |
| `list_bookings` | List bookings with filters (date range, status, screen, search) | `{ cinema_hall_id: uuid, from_date?, to_date?, status?, screen_id?, search?, page?, limit? }` | any | API |
| `get_booking_summary` | Aggregate stats: confirmed/cancelled counts, revenue, fees, avg price | `{ cinema_hall_id: uuid, from_date?, to_date? }` | any | DB |
| `get_bookings_by_date` | Daily booking count + revenue trend over a date range | `{ cinema_hall_id: uuid, from_date?, to_date? }` | any | DB |

### User Tools (3) — superAdmin only

| Tool | Description | Input | Permission | Source |
|---|---|---|---|---|
| `list_customers` | Platform-wide customer list with search and stats | `{ search?, page?, limit? }` | superAdmin | API |
| `get_customer` | Full customer details with recent bookings and sessions | `{ customer_id: uuid }` | superAdmin | API |
| `get_customer_booking_history` | All confirmed bookings for a customer, date-descending | `{ customer_id: uuid, page?, limit? }` | superAdmin | DB |

### Analytics Tools (8)

| Tool | Description | Input | Permission | Source |
|---|---|---|---|---|
| `get_daily_collections` | Daily revenue, bookings, fees over date range | `{ cinema_hall_id: uuid, from_date?, to_date? }` | any | DB |
| `get_weekly_collections` | Weekly aggregated revenue/bookings by ISO week | `{ cinema_hall_id: uuid, from_date?, to_date? }` | any | DB |
| `get_monthly_collections` | Monthly aggregated revenue/bookings by year | `{ cinema_hall_id: uuid, year? }` | any | DB |
| `get_hall_occupancy` | Per-show seat occupancy for a date | `{ cinema_hall_id: uuid, date? }` | any | DB |
| `get_seat_utilization` | Overall seat utilization % over period, by screen | `{ cinema_hall_id: uuid, from_date?, to_date? }` | any | DB |
| `get_revenue_report` | Comprehensive revenue by movie and screen | `{ cinema_hall_id: uuid, from_date?, to_date? }` | any | DB |
| `get_movie_performance` | Per-movie metrics: shows, bookings, revenue, occupancy | `{ cinema_hall_id: uuid, from_date?, to_date? }` | any | DB |
| `get_show_performance` | Per-show metrics: revenue, bookings, occupancy % | `{ cinema_hall_id: uuid, from_date?, to_date? }` | any | DB |

### Platform Tools (8)

| Tool | Description | Input | Permission | Source |
|---|---|---|---|---|
| `get_dashboard_stats` | All dashboard metrics: today, 7-day trend, recent bookings, today shows | `{ cinema_hall_id?: uuid }` | any | API |
| `list_payment_orders` | Payment orders with date range, status, search filters | `{ cinema_hall_id: uuid, from_date?, to_date?, status?, search?, page?, limit? }` | any | API |
| `list_refunds` | Refund records by status/date range | `{ cinema_hall_id: uuid, status?, from_date?, to_date?, page?, limit? }` | any | API |
| `list_offers` | All discount offers/coupons with filters | `{ scope?, is_active?, search?, page?, limit? }` | superAdmin | API |
| `list_active_ads` | Currently active ads by placement (banner/side) | `{ placement? }` | any | API |
| `get_settings` | System-wide fee configuration | `{}` | any | API |
| `list_admins` | All cinema hall admins with hall details | `{ search?, page?, limit? }` | superAdmin | API |
| `get_admin_audit_logs` | Security audit logs for a specific admin | `{ admin_id: uuid }` | superAdmin | API |

---

## Client Configuration

### Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "cinemax": {
      "command": "node",
      "args": ["D:/path/to/cinemax-mcp-server/src/server.js"],
      "env": {
        "CINEMAX_MCP_API_KEY": "cmax_your_api_key_here",
        "DATABASE_URL": "postgresql://cinemax_reader:password@localhost:5432/cinema_hall_db",
        "API_BASE_URL": "http://localhost:5000",
        "MCP_SERVICE_TOKEN": "your_jwt_service_token_here",
        "LOG_LEVEL": "info"
      }
    }
  }
}
```

### OpenCode

Add to MCP config (typically `~/.opencode/config.json`):

```json
{
  "mcpServers": {
    "cinemax": {
      "command": "node",
      "args": ["D:/path/to/cinemax-mcp-server/src/server.js"],
      "env": {
        "CINEMAX_MCP_API_KEY": "cmax_your_api_key_here",
        "DATABASE_URL": "postgresql://cinemax_reader:password@localhost:5432/cinema_hall_db",
        "API_BASE_URL": "http://localhost:5000",
        "MCP_SERVICE_TOKEN": "your_jwt_service_token_here"
      }
    }
  }
}
```

### Cursor / Windsurf / Cline / Roo Code

Same stdio config format; see `examples/` directory for templates.

### ChatGPT / OpenAI Agents (HTTP Mode)

Deploy with `MCP_TRANSPORT=http`, then register the endpoint:

```
URL: https://your-host:8787/mcp
Auth Header: x-api-key: cmax_your_key_here
```

Health checks: `GET /healthz`, `GET /readyz`

---

## Database Setup

```bash
# 1. Create the cinemax_reader role
psql -U postgres -d cinema_hall_db -f sql/01_readonly_role.sql

# 2. Enable Row-Level Security for hall-scoped data access
psql -U postgres -d cinema_hall_db -f sql/02_rls_policies.sql
```

Tables accessible to the MCP server (via `cinemax_reader` role):
- `cinema_hall` — hall listing and details
- `screens` — screen configuration, pricing, seat layout (JSONB)
- `movies` — movie catalog from TMDB
- `shows` — scheduled shows
- `show_booked_seats` — individual seat booking status
- `bookings` — customer booking records
- `payment_orders` — Razorpay payment orders
- `refunds` — refund records
- `customers` — registered customers (superAdmin only via RLS)
- `cinema_admin_user` — admin users (superAdmin only via RLS)
- `offers` / `offer_redemptions` — discount offers
- `ads` / `ad_clicks` — advertisements
- `settings` — global system settings

**Explicitly revoked** from the reader role: `admin_sessions`, `customer_sessions`, `admin_verification_tokens`, `admin_password_reset_tokens`, `otp_verifications`, `webhook_events`, and `password` columns on `cinema_admin_user` and `customers`.

---

## Phase Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 | Read-only tools (36 tools, DB + API) | ✅ Complete |
| 2 | Advanced analytics, caching, materialized views | 🔜 Planned |
| 3 | Admin management (CRUD via `prepare_`/`confirm_` pattern) | 🔜 Planned |
| 4 | Booking management (holds, confirms, refunds) | 🔜 Planned |
| 5 | AI-powered analytics (predictions, recommendations) | 🔜 Planned |
| 6 | Multi-cinema business intelligence | 🔜 Planned |

See `mcp_implementation_plan.md` for detailed implementation notes, tool schemas, and future capabilities.

---

## Deployment Guide

### 1. Local Setup (stdio mode for Claude Desktop / OpenCode)

#### Step 1: Install dependencies
```bash
cd cinemax-mcp-server
npm install
cp .env.example .env
```

#### Step 2: Configure `.env`

| Variable | Example Value |
|---|---|
| `DATABASE_URL` | `postgresql://cinemax_reader:password@localhost:5432/cinema_hall_db` |
| `API_BASE_URL` | `http://localhost:5000` (local API) or your deployed API |
| `CINEMAX_MCP_API_KEY` | `cmax_` + 64 hex chars (generate: `node -e "console.log('cmax_'+require('crypto').randomBytes(32).toString('hex'))"`) |
| `MCP_SERVICE_TOKEN` | JWT from Step 3 (required for API-sourced tools) |
| `MCP_TRANSPORT` | `stdio` (default for local) |

#### Step 3: Generate a JWT service token

API-sourced tools (`list_bookings`, `get_dashboard_stats`, `list_customers`, etc.) require a valid admin JWT to authenticate with the backend API. Generate one using the admin's actual UUID from your database:

```bash
node -e "
const jwt = require('jsonwebtoken');
const secret = '<your_jwt_secret_from_api_env>';
const payload = {
  id: '<admin_uuid_from_db>',
  name: '<admin_name>',
  email: '<admin_email>',
  role: 'superAdmin',
  iat: Math.floor(Date.now() / 1000),
  exp: Math.floor(Date.now() / 1000) + 365 * 24 * 3600  // 1 year
};
console.log(jwt.sign(payload, secret));
"
```

Run this inside your API directory (`cinema-hall-api/`) where `jsonwebtoken` is available. Set the output as `MCP_SERVICE_TOKEN` in your `.env`.

#### Step 4: Run
```bash
# stdio mode (for Claude Desktop, OpenCode, Cursor, etc.)
npm start

# Or with file watching
npm run dev
```

#### Step 5: Configure your AI assistant

**Claude Desktop** — edit `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "cinemax": {
      "command": "node",
      "args": ["D:/path/to/cinemax-mcp-server/src/server.js"],
      "env": {
        "CINEMAX_MCP_API_KEY": "cmax_your_api_key_here",
        "DATABASE_URL": "postgresql://cinemax_reader:password@localhost:5432/cinema_hall_db",
        "API_BASE_URL": "http://localhost:5000",
        "MCP_SERVICE_TOKEN": "your_jwt_service_token_here",
        "LOG_LEVEL": "info"
      }
    }
  }
}
```

**OpenCode / Cursor / Cline** — same format; see `examples/` for templates.

---

### 2. Cloud Deployment (Render.com + Neon DB)

#### Prerequisites
- GitHub repository with the cinemax-mcp-server code
- Neon PostgreSQL database (or any cloud Postgres)
- Cinemax API deployed (Vercel or other)

#### Step 1: Database setup on Neon

Connect to your Neon database and run the setup scripts:

```bash
# Create the cinemax_reader role and grant SELECT permissions
psql "<neon_admin_connection_string>" -f sql/01_readonly_role.sql

# Enable Row-Level Security policies
psql "<neon_admin_connection_string>" -f sql/02_rls_policies.sql
```

The scripts will:
- Create `cinemax_reader` role with a password
- Grant SELECT on all existing and future tables
- Revoke access to sensitive tables (sessions, tokens, OTPs)
- Set up RLS policies for hall-scoped data access

#### Step 2: Push code to GitHub

```bash
cd cinemax-mcp-server
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/<your-username>/cinemax-mcp-server.git
git push -u origin main
```

#### Step 3: Create a Render Web Service

1. Go to [render.com](https://render.com) → Dashboard → **New +** → **Web Service**
2. Connect your GitHub repository
3. Configure the service:

| Setting | Value |
|---|---|
| **Name** | `cinemax-mcp` |
| **Runtime** | Node |
| **Build Command** | `npm install` |
| **Start Command** | `node src/server.js` |
| **Plan** | Free (or paid for production) |

4. Add the following **Environment Variables**:

| Key | Value |
|---|---|
| `MCP_TRANSPORT` | `http` |
| `HTTP_PORT` | `10000` |
| `DATABASE_URL` | `postgresql://cinemax_reader:password@<neon-host>/<dbname>?sslmode=require` |
| `API_BASE_URL` | `https://your-cinemax-api.vercel.app` (or your API URL) |
| `CINEMAX_MCP_API_KEY` | `cmax_` + 64 hex chars |
| `MCP_SERVICE_TOKEN` | JWT generated from Step 5 (required for API-sourced tools) |
| `LOG_LEVEL` | `info` |

> **Important:** For Neon, always add `?sslmode=require` to the `DATABASE_URL`. The Node.js `pg` driver rejects non-SSL connections with error code `28000`.

5. Click **Deploy**

#### Step 4: Verify deployment

Check Render logs for:
```
cinemax-mcp HTTP transport listening on port 10000
```

Test the MCP endpoint:
```bash
curl -X POST "https://cinemax-mcp-server.onrender.com/mcp" \
  -H "x-api-key: cmax_your_api_key_here" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

Expected response: SSE stream with all 36 tool definitions.

#### Step 5: Generate a JWT for the production database

The JWT must contain the **correct admin UUID from your production database** (not local). Local and production databases assign different UUIDs to the same admin user.

```bash
# 1. Get the admin's UUID from production DB
psql "<neon_admin_connection_string>" -c "SELECT id, name, email, role FROM cinema_admin_user WHERE email = 'your@email.com';"

# 2. Generate the JWT using your API's JWT_SECRET
node -e "
const jwt = require('jsonwebtoken');
const secret = '<production_jwt_secret>';
const payload = {
  id: '<admin_uuid_from_step_1>',
  name: '<admin_name>',
  email: '<admin_email>',
  role: 'superAdmin',
  iat: Math.floor(Date.now() / 1000),
  exp: Math.floor(Date.now() / 1000) + 365 * 24 * 3600
};
console.log(jwt.sign(payload, secret));
"
```

Set this JWT as `MCP_SERVICE_TOKEN` on Render, then restart the service.

#### Step 6: Connect Claude.ai (Web)

1. Go to **Settings → Your Account → MCP Connectors** on [claude.ai](https://claude.ai)
2. Click **Add Custom Connector**
3. Configure:

| Setting | Value |
|---|---|
| **Name** | `Cinemax` |
| **URL** | `https://cinemax-mcp-server.onrender.com/mcp` |

4. Click **Advanced** and add a **Custom Header**:

| Header Name | Header Value |
|---|---|
| `x-api-key` | `cmax_your_api_key_here` (same as `CINEMAX_MCP_API_KEY`) |

5. Click **Save**. Claude will discover all 36 tools.

If Claude shows "no tools available", check:
- Render logs for startup errors
- Confirm `MCP_TRANSPORT=http` is set
- Ensure the JWT service token is valid and has the correct admin UUID

---

### 3. Troubleshooting

#### Database Error Code 28000

**Error:** `error: "An internal error occurred", code: "28000"`

**Cause:** The Node.js `pg` driver requires SSL for cloud databases like Neon.

**Fix:** Ensure `DATABASE_URL` has `?sslmode=require` at the end:
```
postgresql://cinemax_reader:password@host/db?sslmode=require
```

#### RLS Returns Empty Results

**Error:** `list_cinemas` returns zero rows even though data exists.

**Cause:** The `cinemax_reader` role has `NOBYPASSRLS`. When connecting directly via psql without setting session variables, RLS policies filter all rows.

**Fix:** The MCP server automatically sets `app.scope_role` and `app.current_hall_ids` session variables before each query. When running as superAdmin (single-key mode), RLS is bypassed and all rows are visible. Verify:
- `CINEMAX_MCP_API_KEY` is set correctly on Render
- `scopeResolver.js` returns `{ role: "superAdmin", hall_ids: [] }`

To test with psql:
```sql
SELECT set_config('app.scope_role', 'superAdmin', false);
SELECT * FROM cinema_hall;  -- should now return all rows
```

#### Hall Not Found or Access Denied (API tools)

**Error:** "Hall not found or access denied" from `list_bookings`, `get_dashboard_stats`, etc.

**Cause:** The JWT token (`MCP_SERVICE_TOKEN`) contains a wrong admin UUID that doesn't match the admin in the production database.

**Fix:** Generate a fresh JWT using the **production database's** admin UUID (see deployment Step 5 above).

#### API Returns "X-Hall-Id header is required"

**Cause:** The API endpoint requires the `X-Hall-Id` header to identify which hall the request is for.

**Fix:** This is handled automatically by the MCP server's `api/client.js`. If you see this error directly, the MCP server's scope resolver isn't associating a hall ID with the request. Ensure the tool handler passes `hall_ids` when creating the API client.

---

### 4. Architecture Summary

```
┌──────────────────┐     stdio/HTTP      ┌─────────────────────────┐     DB/API      ┌──────────────┐
│  AI Assistant    │ ──────────────────> │  cinemax-mcp-server     │ ─────────────> │  Cinemax     │
│  (Claude.ai,     │ <────────────────── │  (McpServer + 36 tools │ <───────────── │  API +       │
│   OpenCode,      │     MCP results     │   + RLS + scope auth)  │   SQL results  │  PostgreSQL  │
│   ChatGPT...)    │                     └─────────────────────────┘               └──────────────┘
```

**Authentication layers:**
1. **Client → MCP Server:** API key (`x-api-key` header or stdio env var) → resolves to scope `{role, hall_ids}`
2. **MCP Server → Backend API:** `MCP_SERVICE_TOKEN` JWT → authenticates as admin for REST proxy calls
3. **MCP Server → Database:** `cinemax_reader` PostgreSQL role with RLS → hall-scoped read-only access
