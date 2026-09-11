-- q30_kategoride_ilk3_urun.sql
-- Soru: Her kategoride ciro bazinda ilk 3 urun hangileridir? (zorunlu)
-- Konu: window function, OVER, PARTITION BY, ROW_NUMBER / RANK / DENSE_RANK
-- Kapsam: paid + shipped + delivered siparisler.

-- a) OVER() ile GROUP BY farki: satirlar korunuyor mu?
SELECT p.id,
       p.category_id,
       p.list_price,
       round(avg(p.list_price) OVER (PARTITION BY p.category_id), 2) AS kategori_ort,
       round(p.list_price - avg(p.list_price) OVER (PARTITION BY p.category_id), 2) AS ortalamadan_fark
FROM products p
ORDER BY p.category_id, p.list_price DESC
LIMIT 10;

-- b) ROW_NUMBER vs RANK vs DENSE_RANK: esitlik oldugunda ne degisir?
SELECT category_id,
       count(*)                                        AS urun_sayisi,
       ROW_NUMBER() OVER (ORDER BY count(*) DESC)      AS row_number,
       RANK()       OVER (ORDER BY count(*) DESC)      AS rank,
       DENSE_RANK() OVER (ORDER BY count(*) DESC)      AS dense_rank
FROM products
GROUP BY category_id
ORDER BY urun_sayisi DESC, category_id
LIMIT 15;

-- c) ASIL SORU: her kategoride ciro bazinda ilk 3 urun
WITH urun_ciro AS (
    SELECT p.id,
           p.sku,
           p.category_id,
           c.name                              AS kategori,
           sum(oi.quantity)                    AS adet,
           sum(oi.quantity * oi.unit_price)    AS ciro
    FROM order_items oi
    JOIN orders o     ON o.id = oi.order_id
    JOIN products p   ON p.id = oi.product_id
    JOIN categories c ON c.id = p.category_id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY p.id, p.sku, p.category_id, c.name
),
siralanmis AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY ciro DESC, id) AS sira,
           sum(ciro)    OVER (PARTITION BY category_id)                        AS kategori_ciro
    FROM urun_ciro
)
SELECT kategori,
       sira,
       sku,
       adet,
       round(ciro, 2)                              AS ciro,
       round(100.0 * ciro / kategori_ciro, 2)      AS kategori_icindeki_pay
FROM siralanmis
WHERE sira <= 3
ORDER BY kategori, sira;
