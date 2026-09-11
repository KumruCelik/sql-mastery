-- q13_kategori_ciro.sql
-- Soru: Kategori bazinda toplam ciro nedir?
-- Konu: uc tablolu JOIN, GROUP BY, is kurali olarak durum filtresi
-- Kapsam: ciro = paid + shipped + delivered siparisler. created/cancelled/returned haric.
-- Kisit: urunler yaprak kategorilere bagli; kok kategori toplamlari icin 37. soru gerekir.

-- a) Yaprak kategori bazinda ciro
SELECT c.id                                                AS kategori_id,
       c.name                                              AS kategori,
       count(DISTINCT o.id)                                AS siparis_sayisi,
       sum(oi.quantity)                                    AS satilan_adet,
       round(sum(oi.quantity * oi.unit_price), 2)          AS ciro,
       round(sum(oi.quantity * (oi.unit_price - oi.unit_cost)), 2) AS brut_marj
FROM order_items oi
JOIN orders o     ON o.id  = oi.order_id
JOIN products p   ON p.id  = oi.product_id
JOIN categories c ON c.id  = p.category_id
WHERE o.status IN ('paid', 'shipped', 'delivered')
GROUP BY c.id, c.name
ORDER BY ciro DESC;

-- b) Toplam kontrol: kategorilerin toplami genel ciroya esit mi?
SELECT round(sum(oi.quantity * oi.unit_price), 2) AS genel_ciro
FROM order_items oi
JOIN orders o ON o.id = oi.order_id
WHERE o.status IN ('paid', 'shipped', 'delivered');
