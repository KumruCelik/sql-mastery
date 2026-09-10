-- 002_products.sql
-- Urun katalogu. categories'e bagli oldugu icin 001'den sonra calisir.

BEGIN;

CREATE TABLE products (
    id            bigint        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id   bigint        NOT NULL,
    sku           text          NOT NULL,
    name          text          NOT NULL,
    list_price    numeric(12,2) NOT NULL,
    unit_cost     numeric(12,2) NOT NULL,
    stock_cached  integer       NOT NULL DEFAULT 0,
    is_active     boolean       NOT NULL DEFAULT true,
    created_at    timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT products_sku_uq      UNIQUE (sku),
    CONSTRAINT products_category_fk FOREIGN KEY (category_id)
        REFERENCES categories (id) ON DELETE RESTRICT,
    CONSTRAINT products_price_pos   CHECK (list_price > 0),
    CONSTRAINT products_cost_nonneg CHECK (unit_cost >= 0),
    CONSTRAINT products_name_not_blank CHECK (length(btrim(name)) > 0)
);

COMMIT;
