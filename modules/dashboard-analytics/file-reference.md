# File Reference — Dashboard & Analytics

## Backend Files

### `cinema-hall-api/controllers/dashboard.Controller.js`

| | |
|---|---|
| **Role** | Dashboard data aggregation controller |
| **Exports** | `getDashboardStats` (single handler) |
| **Dependencies** | `pool` (database), `Promise.all` for parallel queries |
| **Auth** | Requires `verifyCinemaAdminAccessToken` + `requireActiveHall` |
| **Error handling** | `try/catch`, returns 500 on failure |
| **Key logic** | Runs 8 SQL queries in parallel, constructs unified response |

### `cinema-hall-api/routes/dashboard.routes.js`

| | |
|---|---|
| **Role** | Route definition |
| **Endpoint** | `GET /api/dashboard/stats` |
| **Middleware** | `verifyCinemaAdminAccessToken`, `requireActiveHall` |
| **Handler** | `getDashboardStats` (imported from controller) |

## Frontend Files

### `src/pages/HomePage.jsx`

| | |
|---|---|
| **Role** | Main dashboard page (admin landing page) |
| **Route** | `/` |
| **State** | `stats` object (local state via `useState`) |
| **Data fetch** | `useEffect(() => { getStats().then(...) }, [])` |
| **Sub-sections** | Stat cards, revenue chart, recent bookings table, today's shows table |
| **Libraries** | Recharts for charting |

### `src/services/api.js`

| | |
|---|---|
| **Role** | API service layer |
| **Export** | `getStats: () => api.get('/dashboard/stats')` |
| **Base URL** | Configured via axios instance (`api`) |
| **Auth** | Axios interceptor attaches JWT token automatically |

## Documentation Files

| File | Location |
|------|----------|
| `README.md` | `docs/modules/dashboard-analytics/README.md` |
| `frontend.md` | `docs/modules/dashboard-analytics/frontend.md` |
| `backend.md` | `docs/modules/dashboard-analytics/backend.md` |
| `database.md` | `docs/modules/dashboard-analytics/database.md` |
| `api.md` | `docs/modules/dashboard-analytics/api.md` |
| `components.md` | `docs/modules/dashboard-analytics/components.md` |
| `workflows.md` | `docs/modules/dashboard-analytics/workflows.md` |
| `file-reference.md` | `docs/modules/dashboard-analytics/file-reference.md` |

## Summary

| Layer | Files | Total |
|-------|-------|-------|
| Controllers | `dashboard.Controller.js` | 1 |
| Routes | `dashboard.routes.js` | 1 |
| Pages | `HomePage.jsx` | 1 |
| Services | `api.js` (partial — contains `getStats`) | 1 |
| Docs | `README.md`, `frontend.md`, `backend.md`, `database.md`, `api.md`, `components.md`, `workflows.md`, `file-reference.md` | 8 |
| **Total** | | **12 files** |
