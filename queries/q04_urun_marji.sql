-- q04_urun_marji.sql
-- Soru: Her urunun marji ve marj yuzdesi nedir?
-- Konu: SELECT icinde aritmetik, round(), NULLIF, avg()

-- a) En yuksek marj yuzdesine sahip 15 urun
SELECT id,
       sku,
       list_price,
       unit_cost,
       list_price - unit_cost AS marj,
       round(100.0 * (list_price - unit_cost) / NULLIF(list_price, 0), 2) AS marj_yuzde
FROM products
ORDER BY marj_yuzde DESC, id
LIMIT 15;

-- b) Zararina satilan urunler (marj negatif)
SELECT id,
       sku,
       list_price,
       unit_cost,
       list_price - unit_cost AS marj,
       round(100.0 * (list_price - unit_cost) / NULLIF(list_price, 0), 2) AS marj_yuzde
FROM products
WHERE unit_cost > list_price
ORDER BY marj, id;

-- c) Katalog genelinde ortalama marj yuzdesi
SELECT round(avg(100.0 * (list_price - unit_cost) / NULLIF(list_price, 0)), 2) AS ortalama_marj_yuzde,
       min(list_price - unit_cost) AS en_dusuk_marj,
       max(list_price - unit_cost) AS en_yuksek_marj
FROM products;
