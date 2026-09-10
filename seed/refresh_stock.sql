-- refresh_stock.sql
-- products.stock_cached turetilmis kolondur; degeri her zaman defterden gelir.
UPDATE products p
SET stock_cached = COALESCE(
    (SELECT sum(m.quantity) FROM inventory_movements m WHERE m.product_id = p.id),
    0
);
