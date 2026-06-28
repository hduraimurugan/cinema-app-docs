# Frontend — Reports & Export

## Components

### ExportButton.jsx

**Path:** `cinema-hall-admin/src/components/ExportButton.jsx`

A reusable `<ExportButton>` component that renders a dropdown trigger with two export options: CSV and Excel. It uses shadcn/ui `Button` and `DropdownMenu` primitives and calls utility functions from `exportUtils`.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `data` | `Object[]` | `[]` | Array of flat objects. Object keys become column headers in the export file. |
| `filename` | `string` | `'export'` | Base filename (without extension). Output becomes `<filename>.csv` or `<filename>.xlsx`. |
| `disabled` | `boolean` | `false` | Disables the button when set, e.g. while data is loading. |

**Behavior:**
- The button is disabled when `disabled` is true or `data` is empty.
- Clicking the trigger opens a dropdown menu with "Export as CSV" and "Export as Excel" items.
- Each menu item calls the corresponding utility from `exportUtils` on click.

**Usage example:**

```jsx
import { ExportButton } from '@/components/ExportButton'

function BookingTable({ rows }) {
  return (
    <div className="flex items-center gap-2">
      <h2>Bookings</h2>
      <ExportButton data={rows} filename="bookings-2025-01" />
    </div>
  )
}
```

## Utilities

### exportUtils.js

**Path:** `cinema-hall-admin/src/utils/exportUtils.js`

Two exported functions that generate and trigger browser downloads of tabular data.

#### `exportToCSV(data, filename)`

Creates a CSV string from `data`, wraps values containing commas/quotes/newlines in double-quotes, creates a Blob, and triggers a download via a temporary anchor element.

- **Columns:** Determined from `Object.keys(data[0])` (first object's keys).
- **Escaping:** Double-quotes inside values are doubled (`"` → `""`); values containing `,`, `"`, `\n`, or `\r` are wrapped in quotes.
- **Output filename:** `<filename>.csv`

#### `exportToExcel(data, filename)`

Uses the `xlsx` npm package to build a workbook from `data` and trigger a download.

- Calls `XLSX.utils.json_to_sheet(data)` to create a worksheet.
- Calls `XLSX.utils.book_new()` + `XLSX.utils.book_append_sheet()` to build the workbook.
- Calls `XLSX.writeFile(workbook, '<filename>.xlsx')` to trigger the download.
- **Output filename:** `<filename>.xlsx`

#### Guard clause

Both functions return early (no-op) if `data` is empty or `null`.

## Dependencies

- `xlsx` (npm) — used by `exportToExcel` for XLSX generation
- `lucide-react` — icons (`Download`, `FileSpreadsheet`, `FileText`)
- shadcn/ui components — `Button`, `DropdownMenu`, `DropdownMenuContent`, `DropdownMenuItem`, `DropdownMenuTrigger`
