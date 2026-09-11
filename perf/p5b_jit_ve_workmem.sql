-- p5b_jit_ve_workmem.sql
-- Deney: kotu satir tahmini -> sisirilmis maliyet -> gereksiz JIT.
-- Ayrica work_mem artirarak hash tasmasini onlemek.

\echo '===== 1) VARSAYILAN AYARLAR ====='
SHOW jit;
SHOW work_mem;

\echo ''
\echo '===== 2) JIT KAPALI ====='
SET jit = off;
EXPLAIN (ANALYZE, BUFFERS)
WITH siparis_tutari AS (
    SELECT oi.order_id, sum(oi.quantity * oi.unit_price) AS sepet
    FROM order_items oi GROUP BY oi.order_id
),
indirim AS (SELECT order_id, sum(discount_applied) AS indirim FROM order_coupons GROUP BY order_id),
odeme   AS (SELECT order_id, sum(amount) AS odenen FROM payments WHERE status='success' GROUP BY order_id)
SELECT count(*) AS siparis,
       count(*) FILTER (WHERE abs(s.sepet - COALESCE(i.indirim,0) - COALESCE(od.odenen,0)) > 0.01) AS sapan
FROM siparis_tutari s
LEFT JOIN indirim i ON i.order_id = s.order_id
LEFT JOIN odeme od  ON od.order_id = s.order_id;

\echo ''
\echo '===== 3) JIT KAPALI + work_mem 64MB ====='
SET work_mem = '64MB';
EXPLAIN (ANALYZE, BUFFERS)
WITH siparis_tutari AS (
    SELECT oi.order_id, sum(oi.quantity * oi.unit_price) AS sepet
    FROM order_items oi GROUP BY oi.order_id
),
indirim AS (SELECT order_id, sum(discount_applied) AS indirim FROM order_coupons GROUP BY order_id),
odeme   AS (SELECT order_id, sum(amount) AS odenen FROM payments WHERE status='success' GROUP BY order_id)
SELECT count(*) AS siparis,
       count(*) FILTER (WHERE abs(s.sepet - COALESCE(i.indirim,0) - COALESCE(od.odenen,0)) > 0.01) AS sapan
FROM siparis_tutari s
LEFT JOIN indirim i ON i.order_id = s.order_id
LEFT JOIN odeme od  ON od.order_id = s.order_id;

\echo ''
\echo '===== 4) AYARLARI GERI AL ====='
RESET jit;
RESET work_mem;
SHOW jit;
SHOW work_mem;
