-- q14_q15_en_cok_satan_urunler.sql
-- Soru 14: Adet bazinda en cok satan 10 urun.
-- Soru 15: Ciro bazinda en cok satan 10 urun. Ikisinin farki ne anlatiyor?
-- Kapsam: paid + shipped + delivered siparisler.

-- 14) Adet bazinda ilk 10
SELECT p.id,
       p.sku,
       p.list_price,
       sum(oi.quantity)                           AS satilan_adet,
       round(sum(oi.quantity * oi.unit_price), 2) AS ciro
FROM order_items oi
JOIN orders o   ON o.id = oi.order_id
JOIN products p ON p.id = oi.product_id
WHERE o.status IN ('paid', 'shipped', 'delivered')
GROUP BY p.id, p.sku, p.list_price
ORDER BY satilan_adet DESC, p.id
LIMIT 10;

-- 15) Ciro bazinda ilk 10
SELECT p.id,
       p.sku,
       p.list_price,
       sum(oi.quantity)                           AS satilan_adet,
       round(sum(oi.quantity * oi.unit_price), 2) AS ciro
FROM order_items oi
JOIN orders o   ON o.id = oi.order_id
JOIN products p ON p.id = oi.product_id
WHERE o.status IN ('paid', 'shipped', 'delivered')
GROUP BY p.id, p.sku, p.list_price
ORDER BY ciro DESC, p.id
LIMIT 10;
