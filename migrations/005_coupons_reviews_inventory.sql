-- 005_coupons_reviews_inventory.sql
-- Kuponlar, siparis-kupon baglantisi, yorumlar ve stok defteri.

BEGIN;

CREATE TABLE coupons (
    id             bigint        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code           text          NOT NULL,
    discount_type  text          NOT NULL,
    discount_value numeric(12,2) NOT NULL,
    max_uses       integer,
    valid_from     timestamptz   NOT NULL,
    valid_to       timestamptz   NOT NULL,

    CONSTRAINT coupons_code_uq       UNIQUE (code),
    CONSTRAINT coupons_type_valid    CHECK (discount_type IN ('percent', 'amount')),
    CONSTRAINT coupons_value_pos     CHECK (discount_value > 0),
    CONSTRAINT coupons_percent_range CHECK (discount_type <> 'percent' OR discount_value <= 100),
    CONSTRAINT coupons_max_uses_pos  CHECK (max_uses IS NULL OR max_uses > 0),
    CONSTRAINT coupons_valid_range   CHECK (valid_to > valid_from)
);

CREATE TABLE order_coupons (
    order_id         bigint        NOT NULL,
    coupon_id        bigint        NOT NULL,
    discount_applied numeric(12,2) NOT NULL,

    CONSTRAINT order_coupons_pk PRIMARY KEY (order_id, coupon_id),
    CONSTRAINT order_coupons_order_fk FOREIGN KEY (order_id)
        REFERENCES orders (id) ON DELETE CASCADE,
    CONSTRAINT order_coupons_coupon_fk FOREIGN KEY (coupon_id)
        REFERENCES coupons (id) ON DELETE RESTRICT,
    CONSTRAINT order_coupons_amount_pos CHECK (discount_applied > 0)
);

CREATE TABLE reviews (
    id         bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    bigint      NOT NULL,
    product_id bigint      NOT NULL,
    rating     integer     NOT NULL,
    body       text,
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT reviews_user_fk FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT reviews_product_fk FOREIGN KEY (product_id)
        REFERENCES products (id) ON DELETE CASCADE,
    CONSTRAINT reviews_rating_range CHECK (rating BETWEEN 1 AND 5)
);

CREATE TABLE inventory_movements (
    id            bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id    bigint      NOT NULL,
    order_id      bigint,
    movement_type text        NOT NULL,
    quantity      integer     NOT NULL,
    occurred_at   timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT inv_product_fk FOREIGN KEY (product_id)
        REFERENCES products (id) ON DELETE RESTRICT,
    CONSTRAINT inv_order_fk FOREIGN KEY (order_id)
        REFERENCES orders (id) ON DELETE RESTRICT,
    CONSTRAINT inv_type_valid   CHECK (movement_type IN ('purchase', 'sale', 'return', 'adjustment')),
    CONSTRAINT inv_qty_nonzero  CHECK (quantity <> 0),
    CONSTRAINT inv_sale_negative CHECK (movement_type <> 'sale' OR quantity < 0),
    CONSTRAINT inv_order_link CHECK (
        (movement_type IN ('sale', 'return') AND order_id IS NOT NULL)
        OR (movement_type IN ('purchase', 'adjustment') AND order_id IS NULL)
    )
);

COMMIT;
