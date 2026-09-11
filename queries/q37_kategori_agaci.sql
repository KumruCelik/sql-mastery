-- q37_kategori_agaci.sql
-- Soru: Kategori agacinda bir kokun altindaki tum urunler.
-- Konu: WITH RECURSIVE, anchor + yineleme, seviye takibi, dongu korumasi

-- a) Tum agaci seviye seviye dolas
WITH RECURSIVE agac AS (
    SELECT id, parent_id, name, slug, 0 AS seviye, name::text AS yol
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT c.id, c.parent_id, c.name, c.slug, a.seviye + 1, a.yol || ' > ' || c.name
    FROM categories c
    JOIN agac a ON c.parent_id = a.id
    WHERE a.seviye < 10          -- dongu korumasi
)
SELECT seviye, count(*) AS kategori_sayisi
FROM agac
GROUP BY seviye
ORDER BY seviye;

-- b) Bir kokun altindaki tum kategoriler ve yollari
WITH RECURSIVE agac AS (
    SELECT id, parent_id, name, 0 AS seviye, name::text AS yol
    FROM categories
    WHERE slug = 'elektronik'

    UNION ALL

    SELECT c.id, c.parent_id, c.name, a.seviye + 1, a.yol || ' > ' || c.name
    FROM categories c
    JOIN agac a ON c.parent_id = a.id
    WHERE a.seviye < 10
)
SELECT id, seviye, yol FROM agac ORDER BY yol;

-- c) Kok kategori bazinda ciro: agaci yukari toplama
WITH RECURSIVE agac AS (
    SELECT id AS kok_id, name AS kok_ad, id AS alt_id
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT a.kok_id, a.kok_ad, c.id
    FROM categories c
    JOIN agac a ON c.parent_id = a.alt_id
)
SELECT a.kok_ad                                            AS kok_kategori,
       count(DISTINCT p.id)                                AS urun_sayisi,
       sum(oi.quantity)                                    AS satilan_adet,
       round(sum(oi.quantity * oi.unit_price), 2)          AS ciro,
       round(100.0 * sum(oi.quantity * oi.unit_price)
             / sum(sum(oi.quantity * oi.unit_price)) OVER (), 2) AS ciro_payi
FROM agac a
JOIN products p    ON p.category_id = a.alt_id
JOIN order_items oi ON oi.product_id = p.id
JOIN orders o      ON o.id = oi.order_id
WHERE o.status IN ('paid', 'shipped', 'delivered')
GROUP BY a.kok_ad
ORDER BY ciro DESC;
