-- 004_payments_shipments.sql
-- Odeme hareketleri ve kargo gonderileri.

BEGIN;

CREATE TABLE payments (
    id        bigint        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id  bigint        NOT NULL,
    amount    numeric(12,2) NOT NULL,
    method    text          NOT NULL,
    status    text          NOT NULL,
    paid_at   timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT payments_order_fk FOREIGN KEY (order_id)
        REFERENCES orders (id) ON DELETE CASCADE,
    CONSTRAINT payments_method_valid CHECK (method IN ('card', 'transfer', 'cod')),
    CONSTRAINT payments_status_valid CHECK (status IN ('success', 'failed', 'refunded')),
    CONSTRAINT payments_amount_sign CHECK (
        (status = 'refunded' AND amount < 0)
        OR (status <> 'refunded' AND amount > 0)
    )
);

CREATE TABLE shipments (
    id           bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id     bigint      NOT NULL,
    carrier      text        NOT NULL,
    tracking_no  text,
    status       text        NOT NULL DEFAULT 'label_created',
    shipped_at   timestamptz,
    delivered_at timestamptz,

    CONSTRAINT shipments_order_fk FOREIGN KEY (order_id)
        REFERENCES orders (id) ON DELETE CASCADE,
    CONSTRAINT shipments_tracking_uq UNIQUE (tracking_no),
    CONSTRAINT shipments_status_valid CHECK (
        status IN ('label_created', 'in_transit', 'delivered', 'returned')
    ),
    CONSTRAINT shipments_date_order CHECK (
        delivered_at IS NULL OR shipped_at IS NULL OR delivered_at >= shipped_at
    )
);

COMMIT;
