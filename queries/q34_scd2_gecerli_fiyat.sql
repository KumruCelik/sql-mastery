-- q34_scd2_gecerli_fiyat.sql
-- Soru 34: Zaman icinde fiyat degisimi -- SCD2 tablosundan gecerli fiyati bulma. (zorunlu)
-- Konu: SCD2 "as-of" sorgusu, mini-boyut, snapshot ile karsilastirma

\echo '===== 1) Ilk yukleme ====='
\i star/load_price_scd2.sql
SELECT count(*) AS fiyat_surumu, count(*) FILTER (WHERE is_current) AS guncel
FROM star.dim_product_price;

\echo ''
\echo '===== 2) Bir urunun fiyatini degistir ve tekrar yukle ====='
CREATE TEMP TABLE _tp AS SELECT 169::bigint AS product_id;
SELECT id, sku, list_price, unit_cost FROM products WHERE id = (SELECT product_id FROM _tp);

UPDATE products
SET list_price = round(list_price * 1.25, 2)
WHERE id = (SELECT product_id FROM _tp);

\i star/load_price_scd2.sql

\echo ''
\echo '--- Fiyat surumleri:'
SELECT price_sk, product_id, list_price, unit_cost, valid_from, valid_to, is_current
FROM star.dim_product_price
WHERE product_id = (SELECT product_id FROM _tp)
ORDER BY valid_from;

\echo ''
\echo '===== 3) AS-OF SORGUSU: belirli bir tarihte gecerli fiyat neydi? ====='
SELECT t.tarih,
       d.list_price AS o_tarihte_gecerli_fiyat,
       d.is_current AS surum_guncel_mi
FROM (VALUES (timestamptz '2025-06-30'),
             (timestamptz '2026-01-15'),
             (now())) AS t(tarih)
JOIN star.dim_product_price d
  ON d.product_id = (SELECT product_id FROM _tp)
 AND t.tarih >= d.valid_from
 AND t.tarih <  COALESCE(d.valid_to, 'infinity'::timestamptz)
ORDER BY t.tarih;

\echo ''
\echo '===== 4) Siparis anindaki fiyat: SCD2 vs snapshot vs bugunku fiyat ====='
SELECT o.ordered_at::date                       AS siparis_tarihi,
       oi.unit_price                            AS snapshot_order_items,
       d.list_price                             AS scd2_o_tarihteki_liste,
       p.list_price                             AS oltp_bugunku_liste
FROM order_items oi
JOIN orders o   ON o.id = oi.order_id
JOIN products p ON p.id = oi.product_id
JOIN star.dim_product_price d
  ON d.product_id = oi.product_id
 AND o.ordered_at >= d.valid_from
 AND o.ordered_at <  COALESCE(d.valid_to, 'infinity'::timestamptz)
WHERE oi.product_id = (SELECT product_id FROM _tp)
ORDER BY o.ordered_at DESC
LIMIT 8;

\echo ''
\echo '===== 5) Tutarlilik: her urunun tek guncel fiyat surumu var mi? (beklenen: 0) ====='
SELECT count(*) AS ihlal FROM (
    SELECT product_id FROM star.dim_product_price WHERE is_current
    GROUP BY product_id HAVING count(*) <> 1) t;
