-- q12_siparis_vermeyen_kullanicilar.sql
-- Soru: Hic siparis vermemis kullanicilar kimler?
-- Konu: LEFT JOIN + IS NULL (anti-join), NOT EXISTS, NOT IN ve NULL tuzagi

-- a) LEFT JOIN + IS NULL
SELECT count(*) AS siparis_vermeyen
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE o.id IS NULL;

-- b) Ayni soru NOT EXISTS ile
SELECT count(*) AS siparis_vermeyen
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);

-- c) Ayni soru NOT IN ile (orders.user_id NOT NULL oldugu icin burada guvenli)
SELECT count(*) AS siparis_vermeyen
FROM users u
WHERE u.id NOT IN (SELECT user_id FROM orders);

-- d) Ornek kullanicilar
SELECT u.id, u.email, u.country, u.created_at::date AS kayit
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE o.id IS NULL
ORDER BY u.created_at DESC
LIMIT 10;

-- e) NOT IN TUZAGI CANLI: inventory_movements.order_id nullable
--    Dogru soru: hic stok hareketi olmayan siparis var mi?
SELECT count(*) AS not_exists_ile
FROM orders o
WHERE NOT EXISTS (SELECT 1 FROM inventory_movements m WHERE m.order_id = o.id);

SELECT count(*) AS not_in_ile
FROM orders o
WHERE o.id NOT IN (SELECT order_id FROM inventory_movements);

-- f) Tuzagin sebebi: listede kac NULL var?
SELECT count(*)                        AS toplam_hareket,
       count(order_id)                 AS order_id_dolu,
       count(*) - count(order_id)      AS order_id_null
FROM inventory_movements;
