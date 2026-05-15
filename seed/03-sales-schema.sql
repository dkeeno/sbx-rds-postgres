-- =============================================================================
-- 03-sales-schema.sql — CRM + Sales tables
-- =============================================================================
--
-- Domain: customers buy products, recorded as orders → order_items, billed
-- via invoices. Opportunities track the pre-sale pipeline.
--
-- Cross-schema FKs:
--   sales.opportunities.owner_id → hr.employees.id  (sales rep)
--   sales.invoices.created_by    → hr.employees.id  (back-office user)

\echo '== Building sales.* tables =='

-- ----------- products ------------------------------------------------------
CREATE TABLE IF NOT EXISTS sales.products (
  id              BIGSERIAL    PRIMARY KEY,
  sku             TEXT         NOT NULL UNIQUE CHECK (sku ~ '^[A-Z]{2,4}-[0-9]{4,6}$'),  -- e.g. HX-100234
  name            TEXT         NOT NULL,
  description     TEXT,
  category        TEXT         NOT NULL,                                                  -- 'industrial', 'consumer', 'service'
  list_price      NUMERIC(10,2) NOT NULL CHECK (list_price >= 0),
  cost            NUMERIC(10,2) NOT NULL CHECK (cost >= 0),
  weight_kg       NUMERIC(8,3),
  is_active       BOOLEAN      NOT NULL DEFAULT true,
  -- Tags as a TEXT[] array — postgres-native, indexable with GIN.
  tags            TEXT[]       NOT NULL DEFAULT '{}',
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_products_category   ON sales.products (category) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_products_tags       ON sales.products USING gin (tags);
COMMENT ON TABLE sales.products IS 'Product catalog. SKU pattern: 2-4 uppercase letters + 4-6 digits.';

-- ----------- customers (the company / account) ----------------------------
CREATE TABLE IF NOT EXISTS sales.customers (
  id              BIGSERIAL    PRIMARY KEY,
  account_number  TEXT         NOT NULL UNIQUE,                  -- 'ACC-00001'
  legal_name      TEXT         NOT NULL,
  trading_name    TEXT,                                          -- DBA / brand
  industry        TEXT,
  -- ISO-3166-1 alpha-2. Validated by trigger (07-*).
  country_code    CHAR(2)      NOT NULL,
  segment         TEXT         NOT NULL DEFAULT 'smb' CHECK (segment IN ('smb','mid_market','enterprise','strategic')),
  annual_revenue  NUMERIC(14,2),
  employee_count  INTEGER,
  status          TEXT         NOT NULL DEFAULT 'active' CHECK (status IN ('lead','active','suspended','churned')),
  is_credit_held  BOOLEAN      NOT NULL DEFAULT false,
  credit_limit    NUMERIC(12,2) NOT NULL DEFAULT 0,
  metadata        JSONB        NOT NULL DEFAULT '{}'::jsonb,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_customers_segment_status ON sales.customers (segment, status);
CREATE INDEX IF NOT EXISTS idx_customers_country        ON sales.customers (country_code);

-- ----------- contacts (people inside a customer org) ----------------------
CREATE TABLE IF NOT EXISTS sales.contacts (
  id              BIGSERIAL    PRIMARY KEY,
  customer_id     BIGINT       NOT NULL REFERENCES sales.customers(id) ON DELETE CASCADE,
  first_name      TEXT         NOT NULL,
  last_name       TEXT         NOT NULL,
  email           CITEXT       NOT NULL,
  phone           TEXT,
  job_title       TEXT,
  is_primary      BOOLEAN      NOT NULL DEFAULT false,
  opted_in        BOOLEAN      NOT NULL DEFAULT false,            -- GDPR-style consent flag
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  UNIQUE (customer_id, email)
);
CREATE INDEX IF NOT EXISTS idx_contacts_customer ON sales.contacts (customer_id);
-- Partial unique index: only one primary contact per customer.
CREATE UNIQUE INDEX IF NOT EXISTS idx_contacts_one_primary
  ON sales.contacts (customer_id) WHERE is_primary = true;

-- ----------- opportunities (sales pipeline) -------------------------------
CREATE TABLE IF NOT EXISTS sales.opportunities (
  id              BIGSERIAL    PRIMARY KEY,
  customer_id     BIGINT       NOT NULL REFERENCES sales.customers(id),
  owner_id        BIGINT       NOT NULL REFERENCES hr.employees(id),    -- cross-schema FK to sales rep
  name            TEXT         NOT NULL,
  stage           TEXT         NOT NULL DEFAULT 'prospect' CHECK (stage IN ('prospect','qualified','proposal','negotiation','won','lost')),
  amount          NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  probability_pct INTEGER      NOT NULL DEFAULT 10 CHECK (probability_pct BETWEEN 0 AND 100),
  expected_close  DATE,
  actual_close    DATE,
  loss_reason     TEXT,                                                  -- only when stage = 'lost'
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_opps_owner_stage  ON sales.opportunities (owner_id, stage);
CREATE INDEX IF NOT EXISTS idx_opps_close_open   ON sales.opportunities (expected_close) WHERE stage NOT IN ('won','lost');

-- ----------- orders --------------------------------------------------------
CREATE TABLE IF NOT EXISTS sales.orders (
  id              BIGSERIAL    PRIMARY KEY,
  order_number    TEXT         NOT NULL UNIQUE,                          -- 'SO-2026-000123'
  customer_id     BIGINT       NOT NULL REFERENCES sales.customers(id),
  opportunity_id  BIGINT       REFERENCES sales.opportunities(id),       -- nullable: walk-up sale
  ordered_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  status          TEXT         NOT NULL DEFAULT 'open' CHECK (status IN ('open','confirmed','shipped','delivered','cancelled')),
  shipping_address JSONB       NOT NULL DEFAULT '{}'::jsonb,
  billing_address  JSONB       NOT NULL DEFAULT '{}'::jsonb,
  total_amount    NUMERIC(12,2) NOT NULL DEFAULT 0,                      -- maintained by trigger from order_items
  currency        CHAR(3)      NOT NULL DEFAULT 'USD' CHECK (currency = upper(currency)),
  notes           TEXT,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_orders_customer_status ON sales.orders (customer_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_ordered_at      ON sales.orders (ordered_at DESC);

-- ----------- order_items ---------------------------------------------------
CREATE TABLE IF NOT EXISTS sales.order_items (
  id              BIGSERIAL    PRIMARY KEY,
  order_id        BIGINT       NOT NULL REFERENCES sales.orders(id) ON DELETE CASCADE,
  product_id      BIGINT       NOT NULL REFERENCES sales.products(id),
  quantity        INTEGER      NOT NULL CHECK (quantity > 0),
  unit_price      NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
  discount_pct    NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (discount_pct BETWEEN 0 AND 100),
  -- Generated column: line total. Free for queries.
  line_total      NUMERIC(12,2) GENERATED ALWAYS AS (
    quantity * unit_price * (1 - discount_pct / 100.0)
  ) STORED,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  UNIQUE (order_id, product_id)                                          -- prevent duplicate lines
);
CREATE INDEX IF NOT EXISTS idx_order_items_order   ON sales.order_items (order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON sales.order_items (product_id);

-- ----------- invoices ------------------------------------------------------
CREATE TABLE IF NOT EXISTS sales.invoices (
  id              BIGSERIAL    PRIMARY KEY,
  invoice_number  TEXT         NOT NULL UNIQUE,                          -- 'INV-2026-00001'
  order_id        BIGINT       NOT NULL UNIQUE REFERENCES sales.orders(id),  -- 1:1 for sandbox simplicity
  issued_at       DATE         NOT NULL DEFAULT CURRENT_DATE,
  due_at          DATE         NOT NULL CHECK (due_at >= issued_at),
  status          TEXT         NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','sent','paid','overdue','void')),
  subtotal        NUMERIC(12,2) NOT NULL,
  tax_amount      NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_amount    NUMERIC(12,2) NOT NULL,
  paid_amount     NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
  paid_at         DATE,
  created_by      BIGINT       NOT NULL REFERENCES hr.employees(id),     -- back-office user (cross-schema)
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_invoices_status_due ON sales.invoices (status, due_at);

\echo '== sales.* tables ready =='
