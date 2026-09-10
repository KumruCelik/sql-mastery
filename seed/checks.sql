-- checks.sql
-- Odev 3.1 veri kalitesi kontrolleri.
-- Her sorgunun ustunde "beklenen" yaziyor; sapma varsa arastirilir.

\echo '--- 1) stock_cached defter toplamina esit mi?  (beklenen: 0 satir)'
SELECT p.id, p.stock_cached,
       COALESCE((SELECT sum(m.quantity) FROM inventory_movements m WHERE m.product_id = p.id), 0) AS defter
FROM products p
WHERE p.stock_cached <> COALESCE(
        (SELECT sum(m.quantity) FROM inventory_movements m WHERE m.product_id = p.id), 0);

\echo '--- 2) Kargo kaydi olmayan shipped/delivered siparisler  (beklenen: ~30, kasitli anomali)'
SELECT count(*) AS kargosuz_siparis
FROM orders o
WHERE o.status IN ('shipped', 'delivered', 'returned')
  AND NOT EXISTS (SELECT 1 FROM shipments s WHERE s.order_id = o.id);

\echo '--- 3) Maliyeti liste fiyatindan yuksek urunler  (beklenen: 10, kasitli anomali)'
SELECT count(*) AS zararina_urun
FROM products
WHERE unit_cost > list_price;

\echo '--- 4) Ayni kullanici + ayni urun icin birden fazla yorum  (beklenen: ~200, K-005 geregi serbest)'
SELECT count(*) AS tekrarli_cift
FROM (
    SELECT user_id, product_id
    FROM reviews
    GROUP BY user_id, product_id
    HAVING count(*) > 1
) t;

\echo '--- 5) Eksik veri oranlari  (beklenen: her biri ~%5)'
SELECT
    round(100.0 * count(*) FILTER (WHERE country IS NULL) / count(*), 2) AS users_country_bos
FROM users;

SELECT
    round(100.0 * count(*) FILTER (WHERE tracking_no IS NULL) / count(*), 2) AS shipments_takip_bos
FROM shipments;

SELECT
    round(100.0 * count(*) FILTER (WHERE body IS NULL) / count(*), 2) AS reviews_metin_bos
FROM reviews;

\echo '--- 6) Tablo satir sayilari'
SELECT 'users' AS tablo, count(*) FROM users
UNION ALL SELECT 'categories', count(*) FROM categories
UNION ALL SELECT 'products', count(*) FROM products
UNION ALL SELECT 'coupons', count(*) FROM coupons
UNION ALL SELECT 'orders', count(*) FROM orders
UNION ALL SELECT 'order_items', count(*) FROM order_items
UNION ALL SELECT 'payments', count(*) FROM payments
UNION ALL SELECT 'shipments', count(*) FROM shipments
UNION ALL SELECT 'order_coupons', count(*) FROM order_coupons
UNION ALL SELECT 'reviews', count(*) FROM reviews
UNION ALL SELECT 'inventory_movements', count(*) FROM inventory_movements;
