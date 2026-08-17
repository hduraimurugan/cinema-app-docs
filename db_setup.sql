-- =============================================================================
-- Cinema Hall — Full Database Setup Script
-- Works on both: Local PostgreSQL (pgAdmin / psql) and Neon (cloud)
--
-- Usage:
--   Local  → pgAdmin Query Tool → select cinema_hall_db → paste & run
--   Neon   → Neon Console SQL Editor → paste & run
--   psql   → psql -U postgres -d cinema_hall_db -f db_setup.sql
--
-- This is idempotent (safe to re-run): uses CREATE TABLE IF NOT EXISTS,
-- ADD COLUMN IF NOT EXISTS, CREATE INDEX IF NOT EXISTS, DO $$ blocks.
--
-- After running this script, create a superAdmin row:
--   See the "SUPER ADMIN SEED" section at the bottom.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 0. EXTENSIONS
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- provides gen_random_uuid()


-- ---------------------------------------------------------------------------
-- 1. CORE USER TABLES
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS cinema_admin_user (
  id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email                   TEXT        UNIQUE NOT NULL,
  password                TEXT,
  name                    TEXT        NOT NULL,
  phone                   TEXT,
  role                    VARCHAR(20) NOT NULL DEFAULT 'admin'
                            CHECK (role IN ('admin', 'superAdmin', 'staff')),
  email_verified          BOOLEAN     NOT NULL DEFAULT FALSE,
  email_verified_at       TIMESTAMPTZ,
  failed_login_attempts   INT         NOT NULL DEFAULT 0,
  account_locked_until    TIMESTAMPTZ,
  password_changed_at     TIMESTAMPTZ,
  last_login_at           TIMESTAMPTZ,
  -- OAuth identity. `password` stays NULL for accounts created via Google or
  -- GitHub — those inserts write password = NULL and rely on these columns.
  auth_providers          TEXT[]      NOT NULL DEFAULT ARRAY['local'],
  provider_ids            JSONB       NOT NULL DEFAULT '{}'::jsonb,
  avatar                  TEXT,
  created_at              TIMESTAMPTZ DEFAULT now()
);

-- Add auth-security columns to existing cinema_admin_user rows (idempotent)
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS email_verified        BOOLEAN     NOT NULL DEFAULT FALSE;
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS email_verified_at     TIMESTAMPTZ;
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS failed_login_attempts INT         NOT NULL DEFAULT 0;
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS account_locked_until  TIMESTAMPTZ;
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS password_changed_at   TIMESTAMPTZ;
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS last_login_at         TIMESTAMPTZ;
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS auth_providers        TEXT[]      NOT NULL DEFAULT ARRAY['local'];
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS provider_ids          JSONB       NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS avatar                TEXT;

-- One account per external identity. Partial so local-only accounts, which
-- have no provider id, do not all collide on NULL.
CREATE UNIQUE INDEX IF NOT EXISTS idx_admin_google_provider_id
  ON cinema_admin_user ((provider_ids->>'google'))
  WHERE provider_ids->>'google' IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_admin_github_provider_id
  ON cinema_admin_user ((provider_ids->>'github'))
  WHERE provider_ids->>'github' IS NOT NULL;

-- Mark all pre-existing admins as email-verified on fresh install
-- (They registered before this feature existed and have no verification token)
UPDATE cinema_admin_user
  SET email_verified = TRUE, email_verified_at = now()
  WHERE email_verified = FALSE;

-- Ensure constraints allow 'staff' role
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'cinema_admin_user_role_check'
  ) THEN
    ALTER TABLE cinema_admin_user DROP CONSTRAINT cinema_admin_user_role_check;
  END IF;
END $$;
ALTER TABLE cinema_admin_user ADD CONSTRAINT cinema_admin_user_role_check
  CHECK (role IN ('superAdmin', 'admin', 'staff'));

