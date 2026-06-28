# Workflows — Reports & Export

## 1. Admin loads dashboard

```
Admin browser                    API server                    PostgreSQL
    │                               │                             │
    ├── GET /api/dashboard/stats ───►                             │
    │                               ├── Par 1: today stats ──────►│
    │                               ├── Par 2: all-time totals ──►│
    │                               ├── Par 3: total customers ──►│
    │                               ├── Par 4: active offers ─────►│
    │                               ├── Par 5: screen count ──────►│
    │                               ├── Par 6: 7-day trend ──────►│
    │                               ├── Par 7: recent 5 bookings ─►│
    │                               ├── Par 8: today's shows ─────►│
    │                               ◄─── all 8 results ───────────┤
    │ ◄── JSON ─────────────────────┤                             │
    │                                                             │
    │ [Dashboard renders cards, chart, tables]                    │
```

All 8 queries run in parallel via `Promise.all` on a single `db.connect()` client instance. The client is released in the `finally` block.

## 2. Admin filters bookings

```
Admin browser                    API server                    PostgreSQL
    │                               │                             │
    ├── GET /api/booking/admin/all ──►                             │
    │   ?from_date=...              │                             │
    │   &to_date=...                │                             │
    │   &search=Avatar              ├── Query 1: data ───────────►│
    │   &status=confirmed           ├── Query 2: count ──────────►│
    │   &screen_id=...              ├── Query 3: stats ──────────►│
    │   &page=1                     │                             │
    │   &limit=10                   ◄─── 3 results ───────────────┤
    │ ◄── JSON (bookings + total + stats) ──┤                     │
```

All three queries (data, count, stats) use the same WHERE clause built from the query parameters. The `stats` object in the response gives admins filtered revenue/cgst/convenience_fee subtotals without a separate request.

## 3. Admin exports table data to CSV/Excel

```
Admin browser
    │
    ├── [clicks Export → "Export as Excel"]
    │
    ├── exportToExcel(dataRows, "bookings-report")
    │   │
    │   ├── XLSX.utils.json_to_sheet(dataRows)
    │   ├── XLSX.utils.book_new()
    │   ├── XLSX.utils.book_append_sheet(workbook, sheet)
    │   └── XLSX.writeFile(workbook, "bookings-report.xlsx")
    │
    └── Browser downloads .xlsx file
```

The export runs entirely on the client side — no API call is made. All data must already be present in the component's state/array passed to `ExportButton`.

## 4. Admin views refunds

```
Admin browser                    API server                    PostgreSQL
    │                               │                             │
    ├── GET /api/refunds ───────────►                             │
    │   ?status=settled              ├── Dynamic WHERE builder ──►│
    │   &from_date=2025-01-01        │   (parameterized queries)  │
    │   &page=1                      ├── Query 1: refund data ───►│
    │                                ├── Query 2: count ─────────►│
    │                                ◄─── 2 results ──────────────┤
    │ ◄── JSON (refunds + total) ───┤                             │
```

## 5. Admin manually settles a refund

```
Admin browser                    API server                    PostgreSQL
    │                               │                             │
    ├── POST /api/refunds/:id/settle►                             │
    │                               ├── Verify ownership ────────►│
    │                               ├── Check not already settled►│
    │                               ├── UPDATE refunds SET ──────►│
    │                               │   refund_status='settled',  │
    │                               │   settled_at=NOW()          │
    │ ◄── 200 { message: "..." } ───┤                             │
```

This is used when Razorpay's webhook was missed or in test/offline scenarios.
