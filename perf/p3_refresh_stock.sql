-- p3_refresh_stock.sql
-- Sorgu: seed/refresh_stock.sql -- stock_cached kolonunu defterden yeniden hesaplar.
-- Olculen sure: 13,2 sn (make seed icinde).
-- DIKKAT: EXPLAIN ANALYZE UPDATE'i gercekten calistirir; ROLLBACK ile geri aliyoruz.

\echo '===== YAVAS SURUM: her urun icin ayri alt sorgu ====='
BEGIN;
EXPLAIN (ANALYZE, BUFFERS)
UPDATE products p
SET stock_cached = COALESCE(
    (SELECT sum(m.quantity) FROM inventory_movements m WHERE m.product_id = p.id), 0);
ROLLBACK;

\echo ''
\echo '===== HIZLI SURUM: UPDATE ... FROM ile tek gecis ====='
BEGIN;
EXPLAIN (ANALYZE, BUFFERS)
UPDATE products p
SET stock_cached = COALESCE(d.bakiye, 0)
FROM (
    SELECT pr.id AS product_id,
           (SELECT sum(m.quantity) FROM inventory_movements m WHERE m.product_id = pr.id) AS bakiye
    FROM products pr
) d
WHERE d.product_id = p.id;
ROLLBACK;

\echo ''
\echo '===== EN HIZLI SURUM: defter bir kez gruplanip UPDATE ... FROM ====='
BEGIN;
EXPLAIN (ANALYZE, BUFFERS)
UPDATE products p
SET stock_cached = COALESCE(d.bakiye, 0)
FROM (
    SELECT pr.id AS product_id, dd.bakiye
    FROM products pr
    LEFT JOIN (
        SELECT product_id, sum(quantity) AS bakiye
        FROM inventory_movements
        GROUP BY product_id
    ) dd ON dd.product_id = pr.id
) d
WHERE d.product_id = p.id
  AND p.stock_cached IS DISTINCT FROM COALESCE(d.bakiye, 0);
ROLLBACK;