-- ── Admin email-verification tokens ───────────────────────────────────────
-- Raw token sent in email; only the SHA-256 hash is stored here.
CREATE TABLE IF NOT EXISTS admin_verification_tokens (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id   UUID        NOT NULL REFERENCES cinema_admin_user(id) ON DELETE CASCADE,
  token_hash TEXT        NOT NULL UNIQUE,
  purpose    VARCHAR(50) DEFAULT 'email_verification',
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_verification_tokens_admin_id
  ON admin_verification_tokens(admin_id);

ALTER TABLE admin_verification_tokens ADD COLUMN IF NOT EXISTS purpose VARCHAR(50) DEFAULT 'email_verification';

-- ── Admin password-reset tokens ─────────────────────────────────────────────
-- Single-use; marked used = TRUE after redemption.
CREATE TABLE IF NOT EXISTS admin_password_reset_tokens (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id   UUID        NOT NULL REFERENCES cinema_admin_user(id) ON DELETE CASCADE,
  token_hash TEXT        NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  used       BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_password_reset_tokens_admin_id
  ON admin_password_reset_tokens(admin_id);

-- ── Admin sessions (server-side refresh token store) ────────────────────────
-- Enables logout-all-devices and token revocation.
CREATE TABLE IF NOT EXISTS admin_sessions (
  id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id           UUID        NOT NULL REFERENCES cinema_admin_user(id) ON DELETE CASCADE,
  refresh_token_hash TEXT        NOT NULL UNIQUE,
  ip_address         TEXT,
  user_agent         TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_used_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_revoked         BOOLEAN     NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_admin_sessions_admin_id
  ON admin_sessions(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_token_hash
  ON admin_sessions(refresh_token_hash) WHERE is_revoked = FALSE;

-- ── Admin security audit log ─────────────────────────────────────────────────
-- Raw tokens usage tracking and security logs.
CREATE TABLE IF NOT EXISTS admin_security_logs (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id   UUID        REFERENCES cinema_admin_user(id) ON DELETE SET NULL,
  action     TEXT        NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  metadata   JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_security_logs_admin_id
  ON admin_security_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_security_logs_created_at
  ON admin_security_logs(created_at DESC);

-- ── Organizations (tenant layer) ───────────────────────────────────────────
-- owner_id is ON DELETE RESTRICT: ownership must be transferred before the
-- owning user can be deleted, otherwise the org is orphaned. It stays
-- NULLABLE because test fixtures create orgs without an owner.
CREATE TABLE IF NOT EXISTS organizations (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name              TEXT NOT NULL,
  slug              TEXT UNIQUE NOT NULL,
  owner_id          UUID REFERENCES cinema_admin_user(id) ON DELETE RESTRICT,
  default_timezone  TEXT NOT NULL DEFAULT 'Asia/Kolkata',
  default_currency  TEXT NOT NULL DEFAULT 'INR',
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  plan              TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free','pro','enterprise')),
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

-- ── Roles & Permissions (RBAC layer) ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS roles (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id            UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  key               VARCHAR(50) NOT NULL,
  label             VARCHAR(100) NOT NULL,
  description       TEXT,
  is_system         BOOLEAN NOT NULL DEFAULT FALSE,
  permissions_version INTEGER NOT NULL DEFAULT 1,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now(),
  UNIQUE (org_id, key),
  -- Anchor for the composite FK on organization_members: lets a member's
  -- role_id be correlated with the member's own org_id.
  CONSTRAINT roles_id_org_key UNIQUE (id, org_id)
);

CREATE TABLE IF NOT EXISTS permissions (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key       VARCHAR(100) UNIQUE NOT NULL,
  label     VARCHAR(200) NOT NULL,
  resource  VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id       UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- ── Organization Members ───────────────────────────────────────────────────
-- role_id uses a COMPOSITE FK so a member can only ever hold a role from
-- their own organization. A plain FK to roles(id) allowed org A to be
-- assigned org B's role and inherit its permissions.
CREATE TABLE IF NOT EXISTS organization_members (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  admin_id    UUID NOT NULL REFERENCES cinema_admin_user(id) ON DELETE CASCADE,
  role_id     UUID NOT NULL,
  status      VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('invited','active','suspended','removed')),
  invited_by  UUID REFERENCES cinema_admin_user(id),
  invited_at  TIMESTAMPTZ,
  joined_at   TIMESTAMPTZ,
  removed_at  TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT organization_members_id_org_key UNIQUE (id, org_id),
  CONSTRAINT organization_members_role_same_org_fkey
    FOREIGN KEY (role_id, org_id) REFERENCES roles(id, org_id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS idx_org_members_admin ON organization_members(admin_id);
CREATE INDEX IF NOT EXISTS idx_org_members_org ON organization_members(org_id);

-- One LIVE membership per (org, admin). Removed members keep their row as
-- history and can be re-invited; an unconditional UNIQUE made re-inviting
-- a removed member fail permanently.
CREATE UNIQUE INDEX IF NOT EXISTS uniq_active_org_member
  ON organization_members(org_id, admin_id)
  WHERE status <> 'removed';

-- ── Cinema Halls & Hall Assignments ────────────────────────────────────────
-- The ORGANIZATION owns the hall (org_id). admin_id only records who created
-- it, so it is nullable and ON DELETE SET NULL — it was ON DELETE CASCADE,
-- which meant deleting one admin user destroyed that org's halls, screens,
-- shows and bookings.
CREATE TABLE IF NOT EXISTS cinema_hall (
  id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id     UUID         REFERENCES cinema_admin_user(id) ON DELETE SET NULL,
  org_id       UUID         NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name         TEXT         NOT NULL,
  location     TEXT         NOT NULL,
  district     TEXT         NOT NULL DEFAULT '',
  state        TEXT         NOT NULL DEFAULT '',
  latitude     NUMERIC(10,7),
  longitude    NUMERIC(10,7),
  phone        TEXT,
  description  TEXT,
  is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ  DEFAULT now(),
  -- Anchor for hall_assignments' composite FK.
  CONSTRAINT cinema_hall_id_org_key UNIQUE (id, org_id)
);

-- Add org_id to existing cinema_hall table (idempotent)
ALTER TABLE cinema_hall ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES organizations(id) ON DELETE CASCADE;

-- org_id is carried here purely so BOTH sides can be correlated: the member
-- and the hall must belong to the same organization.
CREATE TABLE IF NOT EXISTS hall_assignments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_member_id   UUID NOT NULL,
  -- org_id is constrained through the two composite FKs below, not directly
  -- to organizations — matching the live schema after phase 4.
  org_id          UUID NOT NULL,
  hall_id         UUID NOT NULL,
  scope           VARCHAR(20) NOT NULL DEFAULT 'full' CHECK (scope IN ('full','read_only','limited')),
  assigned_by     UUID REFERENCES cinema_admin_user(id),
  created_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE (org_member_id, hall_id),
  CONSTRAINT hall_assignments_member_same_org_fkey
    FOREIGN KEY (org_member_id, org_id) REFERENCES organization_members(id, org_id) ON DELETE CASCADE,
  CONSTRAINT hall_assignments_hall_same_org_fkey
    FOREIGN KEY (hall_id, org_id) REFERENCES cinema_hall(id, org_id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_hall_assignments_org ON hall_assignments(org_id);

-- Add columns to existing cinema_hall tables (idempotent)
ALTER TABLE cinema_hall ADD COLUMN IF NOT EXISTS latitude    NUMERIC(10,7);
ALTER TABLE cinema_hall ADD COLUMN IF NOT EXISTS longitude   NUMERIC(10,7);
ALTER TABLE cinema_hall ADD COLUMN IF NOT EXISTS phone       TEXT;
ALTER TABLE cinema_hall ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE cinema_hall ADD COLUMN IF NOT EXISTS is_active   BOOLEAN NOT NULL DEFAULT TRUE;

CREATE TABLE IF NOT EXISTS customers (
  id                      UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  email                   TEXT    UNIQUE NOT NULL,
  -- password and name are NULLABLE on purpose. Google sign-up inserts
  -- password = NULL, so a NOT NULL here rejects every OAuth customer.
  password                TEXT,
  name                    TEXT,
  phone                   TEXT,
  is_verified             BOOLEAN NOT NULL DEFAULT FALSE,
  district                TEXT    NOT NULL DEFAULT '',
  state                   TEXT    NOT NULL DEFAULT '',
  failed_login_attempts   INT     NOT NULL DEFAULT 0,
  account_locked_until    TIMESTAMPTZ,
  last_login_at           TIMESTAMPTZ,
  password_changed_at     TIMESTAMPTZ,
  auth_providers          TEXT[]  NOT NULL DEFAULT ARRAY['local'],
  provider_ids            JSONB   NOT NULL DEFAULT '{}'::jsonb,
  avatar                  TEXT,
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

-- Idempotent for databases created before OAuth support
ALTER TABLE customers ADD COLUMN IF NOT EXISTS auth_providers TEXT[] NOT NULL DEFAULT ARRAY['local'];
ALTER TABLE customers ADD COLUMN IF NOT EXISTS provider_ids   JSONB  NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS avatar         TEXT;
ALTER TABLE customers ALTER COLUMN password DROP NOT NULL;
ALTER TABLE customers ALTER COLUMN name     DROP NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_google_provider_id
  ON customers ((provider_ids->>'google'))
  WHERE provider_ids->>'google' IS NOT NULL;

-- Auto-update customers.updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;
CREATE TRIGGER update_customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- organizations.updated_at existed from the start but nothing ever set it.
DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
CREATE TRIGGER update_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE IF NOT EXISTS otp_verifications (
  id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  email        TEXT    NOT NULL,
  type         TEXT    NOT NULL DEFAULT 'signup',  -- 'signup' | 'password_reset'
  otp          TEXT    NOT NULL,                   -- SHA-256 hashed
  otp_attempts INT     NOT NULL DEFAULT 0,
  is_verified  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT now(),
  expires_at   TIMESTAMPTZ NOT NULL,
  CONSTRAINT fk_customer_email FOREIGN KEY (email)
    REFERENCES customers(email) ON DELETE CASCADE,
  CONSTRAINT otp_verifications_email_type_key UNIQUE (email, type)
);

CREATE TABLE IF NOT EXISTS customer_sessions (
  id                  UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id         UUID    NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  refresh_token_hash  TEXT    NOT NULL UNIQUE,
  ip_address          TEXT,
  user_agent          TEXT,
  is_revoked          BOOLEAN NOT NULL DEFAULT FALSE,
  last_used_at        TIMESTAMPTZ DEFAULT now(),
  created_at          TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customer_sessions_customer_id ON customer_sessions(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_sessions_token_hash  ON customer_sessions(refresh_token_hash);


-- ---------------------------------------------------------------------------
-- 2. SCREENS & MOVIES
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS screens (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  cinema_hall_id  UUID    REFERENCES cinema_hall(id) ON DELETE CASCADE,
  name            TEXT    NOT NULL,
  total_seats     INT     NOT NULL,
  premium_seats   INT     NOT NULL,
  gold_seats      INT     NOT NULL,
  silver_seats    INT     NOT NULL,
  premium_price   NUMERIC(10,2) NOT NULL,
  gold_price      NUMERIC(10,2) NOT NULL,
  silver_price    NUMERIC(10,2) NOT NULL,
  rows            INT     NOT NULL,
  columns         INT     NOT NULL,
  screen_position TEXT    NOT NULL,
  layout          JSONB,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS movies (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  title         TEXT    NOT NULL,
  description   TEXT,
  poster_url    TEXT,
  backdrop_path TEXT,
  trailer_url   TEXT,
  duration_mins INT,
  genre         TEXT[],
  language      TEXT[],
  status        TEXT    NOT NULL DEFAULT 'upcoming',
  release_date  DATE,
  tmdb_id       INT     UNIQUE,
  "cast"        JSONB   DEFAULT '[]',
  vote_average  NUMERIC(4,2),
  vote_count    INT,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- Idempotently check and append backdrop_path column
ALTER TABLE movies ADD COLUMN IF NOT EXISTS backdrop_path TEXT;


-- ---------------------------------------------------------------------------
-- 3. SHOWS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS shows (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  movie_id         UUID NOT NULL REFERENCES movies(id)  ON DELETE CASCADE,
  screen_id        UUID NOT NULL REFERENCES screens(id) ON DELETE CASCADE,
  show_date        DATE NOT NULL,
  start_time       TIME NOT NULL,
  end_time         TIME NOT NULL,
  status           TEXT NOT NULL DEFAULT 'scheduled'
                     CHECK (status IN ('scheduled', 'booking_started', 'in_progress', 'show_ended', 'cancelled')),
  language_version TEXT NOT NULL DEFAULT 'Original',
  price_override   JSONB,
  created_at       TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT unique_screen_showtime UNIQUE (screen_id, show_date, start_time)
);

-- Midnight-crossing-safe overlap prevention trigger
CREATE OR REPLACE FUNCTION prevent_overlapping_shows()
RETURNS TRIGGER AS $$
DECLARE
  new_crosses_midnight BOOLEAN := NEW.end_time < NEW.start_time;
BEGIN
  IF EXISTS (
    SELECT 1 FROM shows
    WHERE screen_id = NEW.screen_id
      AND show_date  = NEW.show_date
      AND id IS DISTINCT FROM NEW.id
      AND (
        CASE
          WHEN NOT new_crosses_midnight AND end_time >= start_time THEN
            NEW.start_time < end_time AND start_time < NEW.end_time
          WHEN new_crosses_midnight AND end_time >= start_time THEN
            start_time >= NEW.start_time OR end_time <= NEW.end_time
          WHEN NOT new_crosses_midnight AND end_time < start_time THEN
            NEW.start_time >= start_time OR NEW.end_time <= end_time
          ELSE TRUE
        END
      )
  ) THEN
    RAISE EXCEPTION 'Show overlaps with an existing show on the same screen.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_prevent_overlap ON shows;
CREATE TRIGGER trigger_prevent_overlap
  BEFORE INSERT OR UPDATE ON shows
  FOR EACH ROW EXECUTE FUNCTION prevent_overlapping_shows();


-- ---------------------------------------------------------------------------
-- 4. SEAT & BOOKING TABLES
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS show_booked_seats (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  show_id         UUID NOT NULL REFERENCES shows(id)     ON DELETE CASCADE,
  seat_id         TEXT NOT NULL,
  seat_label      TEXT NOT NULL,
  row_label       TEXT NOT NULL,
  column_number   INT  NOT NULL,
  status          TEXT NOT NULL DEFAULT 'AVAILABLE'
                    CHECK (status IN ('AVAILABLE', 'HELD', 'BOOKED')),
  held_by         UUID REFERENCES customers(id)          ON DELETE SET NULL,
  hold_expires_at TIMESTAMPTZ,
  booked_at       TIMESTAMPTZ DEFAULT now(),
  created_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE (show_id, seat_id)
);

CREATE INDEX IF NOT EXISTS idx_show_booked_seats_expires
  ON show_booked_seats(status, hold_expires_at)
  WHERE status = 'HELD';

CREATE TABLE IF NOT EXISTS payment_orders (
  id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id          VARCHAR(255) UNIQUE NOT NULL,
  show_id           UUID         NOT NULL REFERENCES shows(id)     ON DELETE CASCADE,
  customer_id       UUID         NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  seats             JSONB        NOT NULL,
  amount            DECIMAL(10,2) NOT NULL,
  status            VARCHAR(20)  DEFAULT 'created'
                      CHECK (status IN ('created', 'paid', 'failed', 'expired')),
  payment_id        VARCHAR(255),
  payment_signature VARCHAR(500),
  convenience_fee   DECIMAL(10,2) NOT NULL DEFAULT 0,
  gst_amount        DECIMAL(10,2) NOT NULL DEFAULT 0,
  offer_code        VARCHAR(50),
  discount_amount   NUMERIC(10,2) DEFAULT 0,
  created_at        TIMESTAMPTZ  DEFAULT now(),
  updated_at        TIMESTAMPTZ  DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payment_orders_order_id  ON payment_orders(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_orders_customer  ON payment_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_payment_orders_status    ON payment_orders(status);

CREATE TABLE IF NOT EXISTS bookings (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id     UUID         NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  show_id         UUID         NOT NULL REFERENCES shows(id)     ON DELETE CASCADE,
  seats           JSONB        NOT NULL,
  total_amount    DECIMAL(10,2) NOT NULL,
  payment_status  VARCHAR(20)  DEFAULT 'pending',
  payment_id      VARCHAR(255),                           -- UNIQUE via uq_bookings_payment_id (idempotency)
  booking_status  VARCHAR(20)  DEFAULT 'confirmed'
                    CHECK (booking_status IN ('confirmed', 'cancelled', 'completed')),
  convenience_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
  gst_amount      DECIMAL(10,2) NOT NULL DEFAULT 0,
  offer_code      VARCHAR(50),
  discount_amount NUMERIC(10,2) DEFAULT 0,
  created_at      TIMESTAMPTZ  DEFAULT now(),
  updated_at      TIMESTAMPTZ  DEFAULT now()
);

-- Deduplication table for Razorpay webhooks
CREATE TABLE IF NOT EXISTS webhook_events (
  id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id     TEXT        UNIQUE NOT NULL,       -- X-Razorpay-Event-Id
  event_type   TEXT        NOT NULL,              -- e.g. payment.captured
  -- Nullable to match the live schema. The webhook handler always computes it,
  -- so it could be tightened — see the note at the end of this file.
  payload_hash TEXT,                              -- SHA-256 of raw body
  processed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bookings_customer ON bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_show     ON bookings(show_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status   ON bookings(booking_status);


-- ---------------------------------------------------------------------------
-- 5. OFFERS & REDEMPTIONS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS offers (
  id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  code                VARCHAR(50)  UNIQUE NOT NULL,
  title               VARCHAR(255) NOT NULL,
  description         TEXT,
  discount_type       VARCHAR(10)  NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value      NUMERIC(10,2) NOT NULL,
  max_discount_amount NUMERIC(10,2),
  min_booking_amount  NUMERIC(10,2) NOT NULL DEFAULT 0,
  is_active           BOOLEAN      NOT NULL DEFAULT true,
  valid_until         TIMESTAMPTZ  NOT NULL,
  scope               VARCHAR(10)  NOT NULL DEFAULT 'global' CHECK (scope IN ('global', 'hall')),
  cinema_hall_id      UUID         REFERENCES cinema_hall(id) ON DELETE CASCADE,
  user_eligibility    VARCHAR(20)  NOT NULL DEFAULT 'all' CHECK (user_eligibility IN ('all', 'joined_after')),
  user_joined_after   TIMESTAMPTZ,
  created_by          UUID         REFERENCES cinema_admin_user(id),
  created_at          TIMESTAMPTZ  DEFAULT NOW(),
  updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS offer_redemptions (
  id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  offer_id         UUID         NOT NULL REFERENCES offers(id)    ON DELETE CASCADE,
  customer_id      UUID         NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  booking_id       UUID         REFERENCES bookings(id),
  discount_applied NUMERIC(10,2) NOT NULL,
  created_at       TIMESTAMPTZ  DEFAULT NOW(),
  UNIQUE (offer_id, customer_id)
);


-- ---------------------------------------------------------------------------
-- 6. REFUNDS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS refunds (
  id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id          UUID         NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  payment_id          VARCHAR(255) NOT NULL,
  razorpay_refund_id  VARCHAR(255),
  amount              DECIMAL(10,2) NOT NULL,
  refund_status       VARCHAR(30)  NOT NULL DEFAULT 'initiated'
                        CHECK (refund_status IN ('initiated', 'settled', 'failed')),
  initiated_at        TIMESTAMPTZ  DEFAULT NOW(),
  settled_at          TIMESTAMPTZ,
  failure_reason      TEXT,
  created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refunds_booking_id         ON refunds(booking_id);
CREATE INDEX IF NOT EXISTS idx_refunds_razorpay_refund_id ON refunds(razorpay_refund_id);
CREATE INDEX IF NOT EXISTS idx_refunds_payment_id         ON refunds(payment_id);


-- ---------------------------------------------------------------------------
-- 7. ADS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ads (
  id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  title      VARCHAR(255) NOT NULL,
  image_url  TEXT         NOT NULL,
  click_url  TEXT,
  placement  VARCHAR(20)  NOT NULL DEFAULT 'banner',
  start_date DATE         NOT NULL,
  end_date   DATE         NOT NULL,
  is_active  BOOLEAN      DEFAULT true,
  created_at TIMESTAMP    DEFAULT NOW(),
  updated_at TIMESTAMP    DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ad_clicks (
  id          UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_id       UUID      REFERENCES ads(id)       ON DELETE CASCADE,
  customer_id UUID      REFERENCES customers(id) ON DELETE SET NULL,
  clicked_at  TIMESTAMP DEFAULT NOW()
);


-- ---------------------------------------------------------------------------
-- 8. SETTINGS & SCHEMAS
-- ---------------------------------------------------------------------------

-- Drop legacy settings table if it exists
DROP TABLE IF EXISTS settings CASCADE;

-- ── Organization-level settings (JSONB per section) ──────────────────
-- Sections: general, payment, tickets, security, notifications, branding, integrations, advanced
CREATE TABLE IF NOT EXISTS organization_settings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id          UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  section         TEXT NOT NULL,
  value           JSONB NOT NULL DEFAULT '{}',
  schema_version  INT NOT NULL DEFAULT 1,
  updated_by      UUID REFERENCES cinema_admin_user(id),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE (org_id, section)
);
CREATE INDEX IF NOT EXISTS idx_org_settings_org_section ON organization_settings(org_id, section);

-- ── Hall-level settings (per-branch, JSONB per section) ──────────────
-- Sections: cinema_profile, showtimes, booking, offers
CREATE TABLE IF NOT EXISTS hall_settings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hall_id         UUID NOT NULL REFERENCES cinema_hall(id) ON DELETE CASCADE,
  section         TEXT NOT NULL,
  value           JSONB NOT NULL DEFAULT '{}',
  schema_version  INT NOT NULL DEFAULT 1,
  updated_by      UUID REFERENCES cinema_admin_user(id),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE (hall_id, section)
);
CREATE INDEX IF NOT EXISTS idx_hall_settings_hall_section ON hall_settings(hall_id, section);

-- ── User-level settings (per-admin preferences, JSONB per section) ───
-- Sections: notifications, analytics, appearance
CREATE TABLE IF NOT EXISTS user_settings (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id  UUID NOT NULL REFERENCES cinema_admin_user(id) ON DELETE CASCADE,
  section   TEXT NOT NULL,
  value     JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (admin_id, section)
);
CREATE INDEX IF NOT EXISTS idx_user_settings_admin ON user_settings(admin_id);

-- ---------------------------------------------------------------------------
-- 9. RBAC & PERMISSION SEEDING
-- ---------------------------------------------------------------------------

-- Seed Permissions
INSERT INTO permissions (key, label, resource) VALUES
  ('movies.create',   'Create Movies',          'movies'),
  ('movies.read',     'Read Movies',            'movies'),
  ('movies.update',   'Update Movies',          'movies'),
  ('movies.delete',   'Delete Movies',          'movies'),
  ('shows.create',    'Create Shows',           'shows'),
  ('shows.read',      'Read Shows',             'shows'),
  ('shows.update',    'Update Shows',           'shows'),
  ('shows.delete',    'Delete Shows',           'shows'),
  ('shows.cancel',    'Cancel Shows',           'shows'),
  ('screens.create',  'Create Screens',         'screens'),
  ('screens.read',    'Read Screens',           'screens'),
  ('screens.update',  'Update Screens',         'screens'),
  ('screens.delete',  'Delete Screens',         'screens'),
  ('bookings.read',   'Read Bookings',          'bookings'),
  ('bookings.verify', 'Verify Bookings',        'bookings'),
  ('bookings.cancel', 'Cancel Bookings',        'bookings'),
  ('bookings.modify', 'Modify Bookings',        'bookings'),
  ('refunds.create',  'Create Refunds',         'refunds'),
  ('refunds.read',    'Read Refunds',           'refunds'),
  ('refunds.settle',  'Settle Refunds',         'refunds'),
  ('offers.create',   'Create Offers',          'offers'),
  ('offers.read',     'Read Offers',            'offers'),
  ('offers.update',   'Update Offers',          'offers'),
  ('offers.delete',   'Delete Offers',          'offers'),
  ('ads.create',      'Create Ads',             'ads'),
  ('ads.read',        'Read Ads',               'ads'),
  ('ads.update',      'Update Ads',             'ads'),
  ('ads.delete',      'Delete Ads',             'ads'),
  ('customers.read',  'Read Customers',         'customers'),
  ('customers.manage','Manage Customers',       'customers'),
  ('payment.read',    'Read Payment',           'payment'),
  ('payment.manage',  'Manage Payment',         'payment'),
  ('payment.settle',  'Settle Payment',         'payment'),
  ('halls.read',      'Read Halls',             'halls'),
  ('halls.manage',    'Manage Halls',           'halls'),
  ('settings.org.read',   'Read Org Settings',     'settings'),
  ('settings.org.update', 'Update Org Settings',   'settings'),
  ('settings.hall.read',  'Read Hall Settings',    'settings'),
  ('settings.hall.update','Update Hall Settings',  'settings'),
  ('settings.user.read',  'Read User Settings',    'settings'),
  ('settings.user.update','Update User Settings',  'settings'),
  ('settings.advanced.manage','Manage Advanced Settings','settings'),
  ('team.manage',    'Manage Team',             'team'),
  ('team.invite',    'Invite Team Members',     'team'),
  ('team.revoke',    'Revoke Team Members',     'team'),
  ('roles.manage',   'Manage Roles',            'roles'),
  ('roles.read',     'Read Roles',              'roles'),
  ('audit.view',     'View Audit Logs',         'audit'),
  ('analytics.view', 'View Analytics',          'analytics'),
  ('analytics.manage','Manage Analytics',       'analytics'),
  ('dashboard.view', 'View Dashboard',          'dashboard'),
  ('verify-ticket.use','Use Verify Ticket',     'verify-ticket'),
  ('integrations.manage','Manage Integrations', 'integrations'),
  ('billing.manage', 'Manage Billing',          'billing'),
  ('org.delete',     'Delete Organization',     'org')
ON CONFLICT (key) DO NOTHING;

-- Seed default orgs for any cinema admin who doesn't have one yet (backfill)
--
-- Only for admins who belong to NO organization at all. Testing ownership
-- alone minted a hall-less shell org for every staff member who had been
-- invited into someone else's org, and because that shell made them its
-- 'owner' it then outranked their real membership at sign-in — they landed in
-- an empty tenant with full owner permissions. Platform 'staff' never get an
-- org of their own; they exist only as members of one.
INSERT INTO organizations (name, slug, owner_id)
SELECT
  COALESCE(cau.name, cau.email) || '''s Cinema',
  LOWER(REPLACE(COALESCE(cau.name, cau.email), ' ', '-')) || '-' || LEFT(cau.id::text, 8),
  cau.id
FROM cinema_admin_user cau
WHERE cau.role <> 'staff'
  AND NOT EXISTS (
    SELECT 1 FROM organizations o WHERE o.owner_id = cau.id
  )
  AND NOT EXISTS (
    SELECT 1 FROM organization_members om
    WHERE om.admin_id = cau.id AND om.status IN ('active', 'invited', 'suspended')
  );

-- Associate halls with organization if missing (backfill org_id column)
UPDATE cinema_hall ch
SET org_id = COALESCE(
  (SELECT id FROM organizations o WHERE o.owner_id = ch.admin_id LIMIT 1),
  (SELECT org_id FROM organization_members om WHERE om.admin_id = ch.admin_id LIMIT 1),
  (SELECT id FROM organizations LIMIT 1)
)
WHERE org_id IS NULL;

-- Ensure org_id is NOT NULL after backfill (idempotent)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'cinema_hall' AND column_name = 'org_id' AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE cinema_hall ALTER COLUMN org_id SET NOT NULL;
  END IF;
END $$;

-- Seed System Roles for all organizations
INSERT INTO roles (org_id, key, label, description, is_system)
SELECT o.id, r.key, r.label, r.description, TRUE
FROM organizations o
CROSS JOIN (VALUES
  ('owner',           'Owner',           'Full access to all features including billing and org management'),
  ('admin',           'Admin',           'Full access except billing, org deletion, and role management'),
  ('manager',         'Manager',         'Manage shows, screens, bookings, refunds, and view customers'),
  ('sales',           'Sales',           'Handle bookings, refunds, and customer inquiries'),
  ('finance',         'Finance',         'View bookings, payments, refunds, and analytics'),
  ('marketing',       'Marketing',       'Manage offers, ads, and view customer analytics'),
  ('ticket_operator', 'Ticket Operator',  'Verify tickets and view bookings and shows'),
  ('auditor',         'Auditor',         'Read-only access across all resources')
) AS r(key, label, description)
WHERE NOT EXISTS (
  SELECT 1 FROM roles r2 WHERE r2.org_id = o.id AND r2.key = r.key
);

-- Seed Role Permissions per organization
-- Owner
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.key = 'owner'
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- Admin
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.key = 'admin'
  AND p.key NOT IN ('org.delete', 'roles.manage', 'billing.manage')
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- Manager
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.key = 'manager'
  AND p.key IN (
    'shows.create', 'shows.read', 'shows.update', 'shows.delete', 'shows.cancel',
    'screens.create', 'screens.read', 'screens.update', 'screens.delete',
    'bookings.read', 'bookings.verify', 'bookings.cancel', 'bookings.modify',
    'refunds.create', 'refunds.read', 'refunds.settle',
    'movies.read', 'movies.update',
    'settings.hall.read', 'settings.hall.update',
    'customers.read', 'dashboard.view',
    'halls.read', 'halls.manage'
  )
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- Sales
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.key = 'sales'
  AND p.key IN ('bookings.read', 'bookings.cancel', 'refunds.create', 'refunds.read', 'dashboard.view', 'customers.read', 'halls.read')
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- Finance
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.key = 'finance'
  AND p.key IN ('bookings.read', 'payment.read', 'refunds.create', 'refunds.read', 'refunds.settle', 'analytics.view', 'dashboard.view', 'customers.read', 'halls.read')
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- Marketing
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.key = 'marketing'
  AND p.key IN ('offers.create', 'offers.read', 'offers.update', 'offers.delete', 'ads.create', 'ads.read', 'ads.update', 'ads.delete', 'movies.read', 'customers.read', 'analytics.view', 'dashboard.view', 'halls.read')
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- Ticket Operator
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.key = 'ticket_operator'
  AND p.key IN ('shows.read', 'bookings.read', 'bookings.verify', 'verify-ticket.use', 'customers.read', 'dashboard.view', 'halls.read')
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- Auditor
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.key = 'auditor'
  AND (p.key LIKE '%.read' OR p.key IN ('audit.view', 'dashboard.view'))
  AND NOT EXISTS (
    SELECT 1 FROM role_permissions rp WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- Backfill: Add existing owners as org members
INSERT INTO organization_members (org_id, admin_id, role_id, status, joined_at)
SELECT o.id, o.owner_id, r.id, 'active', now()
FROM organizations o
JOIN roles r ON r.org_id = o.id AND r.key = 'owner'
WHERE o.owner_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM organization_members om WHERE om.org_id = o.id AND om.admin_id = o.owner_id
  );

-- ── Seed default org-level settings for every org (if missing) ───────
INSERT INTO organization_settings (org_id, section, value)
SELECT o.id, 'general', '{"org_name":"","timezone":"Asia/Kolkata","currency":"INR","language":"en"}'::jsonb
FROM organizations o
WHERE NOT EXISTS (SELECT 1 FROM organization_settings os WHERE os.org_id = o.id AND os.section = 'general');

INSERT INTO organization_settings (org_id, section, value)
SELECT o.id, 'payment', '{"convenience_fee":{"model":"per_ticket","amount":15},"gst_percentage":18,"gst_applies_to":"convenience_fee","state_taxes":[]}'::jsonb
FROM organizations o
WHERE NOT EXISTS (SELECT 1 FROM organization_settings os WHERE os.org_id = o.id AND os.section = 'payment');

INSERT INTO organization_settings (org_id, section, value)
SELECT o.id, 'tickets', '{"booking_id_prefix":"CINE","qr_error_correction":"M","pdf_footer_text":""}'::jsonb
FROM organizations o
WHERE NOT EXISTS (SELECT 1 FROM organization_settings os WHERE os.org_id = o.id AND os.section = 'tickets');

INSERT INTO organization_settings (org_id, section, value)
SELECT o.id, 'security', '{"password_policy":{"min_length":8,"require_upper":true,"require_lower":true,"require_digit":true,"require_special":true,"prevent_reuse_count":5,"expiry_days":null},"lockout_policy":{"thresholds":[{"attempts":5,"minutes":15},{"attempts":10,"minutes":60},{"attempts":15,"minutes":1440}]},"session_timeout_minutes":null,"mfa_required":false,"invite_expiry_hours":72}'::jsonb
FROM organizations o
WHERE NOT EXISTS (SELECT 1 FROM organization_settings os WHERE os.org_id = o.id AND os.section = 'security');

INSERT INTO organization_settings (org_id, section, value)
SELECT o.id, 'notifications', '{"email":{"provider":"smtp","from":"","enabled":true},"sms":{"provider":"","from":"","enabled":false},"whatsapp":{"provider":"","enabled":false},"push":{"provider":"fcm","enabled":false}}'::jsonb
FROM organizations o
WHERE NOT EXISTS (SELECT 1 FROM organization_settings os WHERE os.org_id = o.id AND os.section = 'notifications');

INSERT INTO organization_settings (org_id, section, value)
SELECT o.id, 'branding', '{"logo_url":"","logo_dark_url":"","banner_url":"","primary_color":"","accent_color":"","font_family":"","app_name":"Cinemax","default_theme":"dark","white_label":false}'::jsonb
FROM organizations o
WHERE NOT EXISTS (SELECT 1 FROM organization_settings os WHERE os.org_id = o.id AND os.section = 'branding');

INSERT INTO organization_settings (org_id, section, value)
SELECT o.id, 'integrations', '{"razorpay":{"key":"","secret_encrypted":""},"tmdb":{"api_key":""},"cloudinary":{"cloud_name":"","api_key":"","api_secret_encrypted":""}}'::jsonb
FROM organizations o
WHERE NOT EXISTS (SELECT 1 FROM organization_settings os WHERE os.org_id = o.id AND os.section = 'integrations');

INSERT INTO organization_settings (org_id, section, value)
SELECT o.id, 'advanced', '{"feature_flags":{},"retention_days":{"security_logs":90,"audit_logs":90,"sessions":30,"devices":365}}'::jsonb
FROM organizations o
WHERE NOT EXISTS (SELECT 1 FROM organization_settings os WHERE os.org_id = o.id AND os.section = 'advanced');

-- ── Seed default hall-level sections for every hall (if missing) ─────
INSERT INTO hall_settings (hall_id, section, value)
SELECT h.id, 'cinema_profile', '{"name":"","address":"","district":"","state":"","phone":"","description":"","operating_hours":{}}'::jsonb
FROM cinema_hall h
WHERE NOT EXISTS (SELECT 1 FROM hall_settings hs WHERE hs.hall_id = h.id AND hs.section = 'cinema_profile');

INSERT INTO hall_settings (hall_id, section, value)
SELECT h.id, 'showtimes', '{"default_buffer_minutes":15,"prevent_overlap":true,"default_language_version":"Original","auto_status_transitions":true,"timezone":"Asia/Kolkata","advance_booking_days":7,"booking_open_offset_minutes":0}'::jsonb
FROM cinema_hall h
WHERE NOT EXISTS (SELECT 1 FROM hall_settings hs WHERE hs.hall_id = h.id AND hs.section = 'showtimes');

INSERT INTO hall_settings (hall_id, section, value)
SELECT h.id, 'booking', '{"max_seats_per_booking":10,"advance_booking_days":7,"hold_minutes":5,"cancellation":{"allowed":true,"window_minutes":120,"penalty_percentage":10}}'::jsonb
FROM cinema_hall h
WHERE NOT EXISTS (SELECT 1 FROM hall_settings hs WHERE hs.hall_id = h.id AND hs.section = 'booking');

INSERT INTO hall_settings (hall_id, section, value)
SELECT h.id, 'offers', '{"auto_apply_best":true,"max_redemptions_per_customer":1,"default_validity_days":30}'::jsonb
FROM cinema_hall h
WHERE NOT EXISTS (SELECT 1 FROM hall_settings hs WHERE hs.hall_id = h.id AND hs.section = 'offers');

-- ── Seed default user-level sections for every admin (if missing) ────
INSERT INTO user_settings (admin_id, section, value)
SELECT cau.id, 'notifications', '{"email_toggle":true,"sms_toggle":false,"push_toggle":false,"events":{"booking_confirmed":["email"],"booking_cancelled":["email"],"daily_report":["email"]}}'::jsonb
FROM cinema_admin_user cau
WHERE NOT EXISTS (SELECT 1 FROM user_settings us WHERE us.admin_id = cau.id AND us.section = 'notifications');

INSERT INTO user_settings (admin_id, section, value)
SELECT cau.id, 'analytics', '{"dashboard_widgets":["revenue","occupancy","upcoming_shows"],"date_range":"last_30_days","report_schedule":"never"}'::jsonb
FROM cinema_admin_user cau
WHERE NOT EXISTS (SELECT 1 FROM user_settings us WHERE us.admin_id = cau.id AND us.section = 'analytics');

INSERT INTO user_settings (admin_id, section, value)
SELECT cau.id, 'appearance', '{"sidebar_collapsed":false,"theme":"system"}'::jsonb
FROM cinema_admin_user cau
WHERE NOT EXISTS (SELECT 1 FROM user_settings us WHERE us.admin_id = cau.id AND us.section = 'appearance');


-- ---------------------------------------------------------------------------
-- 10. FOREIGN-KEY INDEXES & NAMED CONSTRAINTS
-- ---------------------------------------------------------------------------
-- Postgres does NOT auto-index the referencing side of a foreign key, so every
-- join and every ON DELETE CASCADE below would otherwise sequential-scan.

CREATE INDEX IF NOT EXISTS idx_bookings_show_id            ON bookings(show_id);
CREATE INDEX IF NOT EXISTS idx_bookings_payment_id         ON bookings(payment_id);
CREATE INDEX IF NOT EXISTS idx_screens_cinema_hall_id      ON screens(cinema_hall_id);
CREATE INDEX IF NOT EXISTS idx_shows_screen_id             ON shows(screen_id);
CREATE INDEX IF NOT EXISTS idx_cinema_hall_admin_id        ON cinema_hall(admin_id);
CREATE INDEX IF NOT EXISTS idx_payment_orders_customer_show ON payment_orders(customer_id, show_id, status);
CREATE INDEX IF NOT EXISTS idx_webhook_events_event_id     ON webhook_events(event_id);

-- bookings.payment_id is UNIQUE for payment idempotency. Named explicitly so a
-- database created before this script and one created by it agree.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'uq_bookings_payment_id')
     AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'bookings_payment_id_key') THEN
    ALTER TABLE bookings ADD CONSTRAINT uq_bookings_payment_id UNIQUE (payment_id);
  END IF;
END $$;

-- Columns the live schema has as NOT NULL
ALTER TABLE customer_sessions ALTER COLUMN created_at   SET NOT NULL;
ALTER TABLE customer_sessions ALTER COLUMN last_used_at SET NOT NULL;
ALTER TABLE webhook_events    ALTER COLUMN processed_at SET NOT NULL;

-- Optional hardening, NOT applied because it diverges from the live schema.
-- The Razorpay webhook handler always computes payload_hash, so this is safe
-- to run on both databases if you want the constraint:
--   ALTER TABLE webhook_events ALTER COLUMN payload_hash SET NOT NULL;


-- =============================================================================
-- SUPER ADMIN SEED
-- =============================================================================
-- Run AFTER this script. Replace the hash with one generated by:
--   node -e "import('bcrypt').then(b => b.default.hash('YourPassword', 10).then(console.log))"
--
-- INSERT INTO cinema_admin_user (email, password, name, phone, role, email_verified, email_verified_at)
-- VALUES (
--   'superadmin@cinemahall.com',
--   '$2b$10$<your-bcrypt-hash-here>',
--   'Super Admin',
--   '9999999999',
--   'superAdmin',
--   TRUE,
--   now()
-- );
-- =============================================================================
