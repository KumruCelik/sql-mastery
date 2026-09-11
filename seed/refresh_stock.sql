-- refresh_stock.sql
-- products.stock_cached turetilmis kolondur; degeri her zaman defterden gelir (K-003).
--
-- Performans notu (Odev 3.3 / P3):
--   Ilk surum her urun icin ayri bir bagintili alt sorgu calistiriyordu: 13,2 sn.
--   Bu surum defteri bir kez gruplar ve degeri zaten dogru olan satirlari atlar: 31 ms.
--   IS DISTINCT FROM kosulu MVCC geregi gereksiz satir surumu yazilmasini onler.

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
