-- p5_gereksiz_join.sql
-- Sorgu: q47 -- odeme toplami, sepet eksi indirime esit mi?
-- Olculen sure: 0,94 sn.
-- Konu: gereksiz join, INNER vs LEFT join kaldirma, indexin fayda etmedigi durum

\echo '===== 1) ORIJINAL: siparis_tutari CTE icinde gereksiz orders join i var ====='
EXPLAIN (ANALYZE, BUFFERS)
WITH siparis_tutari AS (
    SELECT o.id AS order_id, sum(oi.quantity * oi.unit_price) AS sepet
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    GROUP BY o.id
),
indirim AS (
    SELECT order_id, sum(discount_applied) AS indirim FROM order_coupons GROUP BY order_id
),
odeme AS (
    SELECT order_id, sum(amount) AS odenen FROM payments WHERE status = 'success' GROUP BY order_id
)
SELECT count(*) AS siparis,
       count(*) FILTER (WHERE abs(s.sepet - COALESCE(i.indirim,0) - COALESCE(od.odenen,0)) > 0.01) AS sapan
FROM siparis_tutari s
LEFT JOIN indirim i ON i.order_id = s.order_id
LEFT JOIN odeme od  ON od.order_id = s.order_id;

\echo ''
\echo '===== 2) GEREKSIZ JOIN KALDIRILDI ====='
EXPLAIN (ANALYZE, BUFFERS)
WITH siparis_tutari AS (
    SELECT oi.order_id, sum(oi.quantity * oi.unit_price) AS sepet
    FROM order_items oi
    GROUP BY oi.order_id
),
indirim AS (
    SELECT order_id, sum(discount_applied) AS indirim FROM order_coupons GROUP BY order_id
),
odeme AS (
    SELECT order_id, sum(amount) AS odenen FROM payments WHERE status = 'success' GROUP BY order_id
)
SELECT count(*) AS siparis,
       count(*) FILTER (WHERE abs(s.sepet - COALESCE(i.indirim,0) - COALESCE(od.odenen,0)) > 0.01) AS sapan
FROM siparis_tutari s
LEFT JOIN indirim i ON i.order_id = s.order_id
LEFT JOIN odeme od  ON od.order_id = s.order_id;

\echo ''
\echo '===== 3a) INNER JOIN: Postgres kaldirabiliyor mu? ====='
EXPLAIN (ANALYZE)
SELECT oi.order_id, sum(oi.quantity * oi.unit_price)
FROM order_items oi
JOIN orders o ON o.id = oi.order_id
GROUP BY oi.order_id;

\echo ''
\echo '===== 3b) AYNI SORGU LEFT JOIN ile ====='
EXPLAIN (ANALYZE)
SELECT oi.order_id, sum(oi.quantity * oi.unit_price)
FROM order_items oi
LEFT JOIN orders o ON o.id = oi.order_id
GROUP BY oi.order_id;

\echo ''
\echo '===== 4) payments ve order_coupons uzerine index ekleniyor ====='
CREATE INDEX IF NOT EXISTS idx_payments_order      ON payments (order_id);
CREATE INDEX IF NOT EXISTS idx_order_coupons_order ON order_coupons (order_id);
ANALYZE payments;
ANALYZE order_coupons;

\echo ''
\echo '===== 5) DUZELTILMIS SORGU, indexler VAR ====='
EXPLAIN (ANALYZE, BUFFERS)
WITH siparis_tutari AS (
    SELECT oi.order_id, sum(oi.quantity * oi.unit_price) AS sepet
    FROM order_items oi
    GROUP BY oi.order_id
),
indirim AS (
    SELECT order_id, sum(discount_applied) AS indirim FROM order_coupons GROUP BY order_id
),
odeme AS (
    SELECT order_id, sum(amount) AS odenen FROM payments WHERE status = 'success' GROUP BY order_id
)
SELECT count(*) AS siparis,
       count(*) FILTER (WHERE abs(s.sepet - COALESCE(i.indirim,0) - COALESCE(od.odenen,0)) > 0.01) AS sapan
FROM siparis_tutari s
LEFT JOIN indirim i ON i.order_id = s.order_id
LEFT JOIN odeme od  ON od.order_id = s.order_id;
