# Ads Management - File Reference

## Admin App (`cinema-hall-admin`)

| File Path | Purpose | Key Imports | Exports |
|-----------|---------|-------------|---------|
| `src/pages/AdsManagement.jsx` | Full ad management page with card grid, analytics table, create/edit sheet, click details dialog, delete confirmation | adsAPI, shadcn/ui (Sheet, Dialog, Tabs, Button), lucide-react (Megaphone, Plus, Pencil, Trash2, MousePointerClick, etc.), sonner, ExportButton | `AdsManagement` |
| `src/services/api.js` (adsAPI section, line 740) | API client for ad CRUD and click analytics | fetch | `adsAPI` (getAll, create, update, delete, getClicks) |

## User App (`cinema-hall-users`)

| File Path | Purpose | Key Imports | Exports |
|-----------|---------|-------------|---------|
| `src/components/AdBanner.jsx` | Auto-rotating ad carousel with click tracking and dot navigation | React, embla-carousel-autoplay, shadcn/ui Carousel, adsAPI | `AdBanner` |
| `src/services/api.js` (adsAPI section, line 436) | API client for active ad fetching and click recording | fetch | `adsAPI` (getActive, recordClick) |

## Backend API (`cinema-hall-api`)

| File Path | Purpose | Key Imports | Exports |
|-----------|---------|-------------|---------|
| `routes/ads.routes.js` | Ad route definitions (admin + public) | ads.Controller, verifySuperAdmin, express.Router | `router` |
| `controllers/ads.Controller.js` | All ad logic: CRUD, active filtering, click recording with optional auth | pool, jsonwebtoken, logger | `getAllAds`, `createAd`, `updateAd`, `deleteAd`, `getAdClicks`, `getActiveAds`, `recordClick` |

## Database

| Object | Type | Purpose |
|--------|------|---------|
| `ads` | Table | Ad campaigns with title, image, placement, date range, active flag |
| `ad_clicks` | Table | Click-through records with optional customer attribution |
| `ad_clicks.ad_id` | FK → ads(id) | References parent ad (cascade delete) |
| `ad_clicks.customer_id` | FK → customers(id) | References customer for attribution (nullable) |
