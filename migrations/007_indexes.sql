-- 007_indexes.sql
-- Odev 3.3 olcumleri sonucunda eklenen indexler.
-- Postgres yabanci anahtar kolonlarina otomatik index acmaz; bunlar elle eklenir.
-- Gerekce ve olcumler: ai-engineer-journey/bolum03/odev-3.3/olcumler.md

BEGIN;

-- Stok defteri: urun bazinda erisim (P1, P2)
CREATE INDEX IF NOT EXISTS idx_inv_product        ON inventory_movements (product_id);

-- Siparis kalemleri: her iki yabanci anahtar da sorgulaniyor (P4, P5)
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items (product_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order   ON order_items (order_id);

-- Yorumlar: urun bazinda erisim (P4)
CREATE INDEX IF NOT EXISTS idx_reviews_product     ON reviews (product_id);

-- Odemeler ve kuponlar: siparis bazinda gruplama (P5)
CREATE INDEX IF NOT EXISTS idx_payments_order      ON payments (order_id);
CREATE INDEX IF NOT EXISTS idx_order_coupons_order ON order_coupons (order_id);

-- Deneme amacli olusturulan indexler kaldiriliyor (P6).
-- Uretimde ihtiyac duyulursa gerekcesiyle birlikte yeniden eklenir.
DROP INDEX IF EXISTS idx_products_sku_lower;
DROP INDEX IF EXISTS idx_products_active;
DROP INDEX IF EXISTS idx_products_sku_pattern;

COMMIT;
