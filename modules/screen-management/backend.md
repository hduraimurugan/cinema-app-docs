# Backend — Screen Management

## Controller: `controllers/screens.Controller.js`

All functions receive `req.currentHallId` from the `requireActiveHall` middleware, injected before the controller runs.

### `createScreen`

**Purpose:** Creates a new screen in the active cinema hall.

**Input (req.body):**
| Field          | Type    | Notes                            |
| -------------- | ------- | -------------------------------- |
| `name`         | String  | Screen name                      |
| `total_seats`  | Integer | Total capacity                   |
| `premium_seats`| Integer | Count of premium tier seats       |
| `gold_seats`   | Integer | Count of gold tier seats          |
| `silver_seats` | Integer | Count of silver tier seats        |
| `premium_price`| Decimal | Price per premium seat            |
| `gold_price`   | Decimal | Price per gold seat               |
| `silver_price` | Decimal | Price per silver seat             |
| `rows`         | Integer | Number of rows in layout          |
| `columns`      | Integer | Number of columns in layout       |
| `screen_position` | Integer| Screen position index (1, 2, …) |
| `layout`       | Object  | JSON seat map (see [Database](database.md)) |

**SQL:** `INSERT INTO screens (...) VALUES ($1, $2, ...)`

**Returns:** The created screen object.

---

### `editScreen`

**Purpose:** Updates an existing screen identified by `:screenId` route parameter.

**Security:** Verifies `screen.cinema_hall_id === req.currentHallId` before updating.

**Input:** Same fields as `createScreen` (all optional — dynamic SET clause).

**SQL:** Builds a `UPDATE screens SET col1=$1, col2=$2, ... WHERE id=$n` dynamically.

**Special handling:** The `layout` field is JSON-serialized before storage.

**Returns:** The updated screen object.

---

### `deleteScreen`

**Purpose:** Soft/hard deletes a screen by `:screenId`.

**Security:** Same hall ownership check as `editScreen`.

**SQL:** `DELETE FROM screens WHERE id = $1 AND cinema_hall_id = $2`

**Returns:** Success confirmation.

---

### `getMyScreens`

**Purpose:** Lists all screens belonging to the active hall.

**SQL:** `SELECT * FROM screens WHERE cinema_hall_id = $1 ORDER BY created_at DESC`

**Returns:** Array of screen objects with full seat/pricing/layout data.

## Routes: `routes/screens.routes.js`

All routes are protected by two middlewares applied in sequence:

1. `verifyCinemaAdminAccessToken` — JWT auth for cinema admin users
2. `requireActiveHall` — injects `req.currentHallId` from the admin's session/header

| Method | Path                       | Handler       | Description |
| ------ | -------------------------- | ------------- | ----------- |
| POST   | `/api/screens/create`      | `createScreen`| Create screen |
| PUT    | `/api/screens/update/:screenId` | `editScreen` | Update screen |
| DELETE | `/api/screens/delete/:screenId` | `deleteScreen` | Delete screen |
| GET    | `/api/screens`             | `getMyScreens`| List screens |

## Middleware Dependency

- `verifyCinemaAdminAccessToken` — ensures the request comes from an authenticated cinema admin
- `requireActiveHall` — ensures the admin has selected an active hall; sets `req.currentHallId`

Without `requireActiveHall`, all screen endpoints return a 400/401 error.
