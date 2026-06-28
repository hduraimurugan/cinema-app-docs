# Hall Management - API

## Hall Endpoints

### GET `/api/halls`
- **Description**: List all halls accessible to the authenticated admin
- **Auth**: `verifyCinemaAdminAccessToken`
- **Scoping**: SuperAdmin → org-scoped (own organization). Owner/Admin → all halls in org. Staff → halls via `hall_assignments` JOIN.
- **Success (200)**: `{ halls: [{ id, name, location, district, state, latitude, longitude, phone, description, is_active, created_at, org_id }] }`
- **Errors**: 500

### POST `/api/halls`
- **Description**: Create a new cinema hall
- **Auth**: `verifyCinemaAdminAccessToken`
- **Body**:
  ```json
  {
    "name": "PVR Cinemas Phoenix",
    "location": "Phoenix Marketcity, Velachery",
    "district": "Chennai",
    "state": "Tamil Nadu",
    "latitude": 12.9916,
    "longitude": 80.2193,
    "phone": "9876543210",
    "description": "Multiplex with 6 screens"
  }
  ```
- **Required fields**: `name`, `location`, `district`, `state`
- **Optional fields**: `latitude`, `longitude`, `phone`, `description`
- **Success (201)**: `{ hall: { id, name, location, district, state, latitude, longitude, phone, description, is_active, created_at, org_id } }`
- **Errors**: 400 (missing required fields or no organization), 500

### PUT `/api/halls/:id`
- **Description**: Update hall fields (partial update via COALESCE)
- **Auth**: `verifyCinemaAdminAccessToken`
- **Access**: SuperAdmin (bypass), Owner/Admin (same org), or hall admin_id match
- **Body**: Any subset of hall fields (same schema as POST, plus `is_active`)
- **Success (200)**: `{ hall: { ...updated fields } }`
- **Errors**: 403 (not found or access denied), 500

### DELETE `/api/halls/:id`
- **Description**: Permanently delete a hall and all cascaded data (screens, shows, bookings)
- **Auth**: `verifyCinemaAdminAccessToken`
- **Access**: Same as PUT (SuperAdmin bypass, Owner/Admin same org, or admin_id match)
- **Success (200)**: `{ message: "Hall deleted successfully" }`
- **Errors**: 403 (not found or access denied), 500
