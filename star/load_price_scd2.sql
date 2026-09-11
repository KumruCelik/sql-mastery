-- load_price_scd2.sql
-- Fiyat mini-boyutunun SCD2 birlestirmesi. Idempotent.

BEGIN;

-- A) Fiyati/maliyeti degismis guncel surumleri kapat
UPDATE star.dim_product_price d
SET valid_to = now(), is_current = false
FROM products p
WHERE d.product_id = p.id
  AND d.is_current
  AND (d.list_price, d.unit_cost) IS DISTINCT FROM (p.list_price, p.unit_cost);

-- B) Guncel surumu olmayan her urun icin yeni surum ac
INSERT INTO star.dim_product_price (product_id, list_price, unit_cost, valid_from, valid_to, is_current)
SELECT p.id, p.list_price, p.unit_cost,
       CASE WHEN EXISTS (SELECT 1 FROM star.dim_product_price d2 WHERE d2.product_id = p.id)
            THEN now() ELSE '-infinity'::timestamptz END,
       NULL, true
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM star.dim_product_price d WHERE d.product_id = p.id AND d.is_current
);

COMMIT;
