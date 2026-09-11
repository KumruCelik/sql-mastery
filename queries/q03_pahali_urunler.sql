-- q03_pahali_urunler.sql
-- Soru: Liste fiyati 500'un uzerindeki urunler, pahalidan ucuza.
-- Konu: WHERE + ORDER BY (cok kolonlu, deterministik), LIMIT

-- a) Kac tane var?
SELECT count(*) AS pahali_urun_sayisi
FROM products
WHERE list_price > 500;

-- b) En pahali 15 urun. id ile deterministik siralama.
SELECT id, sku, name, list_price, unit_cost, stock_cached
FROM products
WHERE list_price > 500
ORDER BY list_price DESC, id
LIMIT 15;

-- c) Ayni filtre, kategori icinde pahalidan ucuza
SELECT category_id, sku, list_price
FROM products
WHERE list_price > 500
ORDER BY category_id, list_price DESC, id
LIMIT 20;
