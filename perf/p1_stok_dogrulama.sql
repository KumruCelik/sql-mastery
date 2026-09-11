-- p1_stok_dogrulama.sql
-- Sorgu: stock_cached kolonu defter toplamiyla uyusmayan urunler.
-- checks.sql'deki 1. kontrol. Olculen sure: 11,1 sn.

\echo '===== YAVAS SURUM: bagintili alt sorgu ====='
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.id, p.stock_cached
FROM products p
WHERE p.stock_cached <> COALESCE(
        (SELECT sum(m.quantity) FROM inventory_movements m WHERE m.product_id = p.id), 0);

\echo ''
\echo '===== HIZLI SURUM: defter bir kez gruplanip LEFT JOIN ====='
EXPLAIN (ANALYZE, BUFFERS)
WITH defter AS (
    SELECT product_id, sum(quantity) AS bakiye
    FROM inventory_movements
    GROUP BY product_id
)
SELECT p.id, p.stock_cached
FROM products p
LEFT JOIN defter d ON d.product_id = p.id
WHERE p.stock_cached <> COALESCE(d.bakiye, 0);
