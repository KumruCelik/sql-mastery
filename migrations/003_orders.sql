-- 003_orders.sql
-- Siparis basligi ve siparis kalemleri.

BEGIN;

CREATE TABLE orders (
    id               bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          bigint      NOT NULL,
    status           text        NOT NULL DEFAULT 'created',
    shipping_country text,
    ordered_at       timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT orders_user_fk FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE RESTRICT,
    CONSTRAINT orders_status_valid CHECK (
        status IN ('created', 'paid', 'shipped', 'delivered', 'cancelled', 'returned')
    )
);

CREATE TABLE order_items (
    id          bigint        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id    bigint        NOT NULL,
    product_id  bigint        NOT NULL,
    quantity    integer       NOT NULL,
    unit_price  numeric(12,2) NOT NULL,
    unit_cost   numeric(12,2) NOT NULL,

    CONSTRAINT order_items_order_fk FOREIGN KEY (order_id)
        REFERENCES orders (id) ON DELETE CASCADE,
    CONSTRAINT order_items_product_fk FOREIGN KEY (product_id)
        REFERENCES products (id) ON DELETE RESTRICT,
    CONSTRAINT order_items_qty_pos       CHECK (quantity > 0),
    CONSTRAINT order_items_price_nonneg  CHECK (unit_price >= 0),
    CONSTRAINT order_items_cost_nonneg   CHECK (unit_cost >= 0),
    CONSTRAINT order_items_order_product_uq UNIQUE (order_id, product_id)
);

COMMIT;
