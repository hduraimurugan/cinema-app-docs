# Database — Screen Management

## Table: `screens`

| Column            | Type          | Constraints                    | Notes                               |
| ----------------- | ------------- | ------------------------------ | ----------------------------------- |
| `id`              | UUID          | PRIMARY KEY, DEFAULT gen_random_uuid() | Auto-generated             |
| `cinema_hall_id`  | UUID          | NOT NULL, FK → cinema_hall(id) | Hall ownership                      |
| `name`            | VARCHAR       | NOT NULL                       | Screen display name                 |
| `total_seats`     | INTEGER       | NOT NULL                       | Total seating capacity               |
| `premium_seats`   | INTEGER       | NOT NULL, DEFAULT 0            | Count of premium tier seats          |
| `gold_seats`      | INTEGER       | NOT NULL, DEFAULT 0            | Count of gold tier seats             |
| `silver_seats`    | INTEGER       | NOT NULL, DEFAULT 0            | Count of silver tier seats           |
| `premium_price`   | DECIMAL(10,2) | NOT NULL, DEFAULT 0.00         | Price per premium seat               |
| `gold_price`      | DECIMAL(10,2) | NOT NULL, DEFAULT 0.00         | Price per gold seat                  |
| `silver_price`    | DECIMAL(10,2) | NOT NULL, DEFAULT 0.00         | Price per silver seat                |
| `rows`            | INTEGER       | NOT NULL                       | Number of rows in seat layout        |
| `columns`         | INTEGER       | NOT NULL                       | Number of columns in seat layout     |
| `screen_position` | INTEGER       | NOT NULL                       | Screen position index (ordering)     |
| `layout`          | JSONB         | NOT NULL, DEFAULT '{}'         | Seat map (see schema below)          |
| `created_at`      | TIMESTAMPTZ   | NOT NULL, DEFAULT NOW()        | Creation timestamp                   |
| `updated_at`      | TIMESTAMPTZ   | NOT NULL, DEFAULT NOW()        | Last update timestamp                |

## Indexes

- Primary key on `id`
- Foreign key index on `cinema_hall_id` (implicit via FK constraint)
- Recommended: `CREATE INDEX idx_screens_hall ON screens(cinema_hall_id);`

## Layout JSONB Schema

The `layout` column stores a JSON object with a `seats` array:

```json
{
  "seats": [
    {
      "id": "uuid-or-unique-key",
      "row": "A",
      "column": 1,
      "type": "seat",
      "isBlocked": false,
      "priceCategory": "premium"
    }
  ]
}
```

### Seat Object Fields

| Field           | Type    | Values                    | Description                       |
| --------------- | ------- | ------------------------- | --------------------------------- |
| `id`            | String  | Unique identifier         | Client-generated or UUID          |
| `row`           | String  | A–Z (single letter)       | Row label                         |
| `column`        | Integer | 1–N                       | Column number                     |
| `type`          | String  | `"seat"` / `"passage"`    | Seat or aisle/passage             |
| `isBlocked`     | Boolean | `true` / `false`          | Blocked = unavailable seat        |
| `priceCategory` | String  | `"premium"` / `"gold"` / `"silver"` | Pricing tier            |

### Rules

- `type: "passage"` objects represent aisles — they have `isBlocked: true` implicitly
- The sum of `premium_seats` + `gold_seats` + `silver_seats` should equal `total_seats`
- `priceCategory` must match one of the three tier columns on the screen row
- `row` + `column` uniqueness within a layout is enforced at the application level

## Foreign Key Relationship

```
screens.cinema_hall_id  →  cinema_hall.id
       │
       │  (hall scoping via requireActiveHall)
       ▼
  All screen queries filter by cinema_hall_id = $1
```
