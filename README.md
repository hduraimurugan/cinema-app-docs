# Cinema Hall Ticket Booking App - Documentation

Welcome to the comprehensive documentation for the Cinema Hall Ticket Booking application!

## 📚 Documentation Files

This folder contains complete documentation for all components of the application. See [index.md](./index.md) for a quick reference to all files.

### 1. [Backend API Documentation](./backend.md)

**What's inside:**

- Complete database schema with ER diagram
- All API endpoints (30+ endpoints across 7 modules)
- Authentication flows (Admin & Customer with OTP)
- Middleware and security features
- Request/response examples
- Deployment configuration

**Start here if you're:**

- Setting up the backend
- Integrating with the API
- Understanding the database structure

---

### 2. [Admin Panel Documentation](./admin.md)

**What's inside:**

- Complete feature documentation
- Movie Management (SuperAdmin only)
- Interactive Screen Designer with seat layout
- Shows Management with scheduling
- Component architecture
- User workflows and diagrams

**Start here if you're:**

- Working on the admin frontend
- Understanding cinema management features
- Building new admin features

---

### 3. [Database Setup Script](./db_setup.sql)

**What's inside:**

- Full idempotent schema: all 16 tables, indexes, triggers, seed data
- Works on both local PostgreSQL and Neon (paste into pgAdmin or Neon SQL Editor)
- Fixes ordering bugs in the original `psql.sql` (FK dependencies, missing `role` column, missing UNIQUE on `otp_verifications.email`)
- Commented superAdmin INSERT template at the bottom

**Start here if you're:**

- Setting up a fresh local development database
- Syncing a new Neon project with the current schema
- Onboarding to the project

---

### 4. [User Application Documentation](./users.md)

**What's inside:**

- Customer authentication with OTP
- Movie browsing with location filtering
- Component architecture
- User workflows
- API integration examples

**Start here if you're:**

- Working on the user frontend
- Understanding customer features
- Building booking features

---

## 🎨 Visual Diagrams

All documentation includes **34 Mermaid diagrams** for visual representation:

- **Sequence Diagrams** - Authentication flows, API requests
- **Flowcharts** - Feature logic, user workflows
- **State Diagrams** - Process states, modal flows
- **ER Diagrams** - Database schema
- **Graph Diagrams** - Architecture, component hierarchy

### Viewing Diagrams

**Option 1: VS Code**

1. Install "Markdown Preview Mermaid Support" extension
2. Open any `.md` file
3. Press `Ctrl+Shift+V` (preview)

**Option 2: GitHub**

- Push to GitHub and view directly (Mermaid renders automatically)

**Option 3: Online**

- Visit https://mermaid.live/ and paste diagram code

---

## 🚀 Quick Start Guide

### For New Developers

1. **Read [backend.md](./backend.md)** - Understand the API and database
2. **Review authentication flows** - See how login/signup works
3. **Check API endpoints** - Find the endpoints you need
4. **Read frontend docs** - [admin.md](./admin.md) or [users.md](./users.md)

### For API Integration

1. Go to [backend.md](./backend.md)
2. Find your API module (Movies, Shows, etc.)
3. Copy request/response examples
4. Test with provided cURL commands

### For Frontend Development

**Admin Panel:**

- Read [admin.md](./admin.md)
- Check component hierarchy
- Review user workflows
- Study API service layer

**User App:**

- Read [users.md](./users.md)
- Understand authentication flow
- Review movie browsing features
- Check API integration

---

## 📊 Documentation Stats

| Metric                | Count  |
| --------------------- | ------ |
| Documentation Files   | 6      |
| Total Lines           | 4,800+ |
| Mermaid Diagrams      | 35+    |
| API Endpoints         | 47+    |
| Database Tables       | 16     |
| Components Documented | 26+    |

---

## 🔍 What's Documented

### Backend Features

