-- q05_stogu_biten_aktif_urunler.sql
-- Soru: Stogu tukenmis (stock_cached <= 0) ama hala aktif gorunen urunler hangileri?
-- Konu: WHERE + AND, turetilmis kolonun yorumlanmasi

-- a) Kac tane?
SELECT count(*) AS stogu_biten_aktif
FROM products
WHERE stock_cached <= 0
  AND is_active = true;

-- b) Stok dagilimi: pozitif / sifir / negatif
SELECT count(*) AS pozitif_stok FROM products WHERE stock_cached > 0;
SELECT count(*) AS sifir_stok   FROM products WHERE stock_cached = 0;
SELECT count(*) AS negatif_stok FROM products WHERE stock_cached < 0;

-- c) En kotu 15: stogu en cok eksiye dusmus urunler
SELECT id, sku, list_price, stock_cached, is_active
FROM products
WHERE stock_cached < 0
ORDER BY stock_cached, id
LIMIT 15;
