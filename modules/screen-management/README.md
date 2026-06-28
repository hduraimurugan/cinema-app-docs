# Screen Management Module

Manages cinema screens within a hall, including CRUD operations and a visual seat layout designer. Each screen has configurable seating tiers (premium, gold, silver), pricing, and a JSONB seat map.

## Module Overview

| Aspect            | Details                                  |
| ----------------- | ---------------------------------------- |
| **Purpose**       | Create, edit, delete, and list screens   |
| **Scope**         | Hall-scoped via `requireActiveHall`      |
| **Frontend**      | Admin panel with list + visual designer   |
| **Backend**       | RESTful API, PostgreSQL persistence       |
| **Layout Format** | JSONB `seats[]` — row/column grid         |

## Architecture

```
┌─────────────────┐     ┌───────────────────┐     ┌──────────────┐
│  Admin Frontend  │────▶│  screens.Controller│────▶│  PostgreSQL  │
│  (React)         │◀────│  (Express routes)  │◀────│  (screens)   │
└─────────────────┘     └───────────────────┘     └──────────────┘
```

## Core Concepts

- **Screens are hall-scoped** — every screen belongs to one cinema hall. The `requireActiveHall` middleware injects `req.currentHallId` into all screen routes.
- **Ownership enforcement** — every mutation verifies the screen's `cinema_hall_id` matches the active hall, preventing cross-hall access.
- **Seat Layout** — a JSONB column stores the visual seat map as an array of seat objects. Each seat has a row (letter), column (number), type (`seat` or `passage`), block state, and price category.
- **Pricing Tiers** — three tiers (premium, gold, silver) each with a decimal price stored on the screen record.

## Key Files

| File | Description |
| ---- | ----------- |
| `controllers/screens.Controller.js` | Business logic for screen CRUD |
| `routes/screens.routes.js` | Express route definitions |
| `src/pages/CinemaScreens.jsx` | Screen list and CRUD UI |
| `src/pages/ScreenDesignerPage.jsx` | Visual seat layout designer |

## Quick Reference

| Action          | API Endpoint                     | Method |
| --------------- | -------------------------------- | ------ |
| List screens    | `/api/screens`                   | GET    |
| Create screen   | `/api/screens/create`            | POST   |
| Update screen   | `/api/screens/update/:screenId`  | PUT    |
| Delete screen   | `/api/screens/delete/:screenId`  | DELETE |

## Related Docs

- [Frontend](frontend.md)
- [Backend](backend.md)
- [Database](database.md)
- [API](api.md)
- [Components](components.md)
- [Workflows](workflows.md)
- [File Reference](file-reference.md)
