-- load_star.sql
-- Odev 3.4: analitik katmani OLTP'den doldurur.
-- IDEMPOTENT: tekrar tekrar calistirilabilir, veri bozulmaz, satir cogalmaz.
-- Calistirma sirasi bagimlilik sirasidir: dim_date -> dim_customer -> dim_product -> fct_orders -> fct_order_items

BEGIN;

-- ============================================================ 1) dim_date
-- Idempotent: ON CONFLICT DO NOTHING
INSERT INTO star.dim_date (date_key, tarih, yil, ceyrek, ay, ay_adi, gun, hafta_gunu, hafta_sonu, ay_basi)
SELECT to_char(g, 'YYYYMMDD')::int,
       g::date,
       EXTRACT(YEAR    FROM g)::int,
       EXTRACT(QUARTER FROM g)::int,
       EXTRACT(MONTH   FROM g)::int,
       btrim(to_char(g, 'Month')),
       EXTRACT(DAY     FROM g)::int,
       EXTRACT(DOW     FROM g)::int,
       EXTRACT(DOW     FROM g) IN (0, 6),
       date_trunc('month', g)::date
FROM generate_series(
        (SELECT min(ordered_at)::date FROM orders),
        (SELECT max(ordered_at)::date FROM orders),
        interval '1 day') AS g
ON CONFLICT (date_key) DO NOTHING;

-- ======================================================== 2) dim_customer (SCD2)
-- Adim A: OLTP'de degismis olan guncel satirlari kapat.
UPDATE star.dim_customer d
SET valid_to   = now(),
    is_current = false
FROM users u
WHERE d.user_id = u.id
  AND d.is_current
  AND (d.email, d.full_name, d.country, d.is_active)
      IS DISTINCT FROM (u.email, u.full_name, u.country, u.is_active);

-- Adim B: guncel satiri olmayan her kullanici icin yeni surum ac.
--   - Ilk kez ekleniyorsa valid_from = '-infinity' (gecmisteki tum siparisler bu surume duser)
--   - Daha once surumu varsa valid_from = now()
INSERT INTO star.dim_customer (user_id, email, full_name, country, is_active, valid_from, valid_to, is_current)
SELECT u.id, u.email, u.full_name, u.country, u.is_active,
       CASE WHEN EXISTS (SELECT 1 FROM star.dim_customer d2 WHERE d2.user_id = u.id)
            THEN now() ELSE '-infinity'::timestamptz END,
       NULL,
       true
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM star.dim_customer d WHERE d.user_id = u.id AND d.is_current
);

-- ======================================================== 3) dim_product (SCD1)
-- Idempotent: ON CONFLICT DO UPDATE (upsert). Degisiklikler uzerine yazilir.
INSERT INTO star.dim_product (product_id, sku, urun_adi, kategori_id, kategori_adi, kok_kategori,
                              list_price, unit_cost, aktif)
SELECT p.id, p.sku, p.name, p.category_id, c.name,
       COALESCE(kok.name, c.name),
       p.list_price, p.unit_cost, p.is_active
FROM products p
JOIN categories c        ON c.id = p.category_id
LEFT JOIN categories kok ON kok.id = c.parent_id
ON CONFLICT (product_id) DO UPDATE
SET sku          = EXCLUDED.sku,
    urun_adi     = EXCLUDED.urun_adi,
    kategori_id  = EXCLUDED.kategori_id,
    kategori_adi = EXCLUDED.kategori_adi,
    kok_kategori = EXCLUDED.kok_kategori,
    list_price   = EXCLUDED.list_price,
    unit_cost    = EXCLUDED.unit_cost,
    aktif        = EXCLUDED.aktif;

-- ========================================================= 4) fct_orders
-- SCD2'nin asil kullanimi burada: siparis, verildigi ANDA gecerli olan musteri surumune baglanir.
INSERT INTO star.fct_orders (order_id, customer_sk, date_key, ordered_at, status, shipping_country,
                             kalem_sayisi, brut_tutar, indirim_tutar, net_tutar, maliyet_tutar, brut_marj)
