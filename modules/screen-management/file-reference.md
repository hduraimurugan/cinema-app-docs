# File Reference — Screen Management

## Backend Files

### `cinema-hall-api/controllers/screens.Controller.js`

The single controller file with all four screen operations.

| Export          | Signature                                          | Description                   |
| --------------- | -------------------------------------------------- | ----------------------------- |
| `createScreen`  | `(req, res) => { ... }`                            | INSERT a new screen           |
| `editScreen`    | `(req, res) => { ... }`                            | Dynamic UPDATE by screenId    |
| `deleteScreen`  | `(req, res) => { ... }`                            | DELETE by screenId            |
| `getMyScreens`  | `(req, res) => { ... }`                            | SELECT * WHERE hall_id = $1   |

**Dependencies:**
- `db` (PostgreSQL pool) — from project database module
- `req.currentHallId` — injected by `requireActiveHall` middleware
- `JSON.stringify()` — for layout serialization in `editScreen`

---

### `cinema-hall-api/routes/screens.routes.js`

Route definitions for screen endpoints.

```javascript
const router = require("express").Router();
const {
  createScreen,
  editScreen,
  deleteScreen,
  getMyScreens,
} = require("../controllers/screens.Controller");
const {
  verifyCinemaAdminAccessToken,
  requireActiveHall,
} = require("../middleware/auth");

router.post(
  "/screens/create",
  verifyCinemaAdminAccessToken,
  requireActiveHall,
  createScreen
);
router.put(
  "/screens/update/:screenId",
  verifyCinemaAdminAccessToken,
  requireActiveHall,
  editScreen
);
router.delete(
  "/screens/delete/:screenId",
  verifyCinemaAdminAccessToken,
  requireActiveHall,
  deleteScreen
);
router.get(
  "/screens",
  verifyCinemaAdminAccessToken,
  requireActiveHall,
  getMyScreens
);

module.exports = router;
```

**Mounted at:** `/api` (app-level prefix)

---

## Frontend Files

### `src/pages/CinemaScreens.jsx`

The screen list and CRUD page.

| Aspect           | Details                                    |
| ---------------- | ------------------------------------------ |
| Route            | `/admin/screens`                           |
| State            | `screens`, `loading`, `editingScreen`, `showCreateForm` |
| API calls        | `screensAPI.getMyScreens()`, `createScreen()`, `updateScreen()`, `deleteScreen()` |
| Key behavior     | Refetches after every CUD operation         |

**Exports:**
- Default: `CinemaScreens` component
- May export child components: `ScreenTable`, `ScreenRow`, `CreateScreenForm`, `EditScreenForm`

---

### `src/pages/ScreenDesignerPage.jsx`

The visual seat layout designer.

| Aspect           | Details                                    |
| ---------------- | ------------------------------------------ |
| Route            | `/admin/screens/designer/:screenId?`       |
| State            | `layout`, `selectedSeat`, `seatCounts`, `gridSize` |
| Key behavior     | Generates layout JSON, syncs seat counts to form |

---

### `src/services/api.js`

API client wrapper (shared module).

```javascript
export const screensAPI = {
  createScreen: (data) => hallFetch.post("/screens/create", data),
  getMyScreens: () => hallFetch.get("/screens"),
  updateScreen: (screenId, data) =>
    hallFetch.put(`/screens/update/${screenId}`, data),
  deleteScreen: (screenId) =>
    hallFetch.delete(`/screens/delete/${screenId}`),
};
```

`hallFetch` is a configured axios/fetch instance that automatically attaches the `X-Hall-Id` header from React context or localStorage.

---

## Database Files

### Migration File (naming convention)

Expected migration filename pattern: `YYYYMMDDHHMMSS_create_screens_table.sql` or similar.

**Contents** (expected):
```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE screens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cinema_hall_id UUID NOT NULL REFERENCES cinema_hall(id) ON DELETE CASCADE,
  name VARCHAR NOT NULL,
  total_seats INTEGER NOT NULL,
  premium_seats INTEGER NOT NULL DEFAULT 0,
  gold_seats INTEGER NOT NULL DEFAULT 0,
  silver_seats INTEGER NOT NULL DEFAULT 0,
  premium_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  gold_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  silver_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  rows INTEGER NOT NULL,
  columns INTEGER NOT NULL,
  screen_position INTEGER NOT NULL,
  layout JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_screens_hall ON screens(cinema_hall_id);
```

---

## Middleware / Config Files

### Middleware: `verifyCinemaAdminAccessToken`

| Location | Cinema Hall API auth middleware |
| -------- | ------------------------------- |
| Purpose  | Verifies JWT, attaches admin user to `req.admin` |

### Middleware: `requireActiveHall`

| Location | Cinema Hall API auth middleware |
| -------- | ------------------------------- |
| Purpose  | Reads `X-Hall-Id` header or session, sets `req.currentHallId` |

---

## Summary Table

| # | File Path | Role | Key Exports/Functions |
|---| --------- | ---- | --------------------- |
| 1 | `cinema-hall-api/controllers/screens.Controller.js` | Business logic | `createScreen`, `editScreen`, `deleteScreen`, `getMyScreens` |
| 2 | `cinema-hall-api/routes/screens.routes.js` | Route definitions | Express router with 4 endpoints |
| 3 | `src/pages/CinemaScreens.jsx` | Screen list page | `CinemaScreens` (default) |
| 4 | `src/pages/ScreenDesignerPage.jsx` | Visual layout designer | `ScreenDesignerPage` (default) |
| 5 | `src/services/api.js` | API client | `screensAPI` object |
| 6 | Database migration | Schema creation | `CREATE TABLE screens (...)` |
| 7 | Auth middleware | JWT + hall validation | `verifyCinemaAdminAccessToken`, `requireActiveHall` |
