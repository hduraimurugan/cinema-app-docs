# Test Suite Documentation

The Cinema Hall API has a comprehensive test suite with **352 tests across 30 test files — all passing**.

## Test Runner & Tooling

- **Test Runner**: [Vitest](https://vitest.dev/) v4 — fast unit test framework powered by Vite
- **HTTP Testing**: [Supertest](https://github.com/ladjs/supertest) for integration tests
- **Coverage**: [@vitest/coverage-v8](https://www.npmjs.com/package/@vitest/coverage-v8)

## Quick Start

```bash
# Navigate to API directory
cd cinema-hall-api

# Interactive watch mode
npm test

# Single run (CI-friendly)
npm run test:run

# With coverage report
npm run test:coverage

# Run a single test file
npx vitest run tests/unit/controllers/booking.test.js
```

## Test Infrastructure

### Database

Dedicated test PostgreSQL database: `cinema_hall_test`

```
postgresql://postgres:Durai@1234@localhost:5432/cinema_hall_test
```

| File | Role |
|------|------|
| `tests/setup/env.js` | Sets `NODE_ENV=test`, test DB URL, fake API keys |
| `tests/setup/globalSetup.js` | Drops all tables, runs consolidated `schema.sql` (20+ tables) |
| `tests/setup/globalTeardown.js` | Cleanup after all tests |
| `tests/setup/schema.sql` | Consolidated schema with all migration columns |
| `tests/setup/db.js` | `getPool()`, `query()`, `getClient()`, `cleanupAll()`, `closePool()` |

### Factories

`tests/setup/factories.js` provides 11 factory functions for inserting test data:

| Factory | Table | Notes |
|---------|-------|-------|
| `createAdmin()` | `cinema_admin_user` | Unique email via Date.now() + random suffix |
| `createSuperAdmin()` | `cinema_admin_user` | Role: superAdmin |
| `createHall(adminId)` | `cinema_hall` | Includes district, state |
| `createScreen(hallId)` | `screens` | Layout as JSON string |
| `createMovie()` | `movies` | Genre/language as text[] |
| `createShow(screenId, movieId)` | `shows` | Future date, overlap-checked |
| `createCustomer()` | `customers` | Unique email |
| `createBooking(customerId, showId)` | `bookings` | Optional overrides |
| `createPaymentOrder(showId, customerId)` | `payment_orders` | Seeds order_id, seats |
| `createSetting(key, value)` | `settings` | Upsert via ON CONFLICT |
| `createOffer(hallId, adminId)` | `offers` | Auto-generated code |

### Mocks

`tests/mocks/` provides mock factories for external services:

| File | Service | What It Replaces |
|------|---------|-----------------|
| `razorpay.js` | Razorpay | `orders.create`, `orders.fetch`, `payments.fetch`, `payments.refund` |
| `oauth.js` | OAuth | `verifyGoogleToken`, `exchangeGithubCode`, `getGithubUser` |
| `email.js` | Nodemailer | `createTransport`, `sendMail` |

## Test Strategy by Layer

| Layer | Approach | DB |
|-------|----------|-----|
| **Utils** | Pure function tests, mock `db.js` via `vi.mock` | ❌ |
| **Middleware** | Mock `db.js`, test each function's decision paths | ❌ |
| **Controllers** | Real test DB via `tests/setup/db.js` | ✅ |
| **Integration** | Real test DB + Supertest | ✅ |

External services (Razorpay, Nodemailer, OAuth, TMDB) are mocked in all layers.

## Test Breakdown by Phase

| Phase | Description | Tests | Status |
|-------|-------------|-------|--------|
| 1 | Infrastructure (vitest, DB, schema, factories, mocks) | — | ✅ |
| 2 | Utils (hashToken 5, passwordPolicy 12, oauthRateLimit 6) | **23/23** | ✅ |
| 3 | Middleware (verifyCinemaAdmin — 8 exports) | **30/30** | ✅ |
| 4A | Simple controllers (settings 7, halls 10, ads 11, customers 5, screens 7, refund 7) | **47/47** | ✅ |
| 4B | Medium controllers (movies 19, offers 13, userMovies 18, dashboard 7, tmdb 10, otp 9) | **76/76** | ✅ |
| 4C | Auth controllers (auth 45, customerAuth 23) | **68/68** | ✅ |
| 4D | Complex controllers (booking 16, shows 19, payment 10) | **45/45** | ✅ |
| 5 | Integration (full request-response via Supertest) | **7/7** | ✅ |
| 6 | Edge case & concurrency (booking/concurrency 3, booking/edge 7, shows/edge 14, payment/edge 5) | **29/29** | ✅ |
| 7 | Coverage tuning (offers-coverage 13, shows-coverage 6, booking-coverage 5) | **24/24** | ✅ |

## Coverage

```
         | % Stmts | % Branch | % Funcs | % Lines
---------|---------|----------|---------|---------
Overall  |   77.54 |    69.43 |    86.8 |   78.69
controllers | 76.51 |    68.23 |   87.86 |   77.71
middleware  |  92.1 |    95.65 |   76.92 |    92.1
utils       | 90.38 |    76.92 |   81.81 |   90.38
```

Thresholds enforced in CI: Statements ≥75%, Branches ≥65%, Functions ≥80%, Lines ≥75%.

## Key Test Patterns

### Controller Test (Real DB)

```js
import { getPool } from '../../setup/db.js'
import { createAdmin } from '../../setup/factories.js'
vi.mock('../../../utils/logger.js', () => ({ default: { info: vi.fn(), error: vi.fn() } }))

import { getMyHalls } from '../../../controllers/halls.Controller.js'

function mockReqRes(overrides = {}) {
  const req = { body: {}, params: {}, query: {}, admin: { id: 'none' }, ...overrides }
  const res = { status: vi.fn().mockReturnThis(), json: vi.fn().mockReturnThis() }
  return { req, res }
}
```

### Concurrency Test

```js
const results = await Promise.allSettled([
  (async () => { /* customer A */ })(),
  (async () => { /* customer B */ })(),
])
const successes = results.filter(r => r.status === 'fulfilled' && r.value.status === 200)
expect(successes.length).toBe(1)
```

## Adding New Tests

1. Create file in `tests/unit/controllers/`, `tests/unit/middleware/`, `tests/unit/utils/`, or `tests/integration/`
2. For controller tests: import `getPool`, use factories, mock logger
3. For integration tests: mock middleware before importing `app`, use Supertest
4. Run in isolation first: `npx vitest run tests/unit/controllers/my-test.test.js`
5. Run full suite before committing: `npm run test:run`

### Cleanup Rules

- Each `afterEach` cleans only the tables touched by that test file
- Factory-created data in `beforeAll` is preserved across tests in the same file
- The global teardown drops all tables after the full run completes

## Detailed Test Case Reference

For a complete per-file, per-test breakdown of all 352 test cases with inputs, expectations, and scenarios covered, see:

> **[`cinema-hall-api/Test_Cases.md`](../cinema-hall-api/Test_Cases.md)** — Full test case catalog

## Known Issues

1. **`requireActiveHall` middleware**: `pool.connect()` called outside try-catch — unhandled rejection on connection failure
2. **Controller `res.status` pattern**: Many controllers call `res.json()` without explicit `res.status(200)`, relying on Express default 200
3. **`movies.Controller.js` missing `logger` import**: `logger.error()` in catch blocks throws `ReferenceError`
4. **Auth test password mutation**: Tests that modify the shared admin's password mutate state for subsequent tests
