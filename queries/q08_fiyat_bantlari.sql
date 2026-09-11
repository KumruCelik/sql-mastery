-- q08_fiyat_bantlari.sql
-- Soru: Urunleri fiyat bandina gore siniflandir (ucuz / orta / pahali).
-- Konu: CASE WHEN, bantlama, GROUP BY ile birlikte kullanim

-- a) Her urune bant etiketi
SELECT id, sku, list_price,
       CASE
           WHEN list_price < 50  THEN 'ucuz'
           WHEN list_price < 250 THEN 'orta'
           ELSE 'pahali'
       END AS fiyat_bandi
FROM products
ORDER BY list_price
LIMIT 10;

-- b) Bant bazinda dagilim. Siralama alfabetik degil, fiyata gore.
SELECT CASE
           WHEN list_price < 50  THEN 'ucuz'
           WHEN list_price < 250 THEN 'orta'
           ELSE 'pahali'
       END AS fiyat_bandi,
       count(*)                        AS urun_sayisi,
       round(100.0 * count(*) / (SELECT count(*) FROM products), 2) AS yuzde,
       min(list_price)                 AS en_dusuk,
       max(list_price)                 AS en_yuksek,
       round(avg(list_price), 2)       AS ortalama,
       round(avg(100.0 * (list_price - unit_cost) / NULLIF(list_price, 0)), 2) AS ort_marj_yuzde
FROM products
GROUP BY fiyat_bandi
ORDER BY min(list_price);