SELECT o.id,
       d.customer_sk,
       to_char(o.ordered_at, 'YYYYMMDD')::int,
       o.ordered_at,
       o.status,
       o.shipping_country,
       COALESCE(i.kalem, 0),
       COALESCE(i.brut, 0),
       COALESCE(k.indirim, 0),
       COALESCE(i.brut, 0) - COALESCE(k.indirim, 0),
       COALESCE(i.maliyet, 0),
       COALESCE(i.brut, 0) - COALESCE(i.maliyet, 0) - COALESCE(k.indirim, 0)
FROM orders o
JOIN star.dim_customer d
  ON d.user_id = o.user_id
 AND o.ordered_at >= d.valid_from
 AND o.ordered_at <  COALESCE(d.valid_to, 'infinity'::timestamptz)
LEFT JOIN (
    SELECT order_id,
           count(*)                       AS kalem,
           sum(quantity * unit_price)     AS brut,
           sum(quantity * unit_cost)      AS maliyet
    FROM order_items GROUP BY order_id
) i ON i.order_id = o.id
LEFT JOIN (
    SELECT order_id, sum(discount_applied) AS indirim
    FROM order_coupons GROUP BY order_id
) k ON k.order_id = o.id
ON CONFLICT (order_id) DO UPDATE
SET customer_sk      = EXCLUDED.customer_sk,
    date_key         = EXCLUDED.date_key,
    status           = EXCLUDED.status,
    shipping_country = EXCLUDED.shipping_country,
    kalem_sayisi     = EXCLUDED.kalem_sayisi,
    brut_tutar       = EXCLUDED.brut_tutar,
    indirim_tutar    = EXCLUDED.indirim_tutar,
    net_tutar        = EXCLUDED.net_tutar,
    maliyet_tutar    = EXCLUDED.maliyet_tutar,
    brut_marj        = EXCLUDED.brut_marj;

-- ==================================================== 5) fct_order_items
INSERT INTO star.fct_order_items (order_item_id, order_id, customer_sk, product_sk, date_key, status,
                                  adet, birim_fiyat, birim_maliyet, brut_tutar, maliyet_tutar, brut_marj)
SELECT oi.id, oi.order_id, f.customer_sk, dp.product_sk, f.date_key, f.status,
       oi.quantity, oi.unit_price, oi.unit_cost,
       oi.quantity * oi.unit_price,
       oi.quantity * oi.unit_cost,
       oi.quantity * (oi.unit_price - oi.unit_cost)
FROM order_items oi
JOIN star.fct_orders f  ON f.order_id   = oi.order_id
JOIN star.dim_product dp ON dp.product_id = oi.product_id
ON CONFLICT (order_item_id) DO UPDATE
SET customer_sk   = EXCLUDED.customer_sk,
    product_sk    = EXCLUDED.product_sk,
    date_key      = EXCLUDED.date_key,
    status        = EXCLUDED.status,
    adet          = EXCLUDED.adet,
    birim_fiyat   = EXCLUDED.birim_fiyat,
    birim_maliyet = EXCLUDED.birim_maliyet,
    brut_tutar    = EXCLUDED.brut_tutar,
    maliyet_tutar = EXCLUDED.maliyet_tutar,
    brut_marj     = EXCLUDED.brut_marj;

COMMIT;

ANALYZE star.dim_date;
ANALYZE star.dim_customer;
ANALYZE star.dim_product;
ANALYZE star.fct_orders;
ANALYZE star.fct_order_items;

\echo '===== SATIR SAYILARI ====='
SELECT 'dim_date' AS tablo, count(*) FROM star.dim_date
UNION ALL SELECT 'dim_customer', count(*) FROM star.dim_customer
UNION ALL SELECT 'dim_product',  count(*) FROM star.dim_product
UNION ALL SELECT 'fct_orders',   count(*) FROM star.fct_orders
UNION ALL SELECT 'fct_order_items', count(*) FROM star.fct_order_items;

\echo '===== TUTARLILIK: star ile OLTP ayni ciroyu mu veriyor? ====='
SELECT round(sum(brut_tutar), 2) AS star_brut_ciro
FROM star.fct_orders WHERE status IN ('paid','shipped','delivered');
