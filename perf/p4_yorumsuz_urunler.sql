-- p4_yorumsuz_urunler.sql
-- Sorgu: q23 (c) -- teslim edilmis ama yorum almamis urunler.
-- Olculen sure: 1,76 sn (index yokken).
-- Tasarim: 2x2 -- (orijinal / yeniden yazilmis) x (index oncesi / sonrasi)

\echo '===== 1) ORIJINAL SORGU, FK indexleri YOK ====='
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.id, p.sku, p.list_price, p.is_active,
       (SELECT sum(oi.quantity)
          FROM order_items oi JOIN orders o ON o.id = oi.order_id
         WHERE oi.product_id = p.id AND o.status = 'delivered') AS teslim_edilen_adet
FROM products p
WHERE NOT EXISTS (SELECT 1 FROM reviews r WHERE r.product_id = p.id)
  AND EXISTS (SELECT 1 FROM order_items oi JOIN orders o ON o.id = oi.order_id
               WHERE oi.product_id = p.id AND o.status = 'delivered')
ORDER BY teslim_edilen_adet DESC, p.id
LIMIT 10;

\echo ''
\echo '===== 2) YENIDEN YAZILMIS, FK indexleri YOK ====='
EXPLAIN (ANALYZE, BUFFERS)
WITH teslim AS (
    SELECT oi.product_id, sum(oi.quantity) AS adet
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    WHERE o.status = 'delivered'
    GROUP BY oi.product_id
),
yorumlu AS (
    SELECT DISTINCT product_id FROM reviews
)
SELECT p.id, p.sku, p.list_price, p.is_active, t.adet AS teslim_edilen_adet
FROM products p
JOIN teslim t       ON t.product_id = p.id
LEFT JOIN yorumlu y ON y.product_id = p.id
WHERE y.product_id IS NULL
ORDER BY t.adet DESC, p.id
LIMIT 10;

\echo ''
\echo '===== 3) YABANCI ANAHTAR INDEXLERI EKLENIYOR ====='
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items (product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order   ON order_items (order_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product     ON reviews (product_id);
ANALYZE order_items;
ANALYZE reviews;

\echo ''
\echo '===== 4) ORIJINAL SORGU, indexler VAR ====='
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.id, p.sku, p.list_price, p.is_active,
       (SELECT sum(oi.quantity)
          FROM order_items oi JOIN orders o ON o.id = oi.order_id
         WHERE oi.product_id = p.id AND o.status = 'delivered') AS teslim_edilen_adet
FROM products p
WHERE NOT EXISTS (SELECT 1 FROM reviews r WHERE r.product_id = p.id)
  AND EXISTS (SELECT 1 FROM order_items oi JOIN orders o ON o.id = oi.order_id
               WHERE oi.product_id = p.id AND o.status = 'delivered')
ORDER BY teslim_edilen_adet DESC, p.id
LIMIT 10;

\echo ''
\echo '===== 5) YENIDEN YAZILMIS, indexler VAR ====='
EXPLAIN (ANALYZE, BUFFERS)
WITH teslim AS (
    SELECT oi.product_id, sum(oi.quantity) AS adet
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    WHERE o.status = 'delivered'
    GROUP BY oi.product_id
),
yorumlu AS (
    SELECT DISTINCT product_id FROM reviews
)
SELECT p.id, p.sku, p.list_price, p.is_active, t.adet AS teslim_edilen_adet
FROM products p
JOIN teslim t       ON t.product_id = p.id
LEFT JOIN yorumlu y ON y.product_id = p.id
WHERE y.product_id IS NULL
ORDER BY t.adet DESC, p.id
LIMIT 10;

\echo ''
\echo '===== 6) INDEX BOYUTLARI ====='
SELECT relname AS nesne, pg_size_pretty(pg_relation_size(oid)) AS boyut
FROM pg_class
WHERE relname IN ('order_items','reviews','idx_order_items_product',
                  'idx_order_items_order','idx_reviews_product','idx_inv_product')
ORDER BY pg_relation_size(oid) DESC;
