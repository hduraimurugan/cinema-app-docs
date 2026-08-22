# Workflows

## 1. Admin Creates an Offer (RBAC since `6e0705a` / `a79e555`)

```
Admin (offers.create) fills OfferFormPage [/offers/new]
  — non-SuperAdmin sees scope default `hall` and Global hidden (useAuth at OfferFormPage.jsx:40)
  ↓
Client-side validation (required fields, hall dependency, joined_after dependency)
  ↓
POST /api/offers/create (verifyCinemaAdminAccessToken + requirePermission('offers.create'))
  ↓
Controller validates (6e0705a, controllers/offers.Controller.js:221):
  - code, title, discount_type, discount_value, valid_until required
  - discount_type must be 'percentage' or 'fixed'
  - scope=global requires superAdmin else 403
  - scope=hall for non-SuperAdmin: cinema_hall_id required and must be WHERE org_id = resolveOrgId(admin.id) else 403
  ↓
INSERT INTO offers (code uppercased, scope defaults to 'global', is_active defaults to true, created_by = req.admin.id)
  ↓
Return created offer with 201
  ↓
Toast "Offer created." → Navigate back to offers list
```

## 2. Customer Applies Offer at Checkout

```
Customer copies offer code from OffersPage
  ↓
Customer enters/pastes code on booking checkout screen
  ↓
Frontend calls POST /api/offers/validate { offer_code, show_id, total_amount }
  ↓
validateOfferCode() runs 8-step pipeline:
  1. Offer exists (UPPER case-insensitive)
  2. is_active = true
  3. valid_until > NOW()
  4. total_amount >= min_booking_amount
  5. Hall scope: show's cinema_hall_id matches offer's
  6. user_eligibility: customer.created_at > user_joined_after
  7. No prior redemption (offer_redemptions UNIQUE constraint)
  8. Calculate discount amount
  ↓
Returns { offer_id, offer_code, discount_amount, final_amount }
  ↓
Frontend displays discount preview to customer
```

## 3. Payment with Offer — Full Flow

```
Customer clicks "Pay" on checkout
  ↓
POST /api/payments/create-order { offer_code, show_id, seats, ... }
  ↓
createOrder() in payment.Controller.js:
  - Calculates grandTotal = seatTotal + convenienceFee + GST
  - If offer_code present: calls validateOfferCode() for validation + discount
  - Calculates finalAmount = grandTotal - discountAmount
  - Creates Razorpay order for finalAmount (in paise)
  - Inserts payment_orders row with offer_code, discount_amount
  ↓
Customer completes payment in Razorpay UI
  ↓
POST /api/payments/verify-payment { razorpay_* params }
  ↓
verifyPayment():
  - Validates signature
  - Confirms order exists, checks idempotency
  - Creates booking record
  - Updates payment_orders → status='paid'
  - Records offer_redemption:
      INSERT INTO offer_redemptions (offer_id, customer_id, booking_id, discount_applied)
      ON CONFLICT (offer_id, customer_id) DO NOTHING
  ↓
Success response → Customer sees booking confirmation
```

## 4. Webhook Fallback — Payment Captured

```
If verifyPayment was not called (e.g., network issue, Razorpay async webhook):
  ↓
handlePaymentCaptured() webhook handler:
  - Validates webhook signature
  - Handles idempotency (skips if already processed)
  - Creates booking if missing
  - Updates payment_orders → status='paid'
  - Records offer_redemption (same INSERT ... ON CONFLICT DO NOTHING)
```

## 5. Admin Edits an Offer (creator-scoped since `6e0705a`)

```
Admin (offers.read) navigates to /offers/:id/edit
  ↓
GET /api/offers/:id (creator ownership for non-SuperAdmin at controllers/offers.Controller.js:280 → 403 if not owner)
  ↓
OfferFormPage pre-fills all fields (code disabled on edit)
  ↓
Admin modifies fields, clicks "Save Changes"
  ↓
Client-side validation (same as create; global hidden for non-SuperAdmin)
  ↓
PUT /api/offers/update/:id (same global/hall ownership checks as create at line 308)
  ↓
Full UPDATE of all columns; code stored uppercased
  ↓
404 if offer missing; 403 if not owner or global not allowed; 409 on code conflict
  ↓
Toast "Offer updated." → Navigate to /offers
```

## 6. Admin Deletes an Offer (creator-scoped since `6e0705a`)

```
Admin sees delete only if isSuperAdmin || created_by===user.id (OffersManagement.jsx:384, a79e555)
  ↓
Admin clicks trash icon on offer row
  ↓
Confirmation dialog shows: "Are you sure you want to delete {code}?"
  ↓
Admin confirms → DELETE /api/offers/delete/:id (requirePermission offers.delete, ownership check at line 395 → 403 if not owner)
  ↓
Hard delete from offers table
  ↓
404 if already deleted; 403 if not owner; 200 with message otherwise
  ↓
Toast "Offer deleted." → List refreshes
```
