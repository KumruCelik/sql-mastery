-- q23_yorumsuz_urunler.sql
-- Soru: Hic yorum almamis urunler hangileri, ve neden yorum almamislar?
-- Konu: anti-join (NOT EXISTS), iki kosulun kesisimi

-- a) Kac urun hic yorum almamis?
SELECT count(*) AS yorumsuz_urun
FROM products p
WHERE NOT EXISTS (SELECT 1 FROM reviews r WHERE r.product_id = p.id);

-- b) Bu urunler satildi mi? Uc gruba ayir.
SELECT CASE
           WHEN NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.id)
               THEN '1 - hic siparise girmemis'
           WHEN NOT EXISTS (
               SELECT 1 FROM order_items oi
               JOIN orders o ON o.id = oi.order_id
               WHERE oi.product_id = p.id AND o.status = 'delivered')
               THEN '2 - siparise girmis ama hic teslim edilmemis'
           ELSE '3 - teslim edilmis ama yorum almamis'
       END AS grup,
       count(*) AS urun_sayisi
FROM products p
WHERE NOT EXISTS (SELECT 1 FROM reviews r WHERE r.product_id = p.id)
GROUP BY grup
ORDER BY grup;

-- c) Ornekler: teslim edilmis ama yorum almamis urunler
SELECT p.id, p.sku, p.list_price, p.is_active,
       (SELECT sum(oi.quantity)
          FROM order_items oi JOIN orders o ON o.id = oi.order_id
         WHERE oi.product_id = p.id AND o.status = 'delivered') AS teslim_edilen_adet
FROM products p
WHERE NOT EXISTS (SELECT 1 FROM reviews r WHERE r.product_id = p.id)
  AND EXISTS (
      SELECT 1 FROM order_items oi JOIN orders o ON o.id = oi.order_id
       WHERE oi.product_id = p.id AND o.status = 'delivered')
ORDER BY teslim_edilen_adet DESC, p.id
LIMIT 10;
