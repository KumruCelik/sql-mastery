-- q46_q50_veri_kalitesi.sql
-- Sorular 46-50: veri kalitesi kontrolleri
-- Her sorgunun ustunde beklenen sonuc yaziyor. Sapma arastirilir.

-- 46) products.stock_cached defter toplamina esit mi?  (beklenen: 0 satir)
WITH defter AS (
    SELECT product_id, sum(quantity) AS bakiye
    FROM inventory_movements
    GROUP BY product_id
)
SELECT count(*) AS uyusmayan_urun
FROM products p
LEFT JOIN defter d ON d.product_id = p.id
WHERE p.stock_cached <> COALESCE(d.bakiye, 0);

-- 47) Odeme toplami, siparis toplami eksi kupon indirimine esit mi?
--     (beklenen: sapma yok; kurus farki tolere edilir)
WITH siparis_tutari AS (
    SELECT o.id AS order_id,
           sum(oi.quantity * oi.unit_price) AS sepet
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    GROUP BY o.id
),
indirim AS (
    SELECT order_id, sum(discount_applied) AS indirim
    FROM order_coupons GROUP BY order_id
),
odeme AS (
    SELECT order_id, sum(amount) AS odenen
    FROM payments WHERE status = 'success'
    GROUP BY order_id
)
SELECT count(*)                                                          AS siparis,
       count(*) FILTER (WHERE abs(s.sepet - COALESCE(i.indirim,0) - COALESCE(od.odenen,0)) > 0.01) AS sapan,
       round(max(abs(s.sepet - COALESCE(i.indirim,0) - COALESCE(od.odenen,0))), 2) AS en_buyuk_sapma
FROM siparis_tutari s
LEFT JOIN indirim i  ON i.order_id = s.order_id
LEFT JOIN odeme od   ON od.order_id = s.order_id;

-- 48) order_items.unit_price ile products.list_price sapmasi
--     (beklenen: sapma VAR ve normaldir - K-002 snapshot karari)
SELECT count(*)                                                            AS kalem,
       count(*) FILTER (WHERE oi.unit_price <> p.list_price)               AS sapan_kalem,
       round(100.0 * count(*) FILTER (WHERE oi.unit_price <> p.list_price) / count(*), 2) AS sapan_yuzde,
       round(min(oi.unit_price / p.list_price), 4)                         AS en_dusuk_oran,
       round(max(oi.unit_price / p.list_price), 4)                         AS en_yuksek_oran,
       count(*) FILTER (WHERE oi.unit_price > p.list_price)                AS liste_fiyatinin_ustunde
FROM order_items oi
JOIN products p ON p.id = oi.product_id;

-- 49) Durumu shipped/delivered/returned olup kargo kaydi bulunmayan siparisler
--     (beklenen: 23 - kasitli anomali)
SELECT count(*) AS kargosuz_siparis
FROM orders o
WHERE o.status IN ('shipped', 'delivered', 'returned')
  AND NOT EXISTS (SELECT 1 FROM shipments s WHERE s.order_id = o.id);

-- 50) inv_order_link kuralina aykiri satir  (beklenen: 0 - kisit garanti ediyor)
--     Kisit olmasaydi bu sorguyla aranirdi:
SELECT count(*) FILTER (WHERE movement_type IN ('sale','return') AND order_id IS NULL)      AS satis_iade_siparissiz,
       count(*) FILTER (WHERE movement_type IN ('purchase','adjustment') AND order_id IS NOT NULL) AS alim_duzeltme_siparisli,
       count(*) FILTER (WHERE movement_type = 'sale' AND quantity >= 0)                     AS satis_pozitif_miktar,
       count(*) FILTER (WHERE quantity = 0)                                                 AS sifir_miktar
FROM inventory_movements;

-- EK) Stok bakiyesi hicbir anda negatif olmamali (kumulatif kural, CHECK ile ifade edilemez)
WITH gunluk AS (
    SELECT product_id,
           occurred_at::date AS gun,
           sum(sum(quantity)) OVER (PARTITION BY product_id ORDER BY occurred_at::date) AS kumulatif
    FROM inventory_movements
    GROUP BY product_id, occurred_at::date
)
SELECT count(DISTINCT product_id) AS bir_ara_negatife_dusen_urun
FROM gunluk
WHERE kumulatif < 0;
