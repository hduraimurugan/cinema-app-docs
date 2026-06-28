# Ads Management Module

## Module Purpose
Manage advertisements across the cinema platform with date-range scheduling, placement targeting, and click-through tracking.

## Business Objective
Provide cinema operators a self-service ad management system to create, schedule, and monitor ad campaigns across placements (banner, sidebar, popup), with detailed click analytics and customer attribution.

## Features
- **Ad CRUD**: Create, read, update, and delete ads with full metadata
- **Date-range Scheduling**: Ads automatically activate/deactivate based on start_date/end_date
- **Placement Targeting**: Assign ads to placements (banner, sidebar, popup) for different UI slots
- **Active Ad Delivery**: Public API serves only active, in-range ads per placement
- **Click Tracking**: Record ad clicks with optional customer identification (via auth cookie)
- **Click Analytics**: Admin dashboard with per-ad click count + per-click customer details
- **Export**: Export ad performance data and click details to CSV

## User Roles Involved
- **Super Admin**: Full CRUD, view click analytics, manage all ads
- **Customer**: View ads on platform, click-through to offer URLs (anonymous if not logged in)

## Dependencies
- **PostgreSQL**: Ads and ad_clicks tables with FK relationships
- **JWT**: Customer identity extraction from cusAccessToken cookie for click attribution
- **Express**: Backend API routes with super admin middleware

## Related Modules
- [Authentication](../authentication/README.md) - Customer auth for click attribution via cookie
- [Show Management](../show-management/README.md) - Ads display alongside show listings
