-- p2_index_etkisi.sql
-- Deney: yavas sorguyu degistirmeden, sadece index ekleyerek ne kadar kazanilir?
-- Karsilastirma: P1'deki yeniden yazim 54 ms vermisti.

\echo '===== 1) INDEX YOKKEN (referans) ====='
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.id FROM products p
WHERE p.stock_cached <> COALESCE(
        (SELECT sum(m.quantity) FROM inventory_movements m WHERE m.product_id = p.id), 0);

\echo ''
\echo '===== 2) INDEX OLUSTURULUYOR ====='
CREATE INDEX IF NOT EXISTS idx_inv_product ON inventory_movements (product_id);
ANALYZE inventory_movements;

\echo ''
\echo '===== 3) AYNI SORGU, INDEX VARKEN ====='
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.id FROM products p
WHERE p.stock_cached <> COALESCE(
        (SELECT sum(m.quantity) FROM inventory_movements m WHERE m.product_id = p.id), 0);

\echo ''
\echo '===== 4) YENIDEN YAZILMIS SURUM, INDEX VARKEN ====='
EXPLAIN (ANALYZE, BUFFERS)
WITH defter AS (
    SELECT product_id, sum(quantity) AS bakiye
    FROM inventory_movements GROUP BY product_id
)
SELECT p.id FROM products p
LEFT JOIN defter d ON d.product_id = p.id
WHERE p.stock_cached <> COALESCE(d.bakiye, 0);

\echo ''
\echo '===== 5) INDEX BOYUTU ====='
SELECT pg_size_pretty(pg_relation_size('inventory_movements'))      AS tablo,
       pg_size_pretty(pg_relation_size('idx_inv_product'))          AS index;
