# Ads Management - Components

## Admin App Component Hierarchy

```
AdsManagement (page)
 ├── Tabs
 │    ├── Tab: "Analytics" → Table view
 │    │    └── Table: title, image_url, click_url, placement, status, dates, clicks, actions
 │    └── Tab: "Ads" → Card grid view
 │         └── AdCard → image preview, placement badge, status badge, date range, click count, edit/delete buttons
 ├── Create/Edit Sheet (slide-over)
 │    └── Form: title, image_url (with preview), click_url, placement (select), start_date, end_date, is_active toggle
 ├── Delete Confirmation Dialog
 └── Click-through Details Dialog
      └── Table: customer name, email, phone, clicked_at + export button
```

## Component Catalog

| Component | File | Props | State | Parent | Children |
|-----------|------|-------|-------|--------|----------|
| `AdsManagement` | `pages/AdsManagement.jsx` | - | ads[], loading, formOpen, editingAd, formData, formLoading, clicksOpen, clicksAd, clicks[], clicksLoading, deleteTarget, deleteLoading | Layout/Routes | Sheet (create/edit), Dialog (delete), Dialog (clicks), ExportButton, Tabs |

## User App Component Hierarchy

```
AdBanner
 ├── Carousel (embla-carousel + Autoplay)
 │    └── AdSlide → image, AD badge, click handler
 └── Dot pagination (if > 1 ad)
```

| Component | File | Props | State | Parent | Children |
|-----------|------|-------|-------|--------|----------|
| `AdBanner` | `components/AdBanner.jsx` | - | ads[], currentIndex, emblaApi | Layout (movies page) | CarouselContent, CarouselItem, dot buttons |

## State Management

### AdsManagement
- `ads[]` - Fetched from `adsAPI.getAll()` on mount
- `loading` - Loading state for initial fetch
- `formOpen` / `editingAd` / `formData` - Create/edit sheet state
- `clicksOpen` / `clicksAd` / `clicks[]` - Click details dialog state
- `deleteTarget` - Delete confirmation dialog state

### AdBanner
- `ads[]` - Fetched from `adsAPI.getActive('banner')` on mount
- `currentIndex` - Tracks active carousel slide for dot indicators
- `emblaApi` - Embla carousel instance for programmatic control