✅ JWT authentication with refresh tokens  
✅ Role-based access control  
✅ OTP email verification  
✅ Location-based movie filtering  
✅ Show overlap prevention  
✅ **Seat booking with hold mechanism**  
✅ **Razorpay payment integration**  
✅ **Webhook handling for payment events** (+ `refund.processed` / `refund.failed`)
✅ **Atomic booking transactions**
✅ **Show cancellation with per-booking refund tracking** (`refunds` table, Razorpay refund IDs, webhook settlement)

### Admin Features

✅ Movie management (CRUD)
✅ Interactive screen designer
✅ Show scheduling
✅ Bulk show creation
✅ Image upload (Cloudinary)
✅ **Ads management (SuperAdmin only) — banner + sidebar ads with click-through tracking**
✅ **Offers / coupon system (SuperAdmin only) — global or hall-scoped percentage/fixed discount codes with expiry, eligibility targeting, and redemption tracking**
✅ **Refunds management — `/refunds` page lists all refund records; cancel dialog shows booking count + refund total; BookingDetailPage shows refund card with manual settle button**

### User Features

✅ OTP-based signup  
✅ Location-based browsing  
✅ Movie search  
✅ Profile management  
✅ Dark mode support  
✅ **Interactive seat selection**
✅ **Real-time seat availability**
✅ **Secure payment with Razorpay**
✅ **Booking confirmation page (API-fetched, refresh-safe)**
✅ **Refund status badge in My Bookings** — cancelled bookings show "Refund Initiated" / "Refund Settled" / "Refund Failed" badge
✅ **MovieInfoPage — BookMyShow-style movie detail with trailer embed**
✅ **Dynamic ad banners (carousel on /movies, sidebar on /movie/:id) with click-through recording**
✅ **Offers page (/offers) — browse eligible discount codes, copy with one click; redeemed offers shown as disabled with "Applied" badge**
✅ **Coupon input at checkout — apply offer code on Order Summary page with live discount preview**

---

## 📖 Documentation Structure

Each documentation file follows this structure:

1. **Overview** - Tech stack and introduction
2. **Architecture** - Diagrams and structure
3. **Features** - Detailed feature documentation
4. **API/Components** - Technical reference
5. **Workflows** - User/developer workflows
6. **Best Practices** - Implementation guidelines
7. **Future Enhancements** - Potential improvements

---

## 🛠️ Tech Stack

### Backend

- Express.js
- PostgreSQL — Neon (production), local PostgreSQL 18 (development)
- JWT Authentication
- Bcrypt
- Nodemailer (OTP)
- **Razorpay (Payments)**

### Frontend (Admin & User)

- React 18
- Vite
- React Router v6
- shadcn/ui
- Tailwind CSS
- Cloudinary (images)

---

## 📝 How to Use

### Finding Information

**Database Schema?** → [backend.md](./backend.md) - Database Schema section

**API Endpoints?** → [backend.md](./backend.md) - API Endpoints section

**Authentication Flow?** → All files have authentication sections

**Component Structure?** → [admin.md](./admin.md) or [users.md](./users.md)

**User Workflows?** → Check "User Workflows" sections

### Code Examples

All documentation includes:

- Request/response examples
- Code snippets
- Configuration examples
- cURL commands for testing

---

## 🔄 Keeping Documentation Updated

When adding new features:

1. **Update relevant .md file**
2. **Add Mermaid diagrams** if needed
3. **Include code examples**
4. **Update this README** if adding new sections

---

## 🤝 Contributing

If you find any issues or want to improve the documentation:

1. Update the relevant `.md` file
2. Ensure Mermaid diagrams render correctly
3. Follow existing formatting style
4. Test all code examples

---

## 📞 Questions?

If you need clarification on any documented feature:

- Check the relevant documentation file
- Review the Mermaid diagrams
- Look for code examples
- Check the "Best Practices" sections

---

## 📅 Last Updated

**Created**: January 29, 2026
**Last Updated**: April 14, 2026

---

**Happy Coding! 🎬🍿**
