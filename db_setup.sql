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
  password                TEXT        NOT NULL,
  name                    TEXT        NOT NULL,
  phone                   TEXT,
  role                    VARCHAR(20) NOT NULL DEFAULT 'admin'
                            CHECK (role IN ('admin', 'superAdmin')),
  email_verified          BOOLEAN     NOT NULL DEFAULT FALSE,
  email_verified_at       TIMESTAMPTZ,
  failed_login_attempts   INT         NOT NULL DEFAULT 0,
  account_locked_until    TIMESTAMPTZ,
  password_changed_at     TIMESTAMPTZ,
  last_login_at           TIMESTAMPTZ,
  created_at              TIMESTAMPTZ DEFAULT now()
);

-- Add auth-security columns to existing cinema_admin_user rows (idempotent)
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS email_verified        BOOLEAN     NOT NULL DEFAULT FALSE;
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS email_verified_at     TIMESTAMPTZ;
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS failed_login_attempts INT         NOT NULL DEFAULT 0;
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS account_locked_until  TIMESTAMPTZ;
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS password_changed_at   TIMESTAMPTZ;
ALTER TABLE cinema_admin_user ADD COLUMN IF NOT EXISTS last_login_at         TIMESTAMPTZ;

-- Mark all pre-existing admins as email-verified on fresh install
-- (They registered before this feature existed and have no verification token)
UPDATE cinema_admin_user
  SET email_verified = TRUE, email_verified_at = now()
  WHERE email_verified = FALSE;

-- ── Admin email-verification tokens ───────────────────────────────────────
-- Raw token sent in email; only the SHA-256 hash is stored here.
CREATE TABLE IF NOT EXISTS admin_verification_tokens (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id   UUID        NOT NULL REFERENCES cinema_admin_user(id) ON DELETE CASCADE,
  token_hash TEXT        NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_verification_tokens_admin_id
  ON admin_verification_tokens(admin_id);

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


CREATE TABLE IF NOT EXISTS cinema_hall (
  id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id     UUID         REFERENCES cinema_admin_user(id) ON DELETE CASCADE,
  name         TEXT         NOT NULL,
  location     TEXT         NOT NULL,
  district     TEXT         NOT NULL DEFAULT '',
  state        TEXT         NOT NULL DEFAULT '',
  latitude     NUMERIC(10,7),
  longitude    NUMERIC(10,7),
  phone        TEXT,
  description  TEXT,
  is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ  DEFAULT now()
);

-- Add columns to existing cinema_hall tables (idempotent)
ALTER TABLE cinema_hall ADD COLUMN IF NOT EXISTS latitude    NUMERIC(10,7);
ALTER TABLE cinema_hall ADD COLUMN IF NOT EXISTS longitude   NUMERIC(10,7);
ALTER TABLE cinema_hall ADD COLUMN IF NOT EXISTS phone       TEXT;
ALTER TABLE cinema_hall ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE cinema_hall ADD COLUMN IF NOT EXISTS is_active   BOOLEAN NOT NULL DEFAULT TRUE;

CREATE TABLE IF NOT EXISTS customers (
  id                      UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  email                   TEXT    UNIQUE NOT NULL,
  password                TEXT    NOT NULL,
  name                    TEXT    NOT NULL,
  phone                   TEXT,
  is_verified             BOOLEAN NOT NULL DEFAULT FALSE,
  district                TEXT    NOT NULL DEFAULT '',
  state                   TEXT    NOT NULL DEFAULT '',
  failed_login_attempts   INT     NOT NULL DEFAULT 0,
  account_locked_until    TIMESTAMPTZ,
  last_login_at           TIMESTAMPTZ,
  password_changed_at     TIMESTAMPTZ,
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

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
                      CHECK (status IN ('created', 'paid', 'failed', 'expired', 'refunded')),
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
  payment_id      VARCHAR(255) UNIQUE,                    -- UNIQUE constraint for idempotency
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
  event_id     VARCHAR(255) UNIQUE NOT NULL,      -- X-Razorpay-Event-Id
  event_type   VARCHAR(50)  NOT NULL,            -- e.g. payment.captured
  payload_hash VARCHAR(64)  NOT NULL,          -- SHA-256 of raw body
  processed_at TIMESTAMPTZ  DEFAULT now()
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
  placement  VARCHAR(20)  NOT NULL DEFAULT 'banner'
               CHECK (placement IN ('banner', 'side')),
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
-- 8. SETTINGS
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS settings (
  key        TEXT PRIMARY KEY,
  value      TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO settings (key, value) VALUES
  ('convenience_fee_per_ticket', '15'),
  ('gst_percentage', '18')
ON CONFLICT (key) DO NOTHING;


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
